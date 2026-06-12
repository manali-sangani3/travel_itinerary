const { v4: uuid } = require('uuid');
const repo = require('../repositories/packing.repository');

exports.list = (tripId) => repo.findByTrip(tripId);
exports.create = (tripId, data) => {
  const id = uuid();
  repo.create({ id, trip_id: tripId, ...data, checked: 0 });
  return repo.findByTrip(tripId).find((i) => i.id === id);
};
exports.update = (id, data) => { repo.update(id, data); };
exports.delete = (id) => repo.delete(id);
