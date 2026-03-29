# NESTJS Mobility Provider Pipeline Fix

## Objective
Fix the backend flow where taxi requests stay in PENDING_PROVIDER and never transition to ACCEPTED, REJECTED, FAILED, or EXPIRED.

This document is based on real API tests executed against production:
- Create proposal: OK
- Confirm proposal: OK
- Booking created in PENDING_PROVIDER: OK
- Polling after confirm: still PENDING_PROVIDER
- providerBookingRef remains null

## Root Cause Summary
The frontend is not the primary blocker.
The backend/provider pipeline is not finishing the booking lifecycle.

Most likely failures:
1. Provider dispatch job is not executed.
2. Provider API call fails silently.
3. Callback or polling worker is not running.
4. No timeout watchdog moves stale bookings to terminal status.

## Required Target Behavior
After confirm:
1. Proposal becomes PENDING_PROVIDER.
2. Booking exists with proposalId and provider.
3. Async provider flow starts.
4. Final status must be one of:
- ACCEPTED
- REJECTED
- FAILED
- EXPIRED

Never keep request in PENDING_PROVIDER forever.

## Backend State Machine
Proposal status:
- PENDING_USER_APPROVAL -> PENDING_PROVIDER -> ACCEPTED or REJECTED or FAILED or EXPIRED

Booking status:
- PENDING_PROVIDER -> ACCEPTED or REJECTED or FAILED or EXPIRED

## Step 1 - Confirm endpoint must enqueue real provider work
In your confirm service logic:
1. Validate proposal belongs to user.
2. Validate current status is PENDING_USER_APPROVAL.
3. Persist proposal status as PENDING_PROVIDER.
4. Upsert booking with:
- proposalId
- userId
- provider
- status PENDING_PROVIDER
5. Enqueue async provider dispatch job with proposalId and bookingId.
6. Return immediate response with status PENDING_PROVIDER.

Important:
- The enqueue call must never be no-op in production.
- Log queue accepted event with proposalId and bookingId.

## Step 2 - Implement worker execution and terminal transitions
Worker responsibilities:
1. Load booking and proposal.
2. Call provider API to request driver.
3. Handle all outcomes explicitly.

Outcome mapping recommendation:
- Driver assigned or booking created by provider:
  - booking.status = ACCEPTED
  - proposal.status = ACCEPTED
  - set providerBookingRef
- No driver available:
  - booking.status = REJECTED
  - proposal.status = REJECTED
- Provider timeout:
  - booking.status = EXPIRED
  - proposal.status = EXPIRED
- Provider technical error:
  - booking.status = FAILED
  - proposal.status = FAILED

Never swallow exceptions. Persist terminal state and reason.

## Step 3 - Add watchdog for stuck pending records
Create a periodic job every 1 minute:
1. Find all bookings where:
- status = PENDING_PROVIDER
- createdAt older than configured threshold (example 2 to 5 minutes)
2. Transition stale bookings to EXPIRED.
3. Transition linked proposals to EXPIRED.
4. Save reason like provider_timeout_watchdog.

This guarantees the app always receives a terminal result.

## Step 4 - Add mandatory observability logs
For each transition, log one structured line containing:
- event name
- proposalId
- bookingId
- userId
- oldStatus
- newStatus
- provider
- providerBookingRef
- errorCode (if any)
- errorMessage (if any)

Minimum events:
- mobility.confirm.received
- mobility.confirm.saved_pending_provider
- mobility.dispatch.enqueued
- mobility.dispatch.started
- mobility.provider.request.sent
- mobility.provider.response
- mobility.booking.status.updated
- mobility.proposal.status.updated
- mobility.dispatch.failed
- mobility.watchdog.expired

## Step 5 - Provider credentials and environment checklist
Validate production env values:
1. Provider base URL is valid.
2. Provider API key or token is present.
3. Token refresh mechanism works.
4. Timeouts are set.
5. Retry policy is finite and logged.
6. Queue broker connection is healthy.
7. Worker process is deployed and running.

## Step 6 - Data consistency constraints
Add DB-level guards:
1. Unique index on bookings.proposalId.
2. Do not allow ACCEPTED to go back to pending states.
3. Confirm endpoint must be idempotent.

Idempotent confirm behavior:
- If already PENDING_PROVIDER or terminal, return current snapshot safely.
- Do not create duplicate bookings.

## Step 7 - Production validation scenario
Run this exact scenario after deploying fixes:
1. Login and get token.
2. Create proposal.
3. Confirm proposal.
4. Poll every 5 seconds for up to 2 minutes:
- GET /mobility/proposals/pending
- GET /mobility/bookings
5. Expected:
- PENDING_PROVIDER appears quickly.
- Then transitions to one terminal status.
- providerBookingRef is set on ACCEPTED flow.

## Quick diagnostic commands
Use the following sequence in terminal.

1) Login and token
BASE=https://backendagentai-production.up.railway.app
TOKEN=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" -d '{"email":"YOUR_EMAIL","password":"YOUR_PASSWORD"}' | sed -n 's/.*"accessToken":"\([^"]*\)".*/\1/p')
echo TOKEN_LEN=${#TOKEN}

2) Create proposal
PICKUP_AT=$(date -u -v+10M +"%Y-%m-%dT%H:%M:%SZ")
curl -s -X POST "$BASE/mobility/proposals" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "{\"from\":\"Map selected pickup\",\"to\":\"25.26229, 55.37687\",\"pickupAt\":\"$PICKUP_AT\",\"selectedProvider\":\"uberx\",\"selectedPrice\":14.4,\"selectedEtaMinutes\":7,\"fromCoordinates\":{\"latitude\":25.20485,\"longitude\":55.27078},\"toCoordinates\":{\"latitude\":25.26229,\"longitude\":55.37687},\"routeSnapshot\":{\"distanceKm\":14.7,\"durationMin\":16}}"

3) Confirm proposal
curl -s -X POST "$BASE/mobility/proposals/PROPOSAL_ID/confirm" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json"

4) Poll bookings and pending
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/mobility/proposals/pending"
curl -s -H "Authorization: Bearer $TOKEN" "$BASE/mobility/bookings"

## Fast triage matrix
If confirm returns PENDING_PROVIDER and then:
1. No booking record:
- Booking upsert bug in confirm service.
2. Booking exists but worker never starts:
- Queue consumer down or queue binding issue.
3. Worker starts but no status change:
- Provider call path failing or callback missing.
4. Booking always pending with no timeout:
- Missing watchdog transition.

## Frontend note
Taxi icons on map come from OpenStreetMap points of interest, not guaranteed real-time provider drivers.
Do not use map marker density as booking acceptance signal.

## Done criteria
Fix is complete only when all are true:
1. No request stays in PENDING_PROVIDER beyond timeout threshold.
2. Terminal status always produced.
3. Frontend receives updated booking status automatically.
4. Logs identify every transition for each proposalId and bookingId.
