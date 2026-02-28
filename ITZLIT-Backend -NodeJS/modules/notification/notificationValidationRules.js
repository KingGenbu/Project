const validator = {};
const input = {
  '/list': {

  },
};

validator.get = (route) => {
  return input[route];
};

module.exports = validator;
