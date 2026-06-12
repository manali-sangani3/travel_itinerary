const svc = require('../services/packing.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.list   = wrap(async (req, res) => res.json(svc.list(req.params.id)));
exports.create = wrap(async (req, res) => res.status(201).json(svc.create(req.params.id, req.body)));
exports.update = wrap(async (req, res) => { svc.update(req.params.itemId, req.body); res.json({ ok: true }); });
exports.delete = wrap(async (req, res) => { svc.delete(req.params.itemId); res.status(204).send(); });
