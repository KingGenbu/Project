const express = require('express');

const router = express.Router();

router.use('/api/v1/user', require('./modules/user/userRoute'));
router.use('/api/v1/device', require('./modules/device/deviceRoute'));
router.use('/api/v1/connection', require('./modules/connection/connectionRoute'));
router.use('/api/v1/feed', require('./modules/feed/feedRoute'));
router.use('/api/v1/notification', require('./modules/notification/notificationRoute'));
router.use('/api/v1/static', require('./modules/static/staticRoute'));

router.all('/*', (req, res) => {
  return res.status(404).send();
});

module.exports = router;
