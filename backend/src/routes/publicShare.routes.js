const router = require('express').Router();
const ctrl = require('../controllers/share.controller');

router.get('/:token', ctrl.getSharedTrip);

module.exports = router;
