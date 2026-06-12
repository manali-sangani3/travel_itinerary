const svc = require('../services/collaboration.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

const emit = (req, room, event, data) => { const io = req.app.get('io'); if (io) io.to(room).emit(event, data); };

exports.getCollaborators = wrap(async (req, res) => res.json(svc.getCollaborators(req.params.id)));
exports.share        = wrap(async (req, res) => res.status(201).json(svc.share(req.params.id, req.user.id, req.body.email, req.body.role)));
exports.updateRole   = wrap(async (req, res) => res.json(svc.updateRole(req.params.id, req.params.userId, req.body.role)));
exports.remove       = wrap(async (req, res) => { svc.remove(req.params.id, req.user.id, req.params.userId); emit(req, `trip:${req.params.id}`, 'collaborator:removed', { userId: req.params.userId }); res.status(204).send(); });

exports.getTasks     = wrap(async (req, res) => res.json(svc.getTasks(req.params.id)));
exports.createTask   = wrap(async (req, res) => { const task = svc.createTask(req.params.id, req.body); emit(req, `trip:${req.params.id}`, 'task:updated', task); res.status(201).json(task); });
exports.updateTask   = wrap(async (req, res) => { svc.updateTask(req.params.taskId, req.body); emit(req, `trip:${req.params.id}`, 'task:updated', { id: req.params.taskId, ...req.body }); res.json({ ok: true }); });

exports.getComments  = wrap(async (req, res) => res.json(svc.getComments(req.params.itemId)));
exports.addComment   = wrap(async (req, res) => { const c = svc.addComment(req.params.itemId, req.user.id, req.body.body); emit(req, `trip:${req.params.tripId}`, 'comment:new', { itemId: req.params.itemId, comment: c }); res.status(201).json(c); });

exports.getSplits    = wrap(async (req, res) => res.json(svc.getSplits(req.params.id)));
