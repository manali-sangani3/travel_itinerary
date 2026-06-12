const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/budget.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',              auth, tripAccess('viewer'), ctrl.getBudgets);
router.put('/',              auth, tripAccess('editor'), ctrl.setBudgets);
router.get('/summary',       auth, tripAccess('viewer'), ctrl.getSummary);
router.get('/expenses',      auth, tripAccess('viewer'), ctrl.getExpenses);
router.post('/expenses',     auth, tripAccess('editor'), ctrl.addExpense);
router.delete('/expenses/:expId', auth, tripAccess('editor'), ctrl.delExpense);

module.exports = router;
