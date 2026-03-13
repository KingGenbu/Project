const winston = require('winston');
const fs = require('fs');

const logDir = 'logs/';

// Create the log directory if it does not exist
fs.access(logDir, (err) => {
  if (err) {
    fs.mkdir(logDir, () => {});
  }
});

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD hh:mm:ss' }),
    winston.format.colorize(),
    winston.format.printf(({ timestamp, level, message }) => `${timestamp} ${level}: ${message}`),
  ),
  transports: [
    new winston.transports.Console(),
  ],
});

module.exports = logger;
