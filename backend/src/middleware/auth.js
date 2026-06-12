const jwt = require('jsonwebtoken');
const config = require('../config');
const AppError = require('../utils/AppError');

module.exports = (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return next(new AppError('Unauthorized', 401));
  const token = header.split(' ')[1];
  try {
    req.user = jwt.verify(token, config.jwt.secret);
    next();
  } catch {
    next(new AppError('Invalid or expired token', 401));
  }
};
