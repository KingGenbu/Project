const _ = require('lodash');
const _v = require('./helper/validate.js');
const jwt = require('./helper/jwt.js');
const logger = require('./helper/logger.js');
const User = require('./modules/user/userModel.js');

// const logger = require('./helper/logger');

const middleware = {};

middleware.reqValidator = (req, res, next) => {
  const { validations } = req;
  const error = _v.validate(req, validations);
  if (!_.isEmpty(error)) {
    res.status(error.statusCode).json(error);
  } else {
    next();
  }
};

middleware.loadUser = (req, res, next) => {
  const { headers, byPassRoutes } = req;
  if (!_.isEmpty(byPassRoutes)) {
    if (_.includes(byPassRoutes, req.path)) {
      next();
      return;
    }
  }

  if (_.isEmpty(headers['x-auth-token'])) {
    res.status(401).json({ error: req.t('UNAUTH') });
  } else {
    const decoded = jwt.decodeAuthToken(headers['x-auth-token']);
    if (decoded) {
      User.findOne({ _id: decoded.id })
        .then((user) => {
          if (user) {
            if (user.isBlocked) {
              res.status(401).json({ error: req.t('USER_BLOCKED') });
            } else {
              req.user = user;
              next();
            }
          } else {
            res.status(401).json({ error: req.t('ERR_USER_ACCOUNT_DELETED') });
          }
        })
        .catch((err) => {
          logger.error(err);
          res.status(401).json({ error: req.t('TOKEN_EXP') });
        });
      req.user = decoded;
    } else {
      res.status(401).json({ error: req.t('TOKEN_EXP') });
    }
  }
};

module.exports = middleware;
