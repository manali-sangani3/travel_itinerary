const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/itinerary.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',                  auth, tripAccess('viewer'), ctrl.list);
router.post('/',                 auth, tripAccess('editor'), ctrl.create);
router.put('/reorder',           auth, tripAccess('editor'), ctrl.reorder);
router.get('/travel-time',       auth, tripAccess('viewer'), ctrl.travelTime);
router.put('/:itemId',           auth, tripAccess('editor'), ctrl.update);
router.delete('/:itemId',        auth, tripAccess('editor'), ctrl.delete);

module.exports = router;
