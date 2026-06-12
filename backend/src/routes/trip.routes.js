const router = require('express').Router();
const ctrl = require('../controllers/trip.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',      auth, ctrl.list);
router.post('/',     auth, ctrl.create);
router.get('/:id',   auth, tripAccess('viewer'), ctrl.get);
router.put('/:id',   auth, tripAccess('editor'), ctrl.update);
router.delete('/:id',auth, tripAccess('admin'),  ctrl.delete);

module.exports = router;
