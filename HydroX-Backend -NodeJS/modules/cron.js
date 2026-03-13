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

const updateFeedList = () => {
  User.find()
    .then((users) => {
      users.forEach((user) => {
        feedUtils.updateFeedListForUser(user._id);
      });
    });
};
updateFeedList();
