const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/packing.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',            auth, tripAccess('viewer'), ctrl.list);
router.post('/',           auth, tripAccess('editor'), ctrl.create);
router.put('/:itemId',     auth, tripAccess('editor'), ctrl.update);
router.delete('/:itemId',  auth, tripAccess('editor'), ctrl.delete);

module.exports = router;
