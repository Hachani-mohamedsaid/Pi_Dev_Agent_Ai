/**
 * AI Financial Simulation Advisor – Controller
 * POST /api/advisor/analyze  body: { project_text: string }
 * Saves each analysis to MongoDB collection "analyses".
 */

const advisorService = require('./advisorService');

/**
 * Expects req.body.project_text (string).
 * Expects req.analysesCollection (MongoDB collection) and req.userId (optional string).
 * On success: saves to DB, returns { report: string }.
 */
async function analyze(req, res) {
  const projectText = req.body?.project_text;
  if (!projectText || typeof projectText !== 'string') {
    return res.status(400).json({ message: 'project_text is required' });
  }

  const collection = req.analysesCollection;
  const userId = req.userId || req.user?._id?.toString() || null;

  try {
    const { report } = await advisorService.sendProjectToAdvisor(projectText);

    if (collection) {
      await collection.insertOne({
        userId,
        project_text: projectText.trim(),
        report,
        createdAt: new Date(),
      });
    }

    return res.status(200).json({ report });
  } catch (err) {
    const message = err.message || 'Analysis failed';
    const status = message.includes('timeout') || message.includes('Server error') ? 504 : 500;
    return res.status(status).json({ message });
  }
}

/**
 * GET /api/advisor/history
 * Expects req.analysesCollection and req.userId (optional).
 * Returns { analyses: [{ id, project_text, report, createdAt }, ...] } sorted by createdAt desc.
 */
async function getHistory(req, res) {
  const collection = req.analysesCollection;
  const userId = req.userId || req.user?._id?.toString() || null;

  if (!collection) {
    return res.status(200).json({ analyses: [] });
  }

  try {
    const filter = userId ? { userId } : {};
    const cursor = collection
      .find(filter)
      .sort({ createdAt: -1 })
      .limit(50)
      .project({ project_text: 1, report: 1, createdAt: 1 });
    const docs = await cursor.toArray();
    const analyses = docs.map((d) => ({
      id: d._id?.toString(),
      project_text: d.project_text ?? '',
      report: d.report ?? '',
      createdAt: d.createdAt,
    }));
    return res.status(200).json({ analyses });
  } catch (err) {
    return res.status(500).json({ message: err.message || 'Failed to fetch history' });
  }
}

module.exports = { analyze, getHistory };
