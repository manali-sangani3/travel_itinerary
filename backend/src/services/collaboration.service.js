const { v4: uuid } = require('uuid');
const repo = require('../repositories/collaboration.repository');
const tripRepo = require('../repositories/trip.repository');
const userRepo = require('../repositories/user.repository');
const AppError = require('../utils/AppError');

exports.share = (tripId, requesterId, email, role) => {
  const target = userRepo.findByEmail(email);
  if (!target) throw new AppError('User not found', 404);
  if (repo.find(tripId, target.id)) throw new AppError('Already a collaborator', 409);
  repo.add(tripId, target.id, role);
  return repo.getCollaborators(tripId);
};

exports.updateRole = (tripId, userId, role) => {
  repo.updateRole(tripId, userId, role);
  return repo.getCollaborators(tripId);
};

exports.remove = (tripId, ownerId, targetUserId) => {
  const trip = tripRepo.findById(tripId);
  if (targetUserId === ownerId) throw new AppError('Owner cannot remove themselves', 400);
  repo.remove(tripId, targetUserId);
};

exports.getCollaborators = (tripId) => repo.getCollaborators(tripId);

exports.getTasks = (tripId) => repo.getTasks(tripId);
exports.createTask = (tripId, data) => {
  const id = uuid();
  repo.createTask({ id, trip_id: tripId, assigned_to: null, ...data });
  return repo.getTasks(tripId).find((t) => t.id === id);
};
exports.updateTask = (taskId, data) => {
  repo.updateTask(taskId, data);
};

exports.getComments = (itemId) => repo.getComments(itemId);
exports.addComment = (itemId, userId, body) => {
  const id = uuid();
  repo.createComment({ id, item_id: itemId, user_id: userId, body });
  return repo.getComments(itemId).find((c) => c.id === id);
};

exports.getSplits = (tripId) => repo.getSplits(tripId);
