const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/documentChecklist.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',     auth, tripAccess('viewer'), ctrl.getChecklist);
router.put('/',     auth, tripAccess('editor'), ctrl.updateChecklist);

module.exports = router;
