const express = require('express');
const notificationCtr = require('./notificationController.js');
const middleware = require('../../middleware.js');
const validationRules = require('./notificationValidationRules.js');

const notificationRouter = express.Router();

// Inject Validation Rules
notificationRouter.use((req, res, next) => {
  req.validations = validationRules.get(req.path);
  next();
});

// Perform Validations
notificationRouter.use(middleware.reqValidator);

// Load Logged in user
notificationRouter.use([(req, res, next) => {
  req.byPassRoutes = ['/contact-us']; // Add Urls to by pass auth protection
  next();
}, middleware.loadUser]);

// Routes
notificationRouter.get('/list', notificationCtr.list);
notificationRouter.post('/contact-us', notificationCtr.contactUs);
module.exports = notificationRouter;
