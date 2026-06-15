const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/packing.controller');
const ctrlV2 = require('../controllers/packingV2.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.get('/',            auth, tripAccess('viewer'), ctrl.list);
router.post('/',           auth, tripAccess('editor'), ctrl.create);
router.put('/:itemId',     auth, tripAccess('editor'), ctrl.update);
router.delete('/:itemId',  auth, tripAccess('editor'), ctrl.delete);

router.get('/templates', auth, tripAccess('viewer'), ctrlV2.getTemplates);
router.post('/generate',  auth, tripAccess('editor'), ctrlV2.generateList);

module.exports = router;
