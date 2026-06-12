const db = require('../db');

exports.findByTrip = (tripId) => db.prepare('SELECT id, trip_id, uploader_id, doc_type, original_name, uploaded_at FROM documents WHERE trip_id = ?').all(tripId);
exports.findById = (id) => db.prepare('SELECT * FROM documents WHERE id = ?').get(id);
exports.create = (doc) => db.prepare('INSERT INTO documents (id, trip_id, uploader_id, file_path, doc_type, original_name) VALUES (@id, @trip_id, @uploader_id, @file_path, @doc_type, @original_name)').run(doc);
exports.delete = (id) => db.prepare('DELETE FROM documents WHERE id = ?').run(id);
