const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/journal.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');
const upload = require('../middleware/upload');

router.get('/',                        auth, tripAccess('viewer'), ctrl.list);
router.post('/',                       auth, tripAccess('editor'), ctrl.create);
router.put('/:entryId',               auth, tripAccess('editor'), ctrl.update);
router.delete('/:entryId',            auth, tripAccess('editor'), ctrl.delete);
router.post('/:entryId/photos',       auth, tripAccess('editor'), upload.single('photo'), ctrl.addPhoto);

module.exports = router;
