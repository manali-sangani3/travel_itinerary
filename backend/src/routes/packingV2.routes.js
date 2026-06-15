const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/packingV2.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/templates', auth, tripAccess('viewer'), ctrl.getTemplates);
router.post('/generate',  auth, tripAccess('editor'), ctrl.generateList);

module.exports = router;
