const AppError = require('../utils/AppError');

module.exports = (schema) => (req, _res, next) => {
  const { error } = schema.validate(req.body, { abortEarly: false });
  if (error) return next(new AppError(error.details.map((d) => d.message).join(', '), 400));
  next();
};
