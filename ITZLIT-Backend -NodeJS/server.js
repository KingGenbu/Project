// Environment variables
require('dotenv').config();

const http = require('http');
const cors = require('cors');
const l10n = require('jm-ez-l10n');
const express = require('express');
const app = express();
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const snsSubscriptionConfirmation = require('aws-sns-subscription-confirmation');

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

require('./config/database.js');
const logger = require('./helper/logger.js');

require('./modules/cron.js');

// Translations
l10n.setTranslationsFile('en', './language/translation.en.json');
app.use(l10n.enableL10NExpress);

// CORS
app.use(cors({
  origin: '*',
  allowedHeaders: ['Origin', 'X-Requested-With', 'Content-Type', 'Accept', 'Access-Control-Allow-Headers', 'x-auth-token'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
}));

// Body Parse (express 4.16+ built-in parsers; body-parser kept as peer dep for SNS middleware)
app.use(snsSubscriptionConfirmation.overrideContentType());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(snsSubscriptionConfirmation.snsConfirmHandler());

// HTTP Logger
const morgan = require('morgan');
app.use(morgan('combined'));

// Express Settings
app.set('port', process.env.PORT);

// Router
app.use(require('./route.js'));

// Start server
const server = http.createServer(app);

// Socket.IO v4: pass cors config directly to the constructor
const io = require('socket.io')(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

io.on('connection', (client) => {
  logger.info('Socket Connect!');

  client.on('onFeedJoin', (data) => {
    logger.info('onFeedJoin');
    let _data;
    if (typeof data === 'object') {
      _data = data;
    } else {
      _data = JSON.parse(data);
    }

    logger.info(data);

    const room = _data.feedId;
    client.join(room);
    client.roomId = room;

    // Socket.IO v4: rooms is a Map; use .get(room).size instead of .rooms[room].length
    const count = io.sockets.adapter.rooms.get(room)?.size ?? 0;

    logger.info(`Live Feed Count - Feed ID: ${room} - Count: ${count}`);
    io.to(room).emit('liveFeedCount', { count, feedId: room });
  });

  client.on('onFeedUnjoin', () => {
    logger.info('onFeedUnjoin');
    const { roomId } = client;
    if (roomId) {
      const roomSockets = io.sockets.adapter.rooms.get(roomId);
      if (roomSockets) {
        client.leave(roomId);
        const count = io.sockets.adapter.rooms.get(roomId)?.size ?? 0;

        logger.info(`Live Feed Count - Feed ID: ${roomId} - Count From: ${count}`);
        io.to(roomId).emit('liveFeedCount', { count, feedId: roomId });
      }
    }
  });

  client.on('disconnect', () => {
    const { roomId } = client;
    if (roomId) {
      const roomSockets = io.sockets.adapter.rooms.get(roomId);
      if (roomSockets) {
        const count = roomSockets.size;
        logger.info(`Live Feed Count - Feed ID: ${roomId} - Count: ${count}`);
        io.to(roomId).emit('liveFeedCount', { count });
      }
    }
    logger.info('Socket Disconnect!');
  });
});

server.listen(process.env.PORT, () => {
  logger.info(`Express server listening on port ${process.env.PORT}`);
});
