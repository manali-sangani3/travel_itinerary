const logger = require('../utils/logger');

module.exports = (err, _req, res, _next) => {
  const status = err.statusCode || 500;
  if (status === 500) logger.error(err.message, { stack: err.stack });
  res.status(status).json({ error: err.message || 'Internal server error' });
};
