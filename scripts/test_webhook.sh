#!/bin/bash
# Test n8n webhook from command line
# Usage: ./scripts/test_webhook.sh

WEBHOOK_URL="https://hachanimohamedsaid.app.n8n.cloud/webhook-test/2429d011-049b-424b-9708-bf415bc682e1"

echo "Testing n8n webhook..."
echo "POST $WEBHOOK_URL"
echo "Body: {\"message\": \"Bonjour, comment vas-tu ?\"}"
echo ""

curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"message": "Bonjour, comment vas-tu ?"}' \
  -w "\n\nHTTP Status: %{http_code}\n"

echo ""
echo "Done."
