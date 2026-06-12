require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
  encryptionKey: process.env.ENCRYPTION_KEY,
  dbPath: process.env.DB_PATH || './data/travel.db',
  uploadPath: process.env.UPLOAD_PATH || './uploads',
};
