const multer = require('multer');
const path = require('path');
const fs = require('fs');
const config = require('../config');
const AppError = require('../utils/AppError');

const ALLOWED = ['.pdf', '.jpg', '.jpeg', '.png', '.webp'];

if (!fs.existsSync(config.uploadPath)) fs.mkdirSync(config.uploadPath, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, config.uploadPath),
  filename: (_req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`),
});

const fileFilter = (_req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (ALLOWED.includes(ext)) return cb(null, true);
  cb(new AppError(`File type not allowed. Allowed: ${ALLOWED.join(', ')}`, 415));
};

module.exports = multer({ storage, fileFilter, limits: { fileSize: 20 * 1024 * 1024 } });
