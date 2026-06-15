const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/notes.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

router.post('/',            auth, tripAccess('editor'), ctrl.createNote);
router.get('/',             auth, tripAccess('viewer'), ctrl.getNotes);
router.put('/:noteId',      auth, tripAccess('editor'), ctrl.updateNote);
router.delete('/:noteId',   auth, tripAccess('editor'), ctrl.deleteNote);

module.exports = router;
