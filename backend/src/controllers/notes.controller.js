const db = require('../db');
const crypto = require('crypto');
const AppError = require('../utils/AppError');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.createNote = wrap(async (req, res, next) => {
  const tripId = req.params.id;
  const { content, dayDate, locationTag } = req.body;

  if (!content) return next(new AppError('Content is required', 400));

  const id = crypto.randomUUID();
  db.prepare('INSERT INTO trip_notes (id, trip_id, content, day_date, location_tag) VALUES (?, ?, ?, ?, ?)')
    .run(id, tripId, content, dayDate || null, locationTag || null);

  const note = db.prepare('SELECT * FROM trip_notes WHERE id = ?').get(id);
  res.status(201).json(note);
});

exports.getNotes = wrap(async (req, res) => {
  const tripId = req.params.id;
  const notes = db.prepare('SELECT * FROM trip_notes WHERE trip_id = ? ORDER BY created_at DESC').all(tripId);
  res.json(notes);
});

exports.updateNote = wrap(async (req, res, next) => {
  const { noteId } = req.params;
  const { content } = req.body;

  if (!content) return next(new AppError('Content is required', 400));

  db.prepare('UPDATE trip_notes SET content = ? WHERE id = ?').run(content, noteId);
  const note = db.prepare('SELECT * FROM trip_notes WHERE id = ?').get(noteId);
  res.json(note);
});

exports.deleteNote = wrap(async (req, res) => {
  const { noteId } = req.params;
  db.prepare('DELETE FROM trip_notes WHERE id = ?').run(noteId);
  res.status(204).send();
});
