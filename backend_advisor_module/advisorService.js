/**
 * AI Financial Simulation Advisor – Service
 * POSTs project text to n8n webhook, returns parsed JSON report.
 * Integrate into your existing Node/Express app.
 */

const axios = require('axios');

const N8N_WEBHOOK_URL = process.env.ADVISOR_N8N_WEBHOOK_URL ||
  'https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c';

const TIMEOUT_MS = 90000;

/**
 * Sends project text to n8n webhook. Returns { report: string }.
 * @param {string} text - User's project description (e.g. "I have 7000 TND, my coffee shop costs 3800 TND monthly...")
 * @returns {Promise<{ report: string }>}
 */
async function sendProjectToAdvisor(text) {
  if (!text || typeof text !== 'string') {
    throw new Error('project_text is required');
  }

  try {
    const response = await axios.post(
      N8N_WEBHOOK_URL,
      { text: text.trim() },
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: TIMEOUT_MS,
        validateStatus: (status) => status === 200,
      }
    );

    const report = response.data?.report;
    if (report == null || typeof report !== 'string') {
      throw new Error('Invalid n8n response: missing or invalid report');
    }
    return { report };
  } catch (err) {
    if (axios.isAxiosError(err)) {
      if (err.code === 'ECONNABORTED') {
        throw new Error('Request timeout. Please try again.');
      }
      const status = err.response?.status;
      const message = err.response?.data?.message || err.message;
      throw new Error(status >= 500 ? 'Server error. Try again later.' : message);
    }
    throw err;
  }
}

module.exports = { sendProjectToAdvisor };
