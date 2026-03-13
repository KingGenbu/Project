const validator = {};
const input = {
  '/create': {
    fullName: { type: 'notEmpty' },
    password: {
      byPassWhen: 'fbProvider.id',
      rules: [
        { type: 'notEmpty' },
        { type: 'validPassword', msg: 'VALID_PASSWORD' },
      ],
    },
    email: [
      { type: 'notEmpty' },
      { type: 'isEmail', msg: 'VALID_EMAIL' },
    ],
    phoneNumber: [
      { type: 'notEmpty' },
      { type: 'isValidPhoneNumber' },
    ],
    deviceId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
    fbProvider: {
      isOptional: true,
      hasChilds: true,
      childs: {
        id: { type: 'notEmpty' },
        accessToken: { type: 'notEmpty' },
      },
    },
  },
  '/login': {
    email: [
      { type: 'notEmpty' },
      { type: 'isEmail', msg: 'VALID_EMAIL' },
    ],
    password: [
      { type: 'notEmpty' },
    ],
    deviceId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/fb-login': {
    deviceId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
    fbProvider: {
      hasChilds: true,
      childs: {
        id: { type: 'notEmpty' },
        accessToken: { type: 'notEmpty' },
      },
    },
  },
  '/forget-password': {
    email: [
      { type: 'notEmpty' },
      { type: 'isEmail', msg: 'VALID_EMAIL' },
    ],
  },
  '/change-password': {
    password: [
      { type: 'notEmpty' },
    ],
    newPassword: [
      { type: 'notEmpty' },
      { type: 'validPassword', msg: 'VALID_PASSWORD' },
    ],
  },
  '/logout': {
    deviceId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/update-profile': {
    email: {
      isOptional: true,
      rules: [
        { type: 'notEmpty' },
        { type: 'isEmail', msg: 'VALID_EMAIL' },
      ],
    },
  },
  '/send-invitation': {
    phoneNumber: [
      { type: 'notEmpty' },
      { type: 'isValidPhoneNumber' },
    ],
  },
};

validator.get = (route) => {
  return input[route];
};

module.exports = validator;
