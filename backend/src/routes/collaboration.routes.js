const router = require('express').Router({ mergeParams: true });
const ctrl = require('../controllers/collaboration.controller');
const auth = require('../middleware/auth');
const tripAccess = require('../middleware/tripAccess');

// collaborators
router.get('/:id/collaborators',               auth, tripAccess('viewer'), ctrl.getCollaborators);
router.post('/:id/collaborators',              auth, tripAccess('admin'),  ctrl.share);
router.put('/:id/collaborators/:userId',       auth, tripAccess('admin'),  ctrl.updateRole);
router.delete('/:id/collaborators/:userId',    auth, tripAccess('admin'),  ctrl.remove);

// tasks
router.get('/:id/tasks',          auth, tripAccess('viewer'), ctrl.getTasks);
router.post('/:id/tasks',         auth, tripAccess('editor'), ctrl.createTask);
router.put('/:id/tasks/:taskId',  auth, tripAccess('editor'), ctrl.updateTask);

// splits
router.get('/:id/splits',         auth, tripAccess('viewer'), ctrl.getSplits);

module.exports = router;
