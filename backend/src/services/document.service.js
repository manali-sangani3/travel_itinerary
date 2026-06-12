const { v4: uuid } = require('uuid');
const fs = require('fs');
const path = require('path');
const repo = require('../repositories/document.repository');
const collabRepo = require('../repositories/collaboration.repository');
const AppError = require('../utils/AppError');

const PASSPORT_TYPES = ['passport'];

exports.list = (tripId, userId, tripOwnerId) => {
  const docs = repo.findByTrip(tripId);
  const collab = collabRepo.find(tripId, userId);
  const isViewer = collab?.role === 'viewer';
  if (isViewer) return docs.filter((d) => !PASSPORT_TYPES.includes(d.doc_type));
  return docs;
};

exports.upload = (tripId, uploaderId, file, docType) => {
  const id = uuid();
  repo.create({ id, trip_id: tripId, uploader_id: uploaderId, file_path: file.path, doc_type: docType, original_name: file.originalname });
  return repo.findById(id);
};

exports.download = (docId) => {
  const doc = repo.findById(docId);
  if (!doc) throw new AppError('Document not found', 404);
  if (!fs.existsSync(doc.file_path)) throw new AppError('File not found on server', 404);
  return doc;
};

exports.delete = (docId) => {
  const doc = repo.findById(docId);
  if (!doc) throw new AppError('Document not found', 404);
  if (fs.existsSync(doc.file_path)) fs.unlinkSync(doc.file_path);
  repo.delete(docId);
};
