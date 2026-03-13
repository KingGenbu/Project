const mongoose = require('mongoose');
const logger = require('../helper/logger');

mongoose.connect(process.env.DB_URL, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  useCreateIndex: true,
  useFindAndModify: false,
});
mongoose.connection.on('error', (err) => {
  logger.error(err);
});
