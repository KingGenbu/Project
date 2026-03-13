const Notification = require('./notificationModel.js');
const logger = require('../../helper/logger');
const notification = require('../../helper/notification');
const constants = require('../../config/constants');

const notificationCtr = {};

const notificationList = (userId, page) => {
  return new Promise((resolve, reject) => {
    const aggregateRules = Notification.aggregate([{
      $match: {
        user: userId,
      },
    }, {
      $sort: {
        createdAt: -1,
      },
    }, {
      $lookup: {
        from: 'connection',
        localField: 'connection',
        foreignField: '_id',
        as: 'connection',
      },
    }, {
      $unwind: {
        path: '$connection',
        preserveNullAndEmptyArrays: true,
      },
    }, {
      $lookup: {
        from: 'user',
        localField: 'connection.follower',
        foreignField: '_id',
        as: 'follower',
      },
    }, {
      $unwind: {
        path: '$follower',
        preserveNullAndEmptyArrays: true,
      },
    }, {
      $lookup: {
        from: 'feed',
        localField: 'feed',
        foreignField: '_id',
        as: 'feed',
      },
    }, {
      $unwind: {
        path: '$feed',
        preserveNullAndEmptyArrays: true,
      },
    }, {
      $lookup: {
        from: 'media',
        localField: 'feed.media',
        foreignField: '_id',
        as: 'feed.media',
      },
    }, {
      $unwind: {
        path: '$feed.media',
        preserveNullAndEmptyArrays: true,
      },
    },
    {
      $lookup: {
        from: 'user',
        localField: 'feed.user',
        foreignField: '_id',
        as: 'user',
      },
    },
    {
      $unwind: {
        path: '$user',
        preserveNullAndEmptyArrays: true,
      },
    },
    {
      $lookup: {
        from: 'user',
        localField: 'goLiveReqBy',
        foreignField: '_id',
        as: 'goLiveReqBy',
      },
    },
    {
      $unwind: {
        path: '$goLiveReqBy',
        preserveNullAndEmptyArrays: true,
      },
    },
    {
      $project: {
        _id: 1,
        message: 1,
        createdAt: 1,
        notificationType: 1,
        'follower._id': 1,
        'follower.profilePic': 1,
        'connection.createdAt': 1,
        feedType: '$feed.feedType',
        media: '$feed.media',
        'user._id': 1,
        'user.fullName': 1,
        'user.profilePic': 1,
        'goLiveReqBy.fullName': 1,
        'goLiveReqBy.profilePic': 1,
      },
    }]);
    const { limit } = constants.pager;
    Notification.aggregatePaginate(aggregateRules, { page, limit }, (err, docs, pages, total) => {
      if (!err) {
        const results = {
          docs,
          total,
          limit,
          page,
          pages,
        };
        resolve(results);
      } else {
        reject(err);
      }
    });
  });
};

notificationCtr.list = (req, res) => {
  const { page } = req.query;
  logger.info(`req.user._id => ${req.user._id}`);
  notificationList(req.user._id, (page || 1))
    .then((notificationsList) => {
      res.status(200).json({ notificationsList });
    })
    .catch((err) => {
      logger.error(err);
    });
};

notificationCtr.contactUs = (req, res) => {
  const { name, email, message } = req.body;
  notification.sendMail(process.env.ContactUSAdminEmail, 'contact-us', {
    message,
    name,
    email,
  }, email);

  res.send('Thank you! Your message has been sent!');
};
module.exports = notificationCtr;
