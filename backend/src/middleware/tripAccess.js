const db = require('../db');
const AppError = require('../utils/AppError');

const ROLE_RANK = { viewer: 0, editor: 1, admin: 2 };

const tripAccess = (minRole = 'viewer') => (req, _res, next) => {
  const tripId = req.params.id || req.params.tripId;
  const userId = req.user.id;

  const trip = db.prepare('SELECT owner_id FROM trips WHERE id = ?').get(tripId);
  if (!trip) return next(new AppError('Trip not found', 404));

  if (trip.owner_id === userId) return next();

  const collab = db.prepare('SELECT role FROM collaborators WHERE trip_id = ? AND user_id = ?').get(tripId, userId);
  if (!collab) return next(new AppError('Forbidden', 403));
  if (ROLE_RANK[collab.role] < ROLE_RANK[minRole]) return next(new AppError('Insufficient permissions', 403));

  req.tripRole = collab.role;
  next();
};

module.exports = tripAccess;
