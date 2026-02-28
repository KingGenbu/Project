const winston = require('winston');
const fs = require('fs');
const moment = require('moment');

// const envLogger;
const logDir = 'logs/';

// Create the log directory if it does not exist
fs.access(logDir, (err) => {
  if (err) {
    fs.mkdir(logDir);
  }
});

const timestampFormat = () => { return moment().format('YYYY-MM-DD hh:mm:ss'); };

const logger = new (winston.Logger)({
  transports: [
    new (winston.transports.Console)({
      timestamp: timestampFormat,
      colorize: true,
      prettyPrint: true,
      level: 'info',
    }),
  ],
});

module.exports = logger;
