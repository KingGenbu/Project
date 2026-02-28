// Environment variables
require('dotenv').config();

const http = require('http');
const l10n = require('jm-ez-l10n');
const app = require('express')();
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const snsSubscriptionConfirmation = require('aws-sns-subscription-confirmation');

// app.use(timeout('10s'));
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

require('./config/database.js');
const logger = require('./helper/logger.js');

require('./modules/cron.js');
// Translations
l10n.setTranslationsFile('en', './language/translation.en.json');
app.use(l10n.enableL10NExpress);

// Body Parse
const bodyParser = require('body-parser');

app.use(snsSubscriptionConfirmation.overrideContentType());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
app.use(snsSubscriptionConfirmation.snsConfirmHandler());

// Express Settings
app.set('port', process.env.PORT);


// API documentation
// app.use(express.static('./apidoc'));

// CORS
app.all('/*', (req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Request-Headers', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With,Content-Type, Accept,Access-Control-Allow-Headers, x-auth-token');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  next();
});

// HTTP Logger
const morgan = require('morgan');

app.use(morgan('combined'));

// Router
app.use(require('./route.js'));

// Start server
const server = http.createServer(app);
const io = require('socket.io')(server);

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
    const _client = client;
    _client.roomId = room;

    const count = io.sockets.adapter.rooms[room].length;

    logger.info(`Live Feed Count - Feed ID: ${room} - Count: ${count}`);
    io.to(room).emit('liveFeedCount', { count, feedId: room });
  });

  client.on('onFeedUnjoin', () => {
    logger.info('onFeedUnjoin');
    const { roomId } = client;
    if (roomId) {
      if (io.sockets.adapter.rooms[roomId]) {
        const count = {};
        client.leave(roomId);
        
        if (io.sockets.adapter.rooms[roomId] === undefined) {
          count.count = 0;
        } else {
          count.count = io.sockets.adapter.rooms[roomId].length; 
        }
  
        logger.info(`Live Feed Count - Feed ID: ${roomId} - Count From: ${count.count}`);
  
        io.to(roomId).emit('liveFeedCount', { count: count.count, feedId: roomId });
      }
    }
  });

  client.on('disconnect', () => {
    const { roomId } = client;
    if (roomId) {
      if (io.sockets.adapter.rooms[roomId]) {
        const count = io.sockets.adapter.rooms[roomId].length;

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
