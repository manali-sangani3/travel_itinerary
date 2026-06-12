const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/document.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');
const upload = require('../middleware/upload');

router.get('/',           auth, tripAccess('viewer'), ctrl.list);
router.post('/',          auth, tripAccess('editor'), upload.single('file'), ctrl.upload);
router.get('/:docId',     auth, tripAccess('viewer'), ctrl.download);
router.delete('/:docId',  auth, tripAccess('editor'), ctrl.delete);

module.exports = router;
