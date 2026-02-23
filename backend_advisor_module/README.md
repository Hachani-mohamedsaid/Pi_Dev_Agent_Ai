# Backend module: AI Financial Simulation Advisor

This folder contains the **backend module** to add to your existing Node.js/Express API. The Flutter app calls `POST /api/advisor/analyze` with `{ "project_text": "..." }` and expects `{ "report": "..." }`.

## MongoDB collection

Create a collection named **`analyses`** with documents:

- `userId` (string, optional) – from your auth
- `project_text` (string)
- `report` (string) – full report from n8n
- `createdAt` (Date)

No need to change existing models; this is a new collection.

## n8n webhook

The service POSTs to:

`https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c`

Body: `{ "text": "<user project description>" }`  
Response: `{ "report": "BUDGET: ...\nMONTHLY COST: ...\n..." }`

## Integration (Express)

1. Install axios (if not already):  
   `npm install axios`

2. Copy the 3 files into your backend (e.g. `src/advisor/` or `routes/advisor/`).

3. In your main app file (e.g. `app.js`):

```js
const { MongoClient } = require('mongodb');
const advisorRoutes = require('./backend_advisor_module/advisorRoutes');

// After DB connection, get collection:
const analysesCollection = db.collection('analyses');

// Optional: provide a function to get current user id from req (e.g. from JWT)
function getUserId(req) {
  return req.user?.id ?? req.auth?.userId ?? null;
}

app.use('/api/advisor', advisorRoutes(analysesCollection, getUserId));
```

4. Environment (optional):  
   `ADVISOR_N8N_WEBHOOK_URL` – override the n8n webhook URL.

## Endpoints

- **POST /api/advisor/analyze**  
  - Body: `{ "project_text": "string" }`  
  - Response 200: `{ "report": "string" }`  
  - Errors: 400 (missing project_text), 504 (timeout), 500 (server error)

- **GET /api/advisor/history**  
  - Headers: `Authorization: Bearer <JWT>` (optional; if present, returns only that user’s analyses).  
  - Response 200: `{ "analyses": [{ "id": "...", "project_text": "...", "report": "...", "createdAt": "ISO date" }, ...] }`  
  - Sorted by `createdAt` desc, max 50 items.

The Flutter app uses `apiBaseUrl + '/api/advisor/analyze'` and `apiBaseUrl + '/api/advisor/history'`. If the backend is not deployed yet, analyze falls back to the n8n webhook; history will be empty.
