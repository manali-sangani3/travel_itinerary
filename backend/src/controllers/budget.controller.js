const svc = require('../services/budget.service');
const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.getBudgets  = wrap(async (req, res) => res.json(svc.getBudgets(req.params.id)));
exports.setBudgets  = wrap(async (req, res) => res.json(svc.setBudgets(req.params.id, req.body)));
exports.getExpenses = wrap(async (req, res) => res.json(svc.getExpenses(req.params.id)));
exports.addExpense  = wrap(async (req, res) => res.status(201).json(svc.addExpense(req.params.id, req.user.id, req.body)));
exports.delExpense  = wrap(async (req, res) => { svc.deleteExpense(req.params.expId); res.status(204).send(); });
exports.getSummary  = wrap(async (req, res) => res.json(svc.getSummary(req.params.id)));
