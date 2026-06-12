const svc = require('../services/itinerary.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.list    = wrap(async (req, res) => res.json(svc.list(req.params.id)));
exports.create  = wrap(async (req, res) => res.status(201).json(svc.create(req.params.id, req.body)));
exports.update  = wrap(async (req, res) => res.json(svc.update(req.params.itemId, req.body)));
exports.delete  = wrap(async (req, res) => { svc.delete(req.params.itemId); res.status(204).send(); });
exports.reorder = wrap(async (req, res) => { svc.reorder(req.body.items); const io = req.app.get('io'); if (io) io.to(`trip:${req.params.id}`).emit('itinerary:reordered', req.body); res.json({ ok: true }); });
exports.travelTime = wrap(async (req, res) => {
  const { lat1, lon1, lat2, lon2, speed } = req.query;
  res.json({ minutes: svc.estimateTravelTime(+lat1, +lon1, +lat2, +lon2, speed ? +speed : undefined) });
});
