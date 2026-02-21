/**
 * AI Financial Simulation Advisor – Routes
 * Mount in your Express app, e.g.:
 *   const { analysesCollection } = require('./db');
 *   const advisorRoutes = require('./backend_advisor_module/advisorRoutes');
 *   app.use('/api/advisor', advisorRoutes(analysesCollection, getUserIdFromReq));
 */

const express = require('express');
const { analyze, getHistory } = require('./advisorController');

/**
 * @param {import('mongodb').Collection} [analysesCollection] - MongoDB collection "analyses"
 * @param {(req) => string|null} [getUserId] - optional: (req) => req.user?.id or similar
 */
function advisorRoutes(analysesCollection, getUserId) {
  const router = express.Router();

  router.post('/analyze', (req, res, next) => {
    req.analysesCollection = analysesCollection;
    req.userId = getUserId ? getUserId(req) : null;
    analyze(req, res).catch(next);
  });

  router.get('/history', (req, res, next) => {
    req.analysesCollection = analysesCollection;
    req.userId = getUserId ? getUserId(req) : null;
    getHistory(req, res).catch(next);
  });

  return router;
}

module.exports = advisorRoutes;
