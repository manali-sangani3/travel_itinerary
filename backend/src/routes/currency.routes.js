const router = require('express').Router();
const ctrl = require('../controllers/currency.controller');
const auth = require('../middleware/auth');

router.get('/convert', auth, ctrl.convert);

module.exports = router;
