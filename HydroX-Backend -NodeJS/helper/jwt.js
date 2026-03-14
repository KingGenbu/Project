const jwt = require('jsonwebtoken');
const logger = require('./logger');

const JWT_ALGORITHM = 'HS256';

const jwtUtil = {};

jwtUtil.getAuthToken = (data) => {
  return jwt.sign(data, process.env.JwtSecret, { algorithm: JWT_ALGORITHM });
};

jwtUtil.decodeAuthToken = (token) => {
  if (token) {
    try {
      return jwt.verify(token, process.env.JwtSecret, { algorithms: [JWT_ALGORITHM] });
    } catch (err) {
      logger.error(err);
      return false;
    }
  }
  return false;
};

module.exports = jwtUtil;
