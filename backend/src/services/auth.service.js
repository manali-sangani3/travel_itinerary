const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuid } = require('uuid');
const config = require('../config');
const userRepo = require('../repositories/user.repository');
const AppError = require('../utils/AppError');
const { encrypt, decrypt } = require('../utils/encrypt');

const signAccess = (id) => jwt.sign({ id }, config.jwt.secret, { expiresIn: config.jwt.expiresIn });
const signRefresh = (id) => jwt.sign({ id }, config.jwt.refreshSecret, { expiresIn: config.jwt.refreshExpiresIn });

exports.register = async (email, password) => {
  if (userRepo.findByEmail(email)) throw new AppError('Email already registered', 409);
  const hash = await bcrypt.hash(password, 12);
  const id = uuid();
  userRepo.create({ id, email, password_hash: hash });
  return { id, email };
};

exports.login = async (email, password) => {
  const user = userRepo.findByEmail(email);
  if (!user) throw new AppError('Invalid credentials', 401);
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) throw new AppError('Invalid credentials', 401);
  const accessToken = signAccess(user.id);
  const refreshToken = signRefresh(user.id);
  const tokenId = uuid();
  const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  userRepo.saveRefreshToken(tokenId, user.id, refreshToken, expires);
  return { accessToken, refreshToken };
};

exports.refresh = (token) => {
  let payload;
  try { payload = jwt.verify(token, config.jwt.refreshSecret); }
  catch { throw new AppError('Invalid refresh token', 401); }
  const stored = userRepo.findRefreshToken(token);
  if (!stored) throw new AppError('Refresh token revoked', 401);
  userRepo.deleteRefreshToken(token);
  const accessToken = signAccess(payload.id);
  const newRefresh = signRefresh(payload.id);
  const tokenId = uuid();
  const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  userRepo.saveRefreshToken(tokenId, payload.id, newRefresh, expires);
  return { accessToken, refreshToken: newRefresh };
};

exports.getProfile = (userId) => {
  const user = userRepo.findById(userId);
  if (!user) throw new AppError('User not found', 404);
  const result = { ...user, travel_preferences: JSON.parse(user.travel_preferences || '{}') };
  if (result.passport_details) {
    try { result.passport_details = JSON.parse(decrypt(result.passport_details)); }
    catch { result.passport_details = null; }
  }
  return result;
};

exports.updateProfile = (userId, { travel_preferences, passport_details }) => {
  if (travel_preferences !== undefined) userRepo.updatePreferences(userId, travel_preferences);
  if (passport_details !== undefined) userRepo.updatePassport(userId, encrypt(JSON.stringify(passport_details)));
};
