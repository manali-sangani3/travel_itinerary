const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/booking.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',               auth, tripAccess('viewer'), ctrl.list);
router.post('/',              auth, tripAccess('editor'), ctrl.create);
router.put('/:bookingId',     auth, tripAccess('editor'), ctrl.update);
router.delete('/:bookingId',  auth, tripAccess('editor'), ctrl.delete);

module.exports = router;
