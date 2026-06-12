const router = require('express').Router();
const ctrl = require('../controllers/auth.controller');
const auth = require('../middleware/auth');
const validate = require('../middleware/validate');
const Joi = require('joi');

const registerSchema = Joi.object({ email: Joi.string().email().required(), password: Joi.string().min(8).required() });
const loginSchema    = Joi.object({ email: Joi.string().email().required(), password: Joi.string().required() });

router.post('/register', validate(registerSchema), ctrl.register);
router.post('/login',    validate(loginSchema),    ctrl.login);
router.post('/refresh',  ctrl.refresh);
router.get('/profile',   auth, ctrl.getProfile);
router.put('/profile',   auth, ctrl.updateProfile);

module.exports = router;
