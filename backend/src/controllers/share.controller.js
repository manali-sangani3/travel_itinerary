const db = require('../db');
const AppError = require('../utils/AppError');
const crypto = require('crypto');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.createShare = wrap(async (req, res, next) => {
  const tripId = req.params.id;
  const { role, expiresInDays } = req.body;

  if (!role || !['viewer', 'editor'].includes(role)) {
    return next(new AppError('Invalid role', 400));
  }

  const token = crypto.randomBytes(24).toString('hex');
  const expiry = new Date();
  expiry.setDate(expiry.getDate() + (parseInt(expiresInDays, 10) || 7));

  const id = crypto.randomUUID();
  db.prepare('INSERT INTO trip_shares (id, trip_id, share_token, role, expires_at) VALUES (?, ?, ?, ?, ?)')
    .run(id, tripId, token, role, expiry.toISOString());

  res.status(201).json({
    id,
    token,
    role,
    expiresAt: expiry.toISOString(),
    shareUrl: `/shares/${token}`
  });
});

exports.getShares = wrap(async (req, res) => {
  const tripId = req.params.id;
  const shares = db.prepare('SELECT * FROM trip_shares WHERE trip_id = ?').all(tripId);
  res.json(shares);
});

exports.revokeShare = wrap(async (req, res) => {
  const { shareId } = req.params;
  db.prepare('DELETE FROM trip_shares WHERE id = ?').run(shareId);
  res.status(204).send();
});

exports.getSharedTrip = wrap(async (req, res, next) => {
  const { token } = req.params;
  const share = db.prepare('SELECT * FROM trip_shares WHERE share_token = ?').get(token);

  if (!share) return next(new AppError('Share link not found', 404));

  const now = new Date();
  if (now > new Date(share.expires_at)) {
    return res.status(410).json({ error: 'Link expired' });
  }

  const trip = db.prepare('SELECT * FROM trips WHERE id = ?').get(share.trip_id);
  if (!trip) return next(new AppError('Trip not found', 404));

  const itinerary = db.prepare('SELECT * FROM itinerary_items WHERE trip_id = ? ORDER BY day_index, order_index').all(share.trip_id);
  const packing = db.prepare('SELECT * FROM packing_items WHERE trip_id = ?').all(share.trip_id);

  res.json({
    trip,
    itinerary,
    packing,
    role: share.role
  });
});
