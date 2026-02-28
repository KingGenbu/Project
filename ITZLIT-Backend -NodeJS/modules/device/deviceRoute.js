const express = require('express');
const deviceCtr = require('./deviceController.js');
const middleware = require('../../middleware.js');
const validationRules = require('./deviceValidationRules.js');

const deviceRouter = express.Router();

// Inject Validation Rules
deviceRouter.use((req, res, next) => {
  req.validations = validationRules.get(req.path);
  next();
});

// Perform Validations
deviceRouter.use(middleware.reqValidator);

// Routes
deviceRouter.post('/create', deviceCtr.create);

deviceRouter.put('/update', deviceCtr.update);
deviceRouter.post('/update', deviceCtr.update);

deviceRouter.post('/update-notification-pref', deviceCtr.updateNotificationPref);

deviceRouter.get('/test-push', middleware.loadUser, deviceCtr.sendTestPush);

module.exports = deviceRouter;

