const jwt = require('jsonwebtoken');
const config = require('../config');

module.exports = (io) => {
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Unauthorized'));
    try {
      socket.user = jwt.verify(token, config.jwt.secret);
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    socket.on('join_trip', ({ tripId }) => {
      socket.join(`trip:${tripId}`);
    });

    socket.on('leave_trip', ({ tripId }) => {
      socket.leave(`trip:${tripId}`);
    });

    socket.on('disconnect', () => {});
  });
};
