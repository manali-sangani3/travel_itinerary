const authService = require('../services/auth.service');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.register = wrap(async (req, res) => {
  const user = await authService.register(req.body.email, req.body.password);
  res.status(201).json(user);
});

exports.login = wrap(async (req, res) => {
  const tokens = await authService.login(req.body.email, req.body.password);
  res.json(tokens);
});

exports.refresh = wrap(async (req, res) => {
  const tokens = authService.refresh(req.body.refreshToken);
  res.json(tokens);
});

exports.getProfile = wrap(async (req, res) => {
  res.json(authService.getProfile(req.user.id));
});

exports.updateProfile = wrap(async (req, res) => {
  authService.updateProfile(req.user.id, req.body);
  res.json({ message: 'Profile updated' });
});
