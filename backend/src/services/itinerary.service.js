const { v4: uuid } = require('uuid');
const repo = require('../repositories/itinerary.repository');
const AppError = require('../utils/AppError');

exports.list = (tripId) => repo.findByTrip(tripId);

exports.create = (tripId, data) => {
  const id = uuid();
  repo.create({ id, trip_id: tripId, ...data });
  return repo.findById(id);
};

exports.update = (id, data) => {
  repo.update(id, data);
  return repo.findById(id);
};

exports.delete = (id) => repo.delete(id);

exports.reorder = (items) => {
  repo.reorder(items);
};

// haversine travel time estimate in minutes (walking ~5km/h default)
exports.estimateTravelTime = (lat1, lon1, lat2, lon2, speedKmh = 5) => {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a = Math.sin(dLat / 2) ** 2 + Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLon / 2) ** 2;
  const dist = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round((dist / speedKmh) * 60);
};
