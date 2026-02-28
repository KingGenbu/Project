const express = require('express');
const connectionCtr = require('./connectionController.js');
const middleware = require('../../middleware.js');
const validationRules = require('./connectionValidationRules.js');

const connectionRouter = express.Router();

// Inject Validation Rules
connectionRouter.use((req, res, next) => {
  req.validations = validationRules.get(req.path);
  next();
});

// Perform Validations
connectionRouter.use(middleware.reqValidator);

// Load Logged in user
connectionRouter.use([(req, res, next) => {
  req.byPassRoutes = []; // Add Urls to by pass auth protection
  next();
}, middleware.loadUser]);

// Routes
connectionRouter.post('/follow', connectionCtr.follow);
connectionRouter.post('/unfollow', connectionCtr.unfollow);

// followings - To whom I am following
// followers - people following to me 
connectionRouter.get('/followers', connectionCtr.followers);
connectionRouter.get('/followings', connectionCtr.followings);
connectionRouter.post('/itzlit-users', connectionCtr.itzlitUsers);
connectionRouter.get('/search', connectionCtr.search);

module.exports = connectionRouter;

