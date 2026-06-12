const { v4: uuid } = require('uuid');
const tripRepo = require('../repositories/trip.repository');
const AppError = require('../utils/AppError');

exports.list = (userId) => tripRepo.findAllByUser(userId).map((t) => ({ ...t, companions: JSON.parse(t.companions || '[]') }));

exports.create = (userId, data) => {
  const id = uuid();
  tripRepo.create({ id, owner_id: userId, ...data, companions: JSON.stringify(data.companions || []), status: 'planning' });
  return tripRepo.findById(id);
};

exports.get = (id) => {
  const trip = tripRepo.findById(id);
  if (!trip) throw new AppError('Trip not found', 404);
  return { ...trip, companions: JSON.parse(trip.companions || '[]') };
};

exports.update = (id, data) => {
  if (data.companions) data.companions = JSON.stringify(data.companions);
  tripRepo.update(id, data);
  return tripRepo.findById(id);
};

exports.delete = (id) => tripRepo.delete(id);
