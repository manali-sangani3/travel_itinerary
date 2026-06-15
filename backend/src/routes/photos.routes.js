const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/photos.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');
const upload = require('../middleware/upload');

router.get('/',           auth, tripAccess('viewer'), ctrl.getPhotos);
router.post('/',          auth, tripAccess('editor'), upload.single('photo'), ctrl.uploadPhoto);
router.delete('/:photoId', auth, tripAccess('editor'), ctrl.deletePhoto);

module.exports = router;
