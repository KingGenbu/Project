const validator = {};
const input = {
  '/follow': {
    followee: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/unfollow': {
    connectionId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
};

validator.get = (route) => {
  return input[route];
};

module.exports = validator;
