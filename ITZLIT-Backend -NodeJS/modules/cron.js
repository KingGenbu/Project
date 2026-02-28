const _ = require('lodash');
const cron = require('node-cron');

const logger = require('../helper/logger');
const feedCtr = require('./feed/feedController');
const feedUtils = require('./feed/feedUtils');
const User = require('./user/userModel');

// 5am EST
cron.schedule('0 10 * * *', () => {
  logger.info('running a task every day 5am EST');
  feedCtr.flushLiveReq();
});

// cron.schedule('0 0 * * *', () => {
// logger.info('running a task every day midnight 12');
const updateFeedList = () => {
  User.find()
    .then((users) => {
      _.forEach(users, (user) => {
        feedUtils.updateFeedListForUser(user._id);
      });
    });
};
// });
updateFeedList();
