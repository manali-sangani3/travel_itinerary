const svc = require('../services/document.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.list     = wrap(async (req, res) => res.json(svc.list(req.params.id, req.user.id)));
exports.upload   = wrap(async (req, res) => res.status(201).json(svc.upload(req.params.id, req.user.id, req.file, req.body.doc_type)));
exports.download = wrap(async (req, res) => { const doc = svc.download(req.params.docId); res.download(doc.file_path, doc.original_name); });
exports.delete   = wrap(async (req, res) => { svc.delete(req.params.docId); res.status(204).send(); });
