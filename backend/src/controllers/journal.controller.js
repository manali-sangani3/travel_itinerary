const svc = require('../services/journal.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.list       = wrap(async (req, res) => res.json(svc.list(req.params.id)));
exports.create     = wrap(async (req, res) => res.status(201).json(svc.create(req.params.id, req.user.id, req.body)));
exports.update     = wrap(async (req, res) => res.json(svc.update(req.params.entryId, req.body)));
exports.delete     = wrap(async (req, res) => { svc.delete(req.params.entryId); res.status(204).send(); });
exports.addPhoto   = wrap(async (req, res) => res.json(svc.addPhoto(req.params.entryId, req.file, req.body.location)));
