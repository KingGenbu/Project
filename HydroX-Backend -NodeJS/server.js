// Environment variables
require('dotenv').config();
const validateEnv = require('./config/validateEnv');
validateEnv();

const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const l10n = require('jm-ez-l10n');
const express = require('express');
const app = express();
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const snsSubscriptionConfirmation = require('aws-sns-subscription-confirmation');

// Security headers
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many authentication attempts, please try again later.' },
});
app.use('/api/v1/user/login', authLimiter);
app.use('/api/v1/user/create', authLimiter);
app.use('/api/v1/user/forget-password', authLimiter);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

require('./config/database.js');
const logger = require('./helper/logger.js');

require('./modules/cron.js');

// Translations
l10n.setTranslationsFile('en', './language/translation.en.json');
app.use(l10n.enableL10NExpress);

// CORS
const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS || '').split(',').filter(Boolean);
app.use(cors({
  origin: allowedOrigins.length > 0 ? allowedOrigins : false,
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
    origin: allowedOrigins.length > 0 ? allowedOrigins : false,
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
