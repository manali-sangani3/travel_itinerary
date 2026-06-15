const router = require('express').Router();
const ctrl = require('../controllers/weather.controller');
const auth = require('../middleware/auth');

router.get('/:destination/:date', auth, ctrl.getForecast);

module.exports = router;
