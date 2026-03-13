const express = require('express');
const staticCtr = require('./staticController.js');

const staticRouter = express.Router();

// Routes
staticRouter.get('/privacy-policy', staticCtr.privacyPolicy);
staticRouter.get('/terms-of-use', staticCtr.termsOfUse);

module.exports = staticRouter;

