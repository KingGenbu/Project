const _ = require('lodash');
const Connection = require('./connectionModel.js');
const User = require('../user/userModel.js');
const Device = require('../device/deviceModel');
const logger = require('../../helper/logger');
const constants = require('../../config/constants');
const PhoneNumber = require('awesome-phonenumber');
const notificationUtils = require('../notification/notificationUtils');

const connectionCtr = {};

connectionCtr.follow = (req, res) => {
  const { followee } = req.body;

  if (followee === req.user._id.toString()) {
    res.status(400).json({ msg: req.t('ERR_FOLLOWED_YOURSELF') });
    return;
  }

  const connection = new Connection({
    followee,
    follower: req.user._id,
  });

  connection.save()
    .then(() => {
      res.status(200).json({ connectionId: connection._id, msg: req.t('MSG_FOLLOWED') });
      Device.find({
        user: followee,
        notificationPref: { $ne: false },
      })
        .then((deviceDocs) => {
          const devices = [];
          deviceDocs.forEach((device) => {
            devices.push(device.deviceToken);
          });
          // Send Notification
          notificationUtils.sendNotification(followee, devices, 'Follow', { connection });
        });
    })
    .catch((err) => {
      logger.error(err);
      if (err.code === 11000) {
        // Find correct document
        Connection.findOne({
          followee,
          follower: req.user._id,
        }).then((conn) => {
          // In case duplicate entry, just allow
          res.status(200).json({ connectionId: conn._id, msg: req.t('MSG_FOLLOWED') });
        });
      } else {
        res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
      }
    });
};

connectionCtr.unfollow = (req, res) => {
  const { connectionId } = req.body;
  Connection.findOneAndRemove({
    _id: connectionId,
    follower: req.user._id,
  })
    .then((done) => {
      if (done) {
        res.status(200).json({ msg: req.t('MSG_UNFOLLOWED') });
      } else {
        res.status(400).json({ msg: req.t('ERR_CONNECTION_NOT_FOUND') });
      }
    })
    .catch((err) => {
      logger.error(err);
    });
};

const getFollowersFollowings = (userId, type, page, q) => {
  return new Promise((resolve, reject) => {
    const matchRules = {};
    matchRules[type] = userId;

    const match = { $match: matchRules };
    const followeeLookup = {
      $lookup: {
        from: 'user',
        localField: 'followee',
        foreignField: '_id',
        as: 'followee',
      },
    };

    const followerLookup = {
      $lookup: {
        from: 'user',
        localField: 'follower',
        foreignField: '_id',
        as: 'follower',
      },
    };

    const unwindFollowee = { $unwind: '$followee' };
    const unwindFollower = { $unwind: '$follower' };

    const rules = [
      match,
      followeeLookup,
      followerLookup,
      unwindFollowee,
      unwindFollower,
      // Join with connection table to get follower's connections
      {
        $lookup: {
          from: 'connection',
          localField: 'follower._id',
          foreignField: 'followee',
          as: 'userFollowers',
        },
      },
      // Adding virtual field for `connections` and filter connections
      //  if logged in user is following
      {
        $addFields: {
          connection: {
            $arrayElemAt: [{
              $filter: {
                input: '$userFollowers',
                as: 'conn',
                cond: { $eq: ['$$conn.follower', userId] },
              },
            }, 0], // Returns first index, because a user can follow a user only once
          },
        },
      },
      {
        $addFields: {
          isFollowed: { $gt: ['$connection.follower', null] },
        },
      },
    ];

    if (!_.isEmpty(q)) {
      const matchRulesForSearch = {};
      const searchTrem = type === 'followee' ? 'follower' : 'followee';
      matchRulesForSearch[`${searchTrem}.fullName`] = { $regex: `^${q}`, $options: 'i' };

      const query = {
        $match: matchRulesForSearch,
      };
      rules.push(query);
    }

    const projectedFields = {
      'followee.fullName': 1, 'followee._id': 1, 'followee.profilePic': 1, 'follower.fullName': 1, 'follower._id': 1, 'follower.profilePic': 1,
    };

    if (type === 'followee') {
      projectedFields.isFollowed = 1;
      projectedFields.connecttionId = '$connection._id';
    } else {
      projectedFields.connecttionId = '$_id';
    }

    const projection = {
      $project: projectedFields,
    };

    rules.push(projection);

    const aggregateRules = Connection.aggregate(rules);

    const { limit } = constants.pager;

    Connection.aggregate([
      {
        $match: { follower: userId },
      },
      {
        $count: 'followingsCount',
      },
    ]).then((data) => {
      Connection.aggregate([
        {
          $match: { followee: userId },
        },
        {
          $count: 'followersCount',
        },
      ]).then((follower) => {
        Connection.aggregatePaginate(aggregateRules, { page, limit }, (err, docs, pages, total) => {
          if (!err) {
            const followings = {
              docs,
              followers: follower[0],
              followings: data[0],
              total,
              limit,
              page,
              pages,
            };
            resolve(followings);
          } else {
            reject(err);
          }
        });
      }).catch((err) => {
        logger.error(err);
      });
    }).catch((err) => {
      logger.error(err);
    });
  });
};

connectionCtr.followers = (req, res) => {
  const { page, q } = req.query;
  getFollowersFollowings(req.user._id, 'followee', (page || 1), q || '')
    .then((followers) => {
      res.status(200).json({ followers });
    })
    .catch((err) => {
      logger.error(err);
    });
};

connectionCtr.followings = (req, res) => {
  const { page, q } = req.query;
  getFollowersFollowings(req.user._id, 'follower', (page || 1), q || '')
    .then((followings) => {
      res.status(200).json({ followings });
    })
    .catch((err) => {
      logger.error(err);
    });
};

const convertNumbers = (contacts) => {
  return _.map(contacts, (contact) => {
    return contact.e164 || undefined;
  })
    .filter((item) => { return item !== undefined; });
};

const formatNumbers = (contacts, regionCode) => {
  return _.map(contacts, (_contact) => {
    const contact = _contact;
    const phone = new PhoneNumber(contact.number, regionCode || 'US');
    if (phone.isValid() && phone.isMobile()) {
      contact.e164 = phone.getNumber('e164');
    }
    return contact;
  });
};

connectionCtr.itzlitUsers = (req, res) => {
  const { contacts, regionCode } = req.body;
  const formattedContacts = formatNumbers(contacts, regionCode);
  const numbers = convertNumbers(formattedContacts);

  User.aggregate([
    // Find all `Users` with numbers
    { $match: { phoneNumber: { $in: numbers } } },
    // Join with `connection` collection, to get to know who all are in connection with someone
    {
      $lookup: {
        from: 'connection',
        localField: '_id',
        foreignField: 'followee',
        as: 'connections',
      },
    },
    // Adding virtual field for `connections` and filter connections if logged in user is following
    {
      $addFields: {
        connection: {
          $arrayElemAt: [{
            $filter: {
              input: '$connections',
              as: 'conn',
              cond: { $eq: ['$$conn.follower', req.user._id] },
            },
          }, 0], // Returns first index, because a user can follow a user only once
        },
      },
    },
    // Projecting a custom response
    {
      $project: {
        fullName: 1,
        email: 1,
        profilePic: 1,
        phoneNumber: 1,
        connecttionId: '$connection._id',
        isFollowed: { $gt: ['$connection.follower', null] }, // Actually checking if array contains element user is following.
      },
    },
  ])
    .then((users) => {
      const data = _.map(formattedContacts, (_contact) => {
        const contact = _contact;
        contact.connection = _.find(users, { phoneNumber: contact.e164 });
        delete contact.e164;
        return contact;
      });
      res.status(200).json(data);
    })
    .catch((err) => {
      logger.error(err);
    });
};

connectionCtr.search = (req, res) => {
  const { q, page } = req.query;

  const aggregateRules = User.aggregate([
    // Find all `Users` with matchin name
    { $match: { fullName: { $regex: `^${q}`, $options: 'i' } } },
    // Join with `connection` collection, to get to know who all are in connection with someone
    {
      $lookup: {
        from: 'connection',
        localField: '_id',
        foreignField: 'followee',
        as: 'connections',
      },
    },
    // Adding virtual field for `connections` and filter connections if logged in user is following
    {
      $addFields: {
        connection: {
          $arrayElemAt: [{
            $filter: {
              input: '$connections',
              as: 'conn',
              cond: { $eq: ['$$conn.follower', req.user._id] },
            },
          }, 0], // Returns first index, because a user can follow a user only once
        },
      },
    },
    // Projecting a custom response
    {
      $project: {
        fullName: 1,
        email: 1,
        profilePic: 1,
        phoneNumber: '', // TODO: Turned off phone number parameter for checking app crash or not
        connecttionId: '$connection._id',
        isFollowed: { $gt: ['$connection.follower', null] }, // Actually checking if array contains element user is following.
      },
    },
  ]);
  const { limit } = constants.pager;
  User.aggregatePaginate(aggregateRules, { page, limit }, (err, docs, pages, total) => {
    if (!err) {
      const results = {
        docs,
        total,
        limit,
        page,
        pages,
      };
      res.status(200).json({ results });
    } else {
      logger.error(err);
    }
  });
};
module.exports = connectionCtr;
