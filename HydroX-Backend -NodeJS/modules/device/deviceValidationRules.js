const validator = {};
const input = {
  '/create': {
    timeZone: { type: 'notEmpty' },
    deviceType: { type: 'isValidEnum', options: { aEnum: ['ios'] } },
    appIdentifier: { type: 'notEmpty' },
    appName: { type: 'notEmpty' },
    appVersion: { type: 'notEmpty' },
    appBuildNumber: { type: 'notEmpty' },
  },
  '/update': {
    deviceId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
    timeZone: { type: 'notEmpty' },
    deviceType: { type: 'isValidEnum', options: { aEnum: ['ios'] } },
    appIdentifier: { type: 'notEmpty' },
    appName: { type: 'notEmpty' },
    appVersion: { type: 'notEmpty' },
    appBuildNumber: { type: 'notEmpty' },
  },
  '/update-notification-pref': {
    deviceId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
    notificationPref: { type: 'notEmpty' },
  },
};

validator.get = (route) => {
  return input[route];
};

module.exports = validator;
