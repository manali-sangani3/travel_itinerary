const { v4: uuid } = require('uuid');
const bookingRepo = require('../repositories/booking.repository');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.list   = wrap(async (req, res) => res.json(bookingRepo.findByTrip(req.params.id)));
exports.create = wrap(async (req, res) => {
  const id = uuid();
  bookingRepo.create({ id, trip_id: req.params.id, ...req.body, details: JSON.stringify(req.body.details || {}) });
  res.status(201).json(bookingRepo.findById(id));
});
exports.update = wrap(async (req, res) => {
  bookingRepo.update(req.params.bookingId, req.body);
  res.json(bookingRepo.findById(req.params.bookingId));
});
exports.delete = wrap(async (req, res) => { bookingRepo.delete(req.params.bookingId); res.status(204).send(); });
