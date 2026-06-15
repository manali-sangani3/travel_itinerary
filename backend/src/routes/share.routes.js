const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/share.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.post('/',            auth, tripAccess('admin'), ctrl.createShare);
router.get('/',             auth, tripAccess('viewer'), ctrl.getShares);
router.delete('/:shareId',  auth, tripAccess('admin'), ctrl.revokeShare);

module.exports = router;
