const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const config = require('./config');
const collabSocket = require('./sockets/collab');
const logger = require('./utils/logger');

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.set('io', io);
collabSocket(io);

server.listen(config.port, () => {
  logger.info(`Server running on port ${config.port}`);
});
