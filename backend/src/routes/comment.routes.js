const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/collaboration.controller');
const auth = require('../middleware/auth');

router.get('/:itemId/comments',  auth, ctrl.getComments);
router.post('/:itemId/comments', auth, ctrl.addComment);

module.exports = router;
