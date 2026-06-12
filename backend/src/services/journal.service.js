const { v4: uuid } = require('uuid');
const repo = require('../repositories/journal.repository');
const AppError = require('../utils/AppError');

exports.list = (tripId) => repo.findByTrip(tripId).map((e) => ({ ...e, photos: JSON.parse(e.photos || '[]') }));

exports.create = (tripId, userId, data) => {
  const id = uuid();
  repo.create({ id, trip_id: tripId, user_id: userId, ...data, photos: '[]' });
  return repo.findById(id);
};

exports.update = (id, data) => {
  repo.update(id, data);
  return repo.findById(id);
};

exports.delete = (id) => repo.delete(id);

exports.addPhoto = (entryId, file, location) => {
  const entry = repo.findById(entryId);
  if (!entry) throw new AppError('Entry not found', 404);
  const photos = JSON.parse(entry.photos || '[]');
  photos.push({ path: file.path, name: file.originalname, location: location || null });
  repo.addPhoto(entryId, photos);
  return photos;
};
