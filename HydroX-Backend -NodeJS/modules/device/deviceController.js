const _ = require('lodash');
const Device = require('./deviceModel.js');
const logger = require('../../helper/logger');
const pjson = require('../../package.json');
const boolean = require('boolean');
const notification = require('../../helper/notification');

const deviceCtr = {};

deviceCtr.create = (req, res) => {
  const { body } = req;
  const {
    timeZone,
    deviceType,
    appIdentifier,
    appName,
    appVersion,
    appBuildNumber,
    deviceToken,
  } = body;

  // Check Email is not already taken
  const device = new Device({
    timeZone,
    deviceType,
    appIdentifier,
    appName,
    appVersion,
    appBuildNumber,
    deviceToken,
    apiVersion: pjson.version,
  });

  device.save()
    .then((result) => {
      if (!_.isEmpty(deviceToken)) {
        // Update devices with same token first to ensure notification won't go to wrong person.
        Device.update({
          deviceToken,
          _id: { $ne: result._id },
        }, { deviceToken: '' }, { multi: true })
          .then((done) => { logger.info(done); })
          .catch((err) => { logger.error(err); });
      }

      res.status(200).json({ deviceId: result._id });
    })
    .catch((err) => {
      logger.error(err);
    });
};

deviceCtr.update = (req, res) => {
  const { body } = req;
  const {
    deviceId,
    timeZone,
    deviceType,
    appIdentifier,
    appName,
    appVersion,
    appBuildNumber,
    deviceToken,
  } = body;

  // Check Email is not already taken
  const device = {
    timeZone,
    deviceType,
    appIdentifier,
    appName,
    appVersion,
    appBuildNumber,
    deviceToken,
    apiVersion: pjson.version,
  };

  Device.update({ _id: deviceId }, device)
    .then(() => {
      if (!_.isEmpty(deviceToken)) {
        // Update devices with same token first to ensure notification won't go to wrong person.
        Device.update({
          deviceToken,
          _id: { $ne: deviceId },
        }, { deviceToken: '' }, { multi: true })
          .then((done) => { logger.info(done); })
          .catch((err) => { logger.error(err); });
      }

      res.status(200).json({ deviceId });
    })
    .catch((err) => {
      logger.error(err);
    });
};

deviceCtr.updateNotificationPref = (req, res) => {
  const { body } = req;
  const {
    deviceId,
    notificationPref,
  } = body;

  // Check Email is not already taken
  const device = {
    notificationPref: boolean(notificationPref),
  };

  Device.update({ _id: deviceId }, device)
    .then((data) => {
      logger.info(data);
      res.status(200).json({ deviceId });
    })
    .catch((err) => {
      logger.error(err);
    });
};

deviceCtr.sendTestPush = (req, res) => {
  Device.find({
    user: req.user._id,
    notificationPref: { $ne: false },
  })
    .then((deviceDocs) => {
      const devices = [];
      deviceDocs.forEach((device) => {
        devices.push(device.deviceToken);
      });
      notification.sendPush(devices, `Test Message : ${new Date()}`, {});
      res.status(200).json({});
    });
};
module.exports = deviceCtr;
