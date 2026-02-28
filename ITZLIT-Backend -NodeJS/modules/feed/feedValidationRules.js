const _ = require('lodash');
const constants = require('../../config/constants');

const validator = {};
const input = {
  '/new-story': {
    feedType: { type: 'isValidEnum', options: { aEnum: ['StoryImage', 'StoryVideo', 'LiveStream', 'LiveStreamVideo'] } },
    privacyLevel: { type: 'isValidEnum', options: { aEnum: ['Public', 'Private'] } },
    sharedWith: {
      byPassWhen: (body) => {
        if (body.privacyLevel === 'Public') {
          return true;
        }
        return false;
      },
      rules: [{
        type: 'isCommaArray',
      },
      {
        type: 'notEmpty',
      }],
    },
    story: {
      isFile: true,
      rules: [
        {
          type: 'isValidMime', options: { aEnum: _.union(constants.supportedMime.image, constants.supportedMime.video) },
        },
      ],
    },
    caption: {
      isOptional: true,
      rules: [{ type: 'checkLength', options: { max: 100 } }],
    },
  },
  '/go-live-req': {
    goLiveUser: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/activate-story': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/add-comment': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
    commentText: {
      rules: [{ type: 'checkLength', options: { max: 500 } }, { type: 'notEmpty' }],
    },
  },
  '/seen': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/itzlit-up': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/go-live-start-publishing': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/go-live-send-notification': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/go-live-stop-publishing': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
  '/hide-by-users': {
    feedId: [
      { type: 'notEmpty' },
      { type: 'isValidMongoId' },
    ],
  },
};

validator.get = (route) => {
  return input[route];
};

module.exports = validator;
