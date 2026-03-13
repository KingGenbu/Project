const _ = require('lodash');
const isEmail = require('isemail');
const isFloat = require('is-float');
// const utils = require('../helper/utils.js');
const isAlphanumeric = require('is-alphanumeric');
const passwordRules = require('password-rules');
const isValidUSZip = require('is-valid-zip');
const PhoneNumber = require('awesome-phonenumber');
const l10n = require('jm-ez-l10n');


const validator = {};
validator.isValidMime = (str, options) => {
  if (str) {
    return validator.isValidEnum(str.type, options);
  }
  return false;
};

validator.isValidMongoId = (str) => {
  return str.match(/^[0-9a-fA-F]{24}$/);
};

validator.isValid = (str) => {
  if (typeof str !== 'string' || _.isEmpty(str)) {
    return false;
  }
  return true;
};

validator.notEmpty = (str) => {
  return !_.isEmpty(str);
};

validator.isArray = (str) => {
  return _.isArray(str);
};

validator.isCommaArray = (str) => {
  return _.isArray(str.split(','));
};

validator.isAlphanumeric = (str) => {
  return isAlphanumeric(str);
};

validator.isInt = (str) => {
  if (typeof str !== 'number') {
    return false;
  }
  return true;
};

validator.isFloat = (str) => {
  return isFloat(str);
};

validator.isEmail = (str) => {
  if (str) {
    return isEmail.validate(str);
  }
  return false;
};

validator.isValidPhoneNumber = (str) => {
  const pn = new PhoneNumber(str);
  return pn.isValid() && pn.isMobile();
};

validator.isValidRex = (str, options) => {
  const { rex } = options;
  if (this.isValid(str)) {
    if (!_.isEmpty(rex)) {
      return rex.test(str);
    }
    return false;
  }
  return false;
};

validator.isValidEnum = (str, options) => {
  const { aEnum } = options;
  if (!_.isEmpty(str)) {
    if (!_.isEmpty(aEnum) && aEnum.indexOf(str) !== -1) {
      return true;
    }
    return false;
  }
  return false;
};

validator.validPassword = (str) => {
  const hasError = passwordRules(str, {
    minimumLength: 6,
    maximumLength: 30,
    requireCapital: true,
    requireLower: true,
    requireNumber: false,
    requireSpecial: false,
  });

  if (hasError) {
    return false;
  }
  return true;
};

// Only US Zipcode
validator.isValidUSZip = (str) => {
  return isValidUSZip(str);
};

validator.checkLength = (str, options) => {
  const { min, max } = options;
  if (_.isFinite(min) && min > 0) {
    if (str.length < min) {
      return false;
    }
  }

  if (_.isFinite(max) && max > 0) {
    if (str.length > max) {
      return false;
    }
  }
  return true;
};

const strToObj = (str, obj) => {
  return str.split('.').reduce((o, i) => {
    if (!o) {
      return undefined;
    }
    return o[i];
  }, obj);
};

const validate = (req, validationRules, parentKey) => {
  const { body, files } = req;
  let input = {};
  let error = {};

  if (!_.isEmpty(validationRules)) {
    // Can use `forEach`, but used `every` as hack to break the loop
    Object.keys(validationRules).every((key) => {
      let validations = validationRules[key];
      if (validations.isFile) {
        input = files;
      } else {
        input = body;
      }
      if (validations.isOptional && _.isEmpty(input[key])) {
        return error;
      }
      if (!_.isEmpty(validations.byPassWhen) || typeof validations.byPassWhen === 'function') {
        if (typeof validations.byPassWhen === 'function') {
          if (validations.byPassWhen(input)) {
            return error;
          }
        } else if (!_.isEmpty(strToObj(validations.byPassWhen, input))) {
          return error;
        }
      }

      if (validations.hasChilds && validations.hasChilds === true) {
        if (_.isEmpty(input[key])) {
          const generatedError = validator.getGeneratedError((parentKey ? `${parentKey}.` : '') + key, 'notEmpty');
          error = {
            statusCode: 400,
            field: key,
            type: 'notEmpty',
            error: generatedError,
            generatedError: generatedError,
          };
        } else {
          error = validate({ body: input[key] }, validations.childs, key);
        }

        return false; // To break the `every` loop
      }

      if (!_.isArray(validations)) {
        if (_.isEmpty(validations.rules)) {
          validations = [validations];
        } else {
          validations = validations.rules;
        }
      }

      // Can use `forEach`, but used `every` as hack to break the loop
      validations.every((validation) => {
        if (!_.isEmpty(validation)) {
          const {
            type, msg, options, statusCode,
          } = validation;
          if (!validator[type](input[key], options)) {
            const generatedError = validator.getGeneratedError((parentKey ? `${parentKey}.` : '') + key, type, options);
            error = {
              statusCode: statusCode || 400,
              field: key,
              type: type,
              error: msg ? l10n.t(msg) : null || generatedError,
              generatedError: generatedError,
            };
            return false;
          }
        }
        return true;
      });

      if (!_.isEmpty(error)) {
        return false;
      }
      return true;
    });
  }
  return error;
};

validator.getGeneratedError = (field, type, options) => {
  switch (type) {
  case 'notEmpty':
    return `${field} is required`;
  case 'isValidPhoneNumber':
    return `${field} is not valid`;
  case 'isValidMime':
    return `${field} - Unsopported file format`;
  case 'checkLength':
    if (_.isFinite(options.max) && _.isFinite(options.min)) {
      return `${field} should be at-least of ${options.min} and maximum of ${options.max} char`;
    } else if (_.isFinite(options.max)) {
      return `${field} should maximum of ${options.max} char`;
    } else if (_.isFinite(options.min)) {
      return `${field} should at-least of ${options.min} char`;
    }
    return `${field} - error - ${type}`;
  default:
    return `${field} - error - ${type}`;
  }
};

module.exports = {
  validate: validate,
};
