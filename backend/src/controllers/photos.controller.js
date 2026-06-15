const db = require('../db');
const crypto = require('crypto');
const fs = require('fs');
const AppError = require('../utils/AppError');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.getPhotos = wrap(async (req, res) => {
  const tripId = req.params.id;
  const photos = db.prepare('SELECT * FROM trip_photos WHERE trip_id = ? ORDER BY date_taken DESC').all(tripId);
  res.json(photos);
});

exports.uploadPhoto = wrap(async (req, res, next) => {
  const tripId = req.params.id;
  if (!req.file) return next(new AppError('No photo file provided', 400));

  const { locationTag, dateTaken } = req.body;
  const id = crypto.randomUUID();
  const filePath = req.file.path; // relative to backend root e.g. uploads/xxx
  const dateTakenVal = dateTaken || new Date().toISOString().split('T')[0];

  db.prepare('INSERT INTO trip_photos (id, trip_id, file_path, location_tag, date_taken) VALUES (?, ?, ?, ?, ?)')
    .run(id, tripId, filePath, locationTag || null, dateTakenVal);

  const photo = db.prepare('SELECT * FROM trip_photos WHERE id = ?').get(id);
  res.status(201).json(photo);
});

exports.deletePhoto = wrap(async (req, res, next) => {
  const { photoId } = req.params;
  const photo = db.prepare('SELECT * FROM trip_photos WHERE id = ?').get(photoId);

  if (!photo) return next(new AppError('Photo not found', 404));

  if (fs.existsSync(photo.file_path)) {
    fs.unlinkSync(photo.file_path);
  }

  db.prepare('DELETE FROM trip_photos WHERE id = ?').run(photoId);
  res.status(204).send();
});
