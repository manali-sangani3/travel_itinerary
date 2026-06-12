const tripService = require('../services/trip.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.list   = wrap(async (req, res) => res.json(tripService.list(req.user.id)));
exports.create = wrap(async (req, res) => res.status(201).json(tripService.create(req.user.id, req.body)));
exports.get    = wrap(async (req, res) => res.json(tripService.get(req.params.id)));
exports.update = wrap(async (req, res) => res.json(tripService.update(req.params.id, req.body)));
exports.delete = wrap(async (req, res) => { tripService.delete(req.params.id); res.status(204).send(); });
