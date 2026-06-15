const router = require('express').Router();
const ctrl = require('../controllers/timezone.controller');
const auth = require('../middleware/auth');

router.get('/diff', auth, ctrl.getDiff);

module.exports = router;
