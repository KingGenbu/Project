const _ = require('lodash');
const fs = require('fs');
const moment = require('moment');
const path = require('path');

const logger = require('../../helper/logger');
const aws = require('../../helper/aws');
const constants = require('../../config/constants');
const Feed = require('./feedModel.js');
const Media = require('../media/mediaModel.js');
const Connection = require('../connection/connectionModel.js');
const User = require('../user/userModel');
const { ObjectId } = require('mongoose').Types;
const uuid = require('node-uuid');
const wowza = require('../../helper/wowza');
const notificationUtils = require('../notification/notificationUtils');
const connectionUtils = require('../connection/connectionUtils');
const feedUtils = require('./feedUtils');
const Device = require('../device/deviceModel');
const FeedList = require('./feedListModel');
const branch = require('../../helper/branch');
const notification = require('../../helper/notification');

const feedCtr = {};

feedCtr.newStory = (req, res) => {
  const {
    feedType, privacyLevel, sharedWith, caption,
  } = req.body;

  const { files } = req;
  const { s3Files } = files.story;

  const thumbs = [];

  Object.keys(s3Files).forEach((key) => {
    const thumb = s3Files[key];
    thumbs.push({
      size: thumb.id,
      path: thumb.url,
    });
  });

  const media = new Media({
    mimeType: files.story.type,
    path: s3Files.original.url,
    thumbs: thumbs,
    duration: s3Files.original.duration || null,
  });

  // Remove file
  if (fs.existsSync(files.story.path)) {
    fs.unlink(files.story.path);
  }

  media.save();

  const sharedUsers = [];
  if (!_.isEmpty(sharedWith) && privacyLevel !== 'Public') {
    const sharedWithUsers = sharedWith.split(',');
    sharedWithUsers.forEach((u) => {
      sharedUsers.push({ user: _.trim(u) });
    });
  }

  const feed = new Feed({
    user: req.user,
    media,
    feedType,
    privacy: {
      level: privacyLevel,
      sharedWith: sharedUsers,
    },
    caption,
    lastActive: new Date(),
    storyExpiration: new Date(moment().add(constants.story.expirationDays, 'days').format()),
  });

  feed.save()
    .then((result) => {
      // Update FeedList
      feedUtils.updateFeedListForUser(req.user._id);

      // Notification Send
      const wListed = sharedUsers.map((user) => { return ObjectId(user.user); });
      connectionUtils.getFollowers(req.user._id, wListed)
        .then((followers) => {
          const { users, devices } = followers;
          notificationUtils.sendBulkNotification(users, devices, 'ShareStory', { userId: req.user._id, feed: result._id });
        })
        .catch((err) => {
          logger.error(err);
          res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
        });
      res.status(200).json({ feedId: result._id });
    })
    .catch((err) => {
      logger.error(err);
    });
};

feedCtr.recentStories = (req, res) => {
  Feed.aggregate([
    {
      $match: {
        user: req.user._id,
      },
    }, {
      $sort: {
        updatedAt: -1,
      },
    }, {
      $match: {
        $and: [
          { feedType: { $ne: 'LiveStreamVideo' } },
          { feedType: { $ne: 'LiveStream' } },
        ],
      },
    }, { $limit: 6 }, {
      $lookup: {
        from: 'media',
        localField: 'media',
        foreignField: '_id',
        as: 'media',
      },
    }, {
      $unwind: '$media',
    }, {
      $project: {
        _id: 1,
        user: 1,
        'media.mimeType': 1,
        'media.path': 1,
        'media.thumbs': 1,
        'media.duration': 1,
        feedType: 1,
        privacy: 1,
        caption: 1,
        createdAt: 1,
        viewers: {
          $size: { $ifNull: ['$seenBy', []] },
        },
      },
    },
  ]).then((docs) => {
    res.status(200).json({ docs });
  }).catch(() => {
    res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  });
};

const followingsFeedList = (userId, page) => {
  return new Promise((resolve, reject) => {
    Connection.aggregate([
      {
        $match: {
          follower: userId,
        },
      },
    ])
      .then((connections) => {
        const userIds = [];
        _.forEach(connections, (user) => {
          userIds.push(user.followee);
        });
        // Add logged in user also
        // userIds.push(userId);
        return userIds;
      })
      .then((userIds) => {
        const aggregateRules = FeedList.aggregate([
          {
            $match: {
              user: {
                $in: userIds,
              },
            },
          },
          {
            $sort: {
              lastActive: -1,
            },
          },
          {
            $lookup: {
              from: 'user',
              localField: 'user',
              foreignField: '_id',
              as: 'user',
            },
          },
          {
            $unwind: '$user',
          },
          {
            $addFields: {
              isItzlit: {
                $arrayElemAt: [{
                  $filter: {
                    input: '$user.goLiveReq',
                    as: 'user',
                    cond: { $eq: ['$$user.user', userId] },
                  },
                }, 0], // Returns first index, because a user can follow a user only once
              },
            },
          },
          {
            $addFields: {
              stories: {
                $filter: {
                  input: {
                    $map: {
                      input: '$stories',
                      as: 'sa',
                      in: {
                        totalViewers: '$$sa.totalViewers',
                        totalComments: '$$sa.totalComments',
                        itzlitCount: '$$sa.itzlitCount',
                        streamStatus: '$$sa.streamStatus',
                        privacy: { sharedWith: '$$sa.privacy.sharedWith', level: '$$sa.privacy.level' },
                        storyExpiration: '$$sa.storyExpiration',
                        caption: '$$sa.caption',
                        feedType: '$$sa.feedType',
                        media: '$$sa.media',
                        createdAt: '$$sa.createdAt',
                        updatedAt: '$$sa.updatedAt',
                        _id: '$$sa._id',
                        level: '$$sa.privacy.level',
                        hideByUsers: '$$sa.hideByUsers',
                        sharedWith: {
                          $filter: {
                            input: '$$sa.privacy.sharedWith',
                            as: 'sn',
                            cond: {
                              $and: [
                                {
                                  $or: [
                                    { $ne: ['$$sa.privacy.level', 'Private'] },
                                    { $eq: ['$$sn.user', userId] },
                                  ],
                                },
                              ],
                            },
                          },
                        },
                      },
                    },
                  },
                  as: 'sa',
                  cond: {
                    $and: [
                      {
                        $gt: ['$$sa.storyExpiration', new Date()],
                      },
                      {
                        $not: { $setIsSubset: [[userId], '$$sa.hideByUsers'] },
                      },
                      {
                        $or:
                          [
                            { $eq: ['$$sa.level', 'Public'] },
                            {
                              $and:
                                [
                                  { $eq: ['$$sa.level', 'Private'] },
                                  { $ne: [{ $size: '$$sa.sharedWith' }, 0] },

                                ],
                            },
                          ],
                      },
                    ],
                  },
                },
              },
              liveStreams: {
                $filter: {
                  input: '$liveStreams',
                  as: 'live',
                  cond: {
                    $and: [
                      { $gt: ['$$live.storyExpiration', new Date()] },
                      { $not: { $setIsSubset: [[userId], '$$live.hideByUsers'] } },
                    ], 
                  },
                },
              },
            },
          },
          {
            $sort: {
              lastActive: -1,
            },
          },
          {
            $project: {
              'stories.totalViewers': 1,
              'stories.totalComments': 1,
              'stories.itzlitCount': 1,
              'stories.streamStatus': 1,
              'stories.privacy': 1,
              'stories.storyExpiration': 1,
              'stories.caption': 1,
              'stories.feedType': 1,
              'stories.media': 1,
              'stories.createdAt': 1,
              'stories.updatedAt': 1,
              'stories._id': 1,
              'liveStreams.totalViewers': 1,
              'liveStreams.totalComments': 1,
              'liveStreams.itzlitCount': 1,
              'liveStreams.streamStatus': 1,
              'liveStreams.privacy': 1,
              'liveStreams.storyExpiration': 1,
              'liveStreams.caption': 1,
              'liveStreams.feedType': 1,
              'liveStreams.media.thumbs': 1,
              'liveStreams.media.streamId': 1,
              'liveStreams.media.path': 1,
              'liveStreams.media.mimeType': 1,
              'liveStreams.media._id': 1,
              'liveStreams.createdAt': 1,
              'liveStreams.updatedAt': 1,
              'liveStreams._id': 1,              
              'user._id': 1,
              'user.fullName': 1,
              'user.profilePic': 1,
              isItzlit: {
                $cond: {
                  if: { $gte: ['$isItzlit', 0] },
                  then: true,
                  else: false,
                },
              },
            },
          },
        ]);
        const { limit } = constants.pager;
        FeedList.aggregatePaginate(aggregateRules, { page, limit }, (err, rDocs, pages, total) => {
          if (!err) {
            // TODO: Remove objects which are Hiden By user.
            // TODO: Remove objects which are Private and not shared with me.
            const docs = feedUtils.filterDocs(rDocs);
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
  });
};

feedCtr.stories = (req, res) => {
  const { page } = req.query;
  followingsFeedList(req.user._id, (page || 1))
    .then((followingsFeeds) => {
      res.status(200).json({ followingsFeeds });
    })
    .catch((err) => {
      logger.error(err);
    });
};

feedCtr.goLiveReq = (req, res) => {
  const { goLiveUser } = req.body;
  const user = req.user._id;

  User.aggregate([{
    $match: {
      $and: [
        {
          _id: ObjectId(goLiveUser),
        },
        {
          'goLiveReq.user': { $in: [user] },
        },
      ],
    },
  }])
    .then((users) => {
      if (users.length > 0) {
        // increase only cound don't send notification
        const userToUpdate = users[0];
        userToUpdate.goLiveReq.forEach((u, i) => {
          if (u.user.toString() === req.user._id.toString()) {
            userToUpdate.goLiveReq[i].reqCount += 1;
            User.update({
              _id: goLiveUser,
            }, {
              $set: {
                goLiveReq: userToUpdate.goLiveReq,
              },
            })
              .then(() => {
                res.status(200).json({ msg: req.t('MSG_GO_LIVE_REQ') });
              });
          }
        });
      } else {
        User.update({
          _id: goLiveUser,
        }, {
          $push: {
            goLiveReq: { user },
          },
        })
          .then(() => {
            // Send Notification
            Device.find({
              user: goLiveUser,
              notificationPref: { $ne: false },
            })
              .then((deviceDocs) => {
                const devices = [];
                deviceDocs.forEach((device) => {
                  devices.push(device.deviceToken);
                });
                // Send Notification
                // logger.info(feed.user._id);
                notificationUtils.sendNotification(goLiveUser, devices, 'GoLiveReq', { userId: req.user._id });
              });
            res.status(200).json({ msg: req.t('MSG_GO_LIVE_REQ') });
          })
          .catch((err) => { res.status(400).json({ error: err }); });
      }
    });
};

feedCtr.liveReqCount = (req, res) => {
  // Return count of total live request
  User.aggregate([
    {
      $match: {
        _id: req.user._id,
      },
    },
    {
      $project: {
        totalcount: {
          $size: '$goLiveReq',
        },
      },
    },
  ]).then((doc) => { res.status(200).json({ doc }); })
    .catch((err) => { res.status(500).json({ error: err }); });
};

feedCtr.liveReq = (req, res) => {
  User.aggregate([
    {
      $match: {
        _id: req.user._id,
      },
    },
    {
      $project: {
        goLiveReq: 1,
      },
    },
    {
      $unwind: '$goLiveReq',
    },
    {
      $lookup: {
        from: 'user',
        localField: 'goLiveReq.user',
        foreignField: '_id',
        as: 'user',
      },
    },
    {
      $unwind: '$user',
    },
    {
      $project: {
        'user._id': 1, 'user.fullName': 1, 'user.profilePic': 1,
      },
    },
  ]).then((doc) => { res.status(200).json({ doc }); })
    .catch((err) => { res.status(500).json({ error: err }); });
};

feedCtr.flushLiveReq = () => {
  User.update({

  }, {
    $set: {
      goLiveReq: [],
    },
  }, {
    upsert: true,
    multi: true,
  }).then((doc) => {
    logger.info(doc);
  }).catch((err) => {
    logger.error(err);
  });
};

feedCtr.activateStory = (req, res) => {
  const { feedId } = req.body;
  const now = new Date();

  Feed.findOneAndUpdate({ _id: feedId }, {
    $set: {
      lastActive: now,
      storyExpiration: new Date(moment().add(constants.story.expirationDays, 'days').format()),
    },
  })
    .then((feed) => {
      res.status(200).json({ feedId: feed._id });
      feedUtils.updateFeedListForUser(feed.user);
    }).catch((err) => {
      res.status(500).json({ error: err });
    });
};

feedCtr.addComment = (req, res) => {
  const { commentText, feedId } = req.body;
  const createdAt = new Date();
  const comment = {
    commentText, user: req.user._id, feedId, createdAt,
  };

  Feed.findOneAndUpdate({
    _id: feedId,
  }, {
    $push: {
      comments: comment,
    },
  }).then((feed) => {
    // Send Notification
    Device.find({
      user: feed.user.id,
      notificationPref: { $ne: false },
    })
      .then((deviceDocs) => {
        const devices = [];
        deviceDocs.forEach((device) => {
          devices.push(device.deviceToken);
        });
        // Send Notification
        // logger.info(feed.user._id);
        notificationUtils.sendNotification(feed.user.id, devices, 'FeedComment', { feed: feed._id, userId: req.user._id });
      });
    res.status(200).json({ msg: req.t('MSG_COMMENT_ADDED') });

    // Update count in cache
    feedUtils.updateFeedListForUser(ObjectId(feed.user.id));
  }).catch(() => {
    res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  });
};

feedCtr.liveReqCount = (req, res) => {
  // Return count of total live request
  User.aggregate([
    {
      $match: {
        _id: req.user._id,
      },
    },
    {
      $project: {
        totalcount: {
          $sum: '$goLiveReq.reqCount',
        },
      },
    },
  ]).then((doc) => { res.status(200).json({ doc }); })
    .catch((err) => { res.status(400).json({ error: err }); });
};

feedCtr.seen = (req, res) => {
  const { feedId } = req.body;
  const seen = { user: req.user._id };

  Feed.aggregate([
    {
      $match: {
        _id: ObjectId(feedId),
      },
    }, {
      $match: {
        'seenBy.user': {
          $eq: req.user._id,
        },
      },
    },
  ]).then((doc) => {
    if (doc.length > 0) {
      Feed.update({
        _id: feedId,
        'seenBy.user': req.user._id,
      }, {
        $inc: { 'seenBy.$.count': 1 },
      }).then((data) => {
        res.send(data);
      }).catch(() => {
        res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
      });
    } else {
      Feed.update({
        _id: feedId,
      }, {
        $addToSet: {
          seenBy: seen,
        },
      }).then((data) => {
        res.send(data);
      }).catch(() => {
        res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
      });

      Feed.findOne({
        _id: feedId,
      }, { user: 1 })
        .then((feed) => {
          feedUtils.updateFeedListForUser(feed.user);
        }).catch((err) => {
          logger.error(err);
        });
    }
  }).catch(() => {
    res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  });
};

feedCtr.seenBy = (req, res) => {
  // Return details of total users those are seen your feeds.
  const { feedId } = req.body;

  Feed.aggregate([
    {
      $match: {
        _id: ObjectId(feedId),
      },
    },
    {
      $unwind: '$seenBy',
    },
    {
      $lookup: {
        from: 'user',
        localField: 'seenBy.user',
        foreignField: '_id',
        as: 'user',
      },
    },
    {
      $unwind: '$user',
    },
    {
      $project: {
        'user._id': 1, 'user.fullName': 1, 'user.profilePic': 1,
      },
    },
  ]).then((doc) => { res.status(200).json({ doc }); })
    .catch((err) => { res.status(500).json({ error: err }); });
};

feedCtr.comments = (req, res) => {
  const { feedId } = req.params;

  Feed.aggregate([
    {
      $match: { _id: ObjectId(feedId) },
    }, {
      $unwind: '$comments',
    }, {
      $lookup: {
        from: 'user',
        localField: 'comments.user',
        foreignField: '_id',
        as: 'users',
      },
    }, {
      $unwind: '$users',
    }, {
      $project: {
        comments: 1, 'users.fullName': 1, 'users.profilePic': 1,
      },
    },
  ])
    .then((doc) => {
      res.status(200).json({ doc });
    })
    .catch((err) => { res.status(500).json({ error: err }); });
};

feedCtr.goLiveGetStreamId = (req, res) => {
  logger.info(req.body);
  const feedType = 'LiveStream';
  const privacyLevel = 'Public';
  const { caption } = req.body || '';
  let { streamToYt } = req.body || false;
  let { streamToItzlit } = req.body || false;
  let { streamToFb } = req.body || false;
  const { ingestionUrl, streamName } = req.body.yt || {};
  const { streamUrl } = req.body.fb || {};

  streamToYt = streamToYt === '1';
  streamToFb = streamToFb === '1';
  streamToItzlit = streamToItzlit === '1';

  logger.info('stream to...', [streamToYt, streamToFb, streamToItzlit]);

  const streamId = uuid.v1();
  const media = new Media({
    mimeType: 'vnd.apple.mpegURL',
    path: `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaPort}/${process.env.WowzaApp}/${streamId}/playlist.m3u8`,
    streamId,
  });

  media.save();

  const feed = new Feed({
    user: req.user,
    media,
    feedType,
    streamToYt,
    streamToItzlit,
    streamToFb,
    privacy: {
      level: privacyLevel,
    },
    caption,
    streamStatus: 'Created',
    lastActive: new Date(),
    storyExpiration: new Date(moment().add(constants.story.liveExpirationDays, 'days').format()),
  });

  feed.save()
    .then((result) => {
      feedUtils.updateFeedListForUser(req.user._id);
      // Create Wowza Stream Target!
      if (streamToYt) {
        logger.info('yt', [ingestionUrl, streamName, streamId]);
        wowza.createStreamTargetYt(ingestionUrl, streamName, streamId)
          .then(() => {

          })
          .catch((err) => {
            logger.error(err);
          });
      }

      if (streamToFb) {
        logger.info('fb', [streamUrl, streamId]);
        wowza.createStreamTargetFb(streamUrl, streamId)
          .then(() => {

          })
          .catch((err) => {
            logger.error(err);
          });
      }

      // Create Wowza Recorder
      wowza.startStreamRecording(streamId);


      // Notification Send

      res.status(200).json({ feedId: result._id, streamId: streamId });
    })
    .catch((err) => {
      logger.error(err);
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
};

feedCtr.goLiveSendNotification = (req, res) => {
  const { feedId } = req.body;
  connectionUtils.getFollowers(req.user._id)
    .then((followers) => {
      const { users, devices } = followers;
      notificationUtils.sendBulkNotification(users, devices, 'IsLive', { userId: req.user._id, feed: feedId });
    })
    .catch((err) => {
      logger.error(err);
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
  res.status(200).json({
    msg: req.t('MSG_NOTIFICATION_SENT'),
  });
};

feedCtr.goLiveStartPublishing = (req, res) => {
  const {
    feedId,
  } = req.body;

  Feed.update({
    _id: feedId,
  }, { streamStatus: 'Publishing' })
    .then(() => {
      feedUtils.updateFeedListForUser(req.user._id);
      res.status(200).json({
        msg: req.t('MSG_STREAM_STARTED'),
      });
    })
    .catch((err) => {
      logger.error(err);
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
};

feedCtr.goLiveStopPublishing = (req, res) => {
  const { feedId } = req.body;

  // connectionUtils.getFollowers(req.user._id)
  //   .then((followers) => {
  //     const { users, devices } = followers;
  // notificationUtils.sendBulkNotification(users, devices, 'WasLive', 
  //     { userId: req.user._id, feed: feedId });
  //   })
  //   .catch((err) => {
  //     logger.error(err);
  //     res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  //   });

  Feed.findOne({
    _id: feedId,
  })
    .then((feed) => {
      Media.findOne({
        _id: feed.media,
      })
        .then((media) => {
          if (media.streamId) {
            // const _media = media;
            // // Update to recorded Live Stream
            // _media.path = `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaPort}/vods3/_definst_/mp4:amazons3/${process.env.AwsS3BucketLiveStream}/liveStream/${media.streamId}.mp4/playlist.m3u8`;
            // _media.save();

            // wowza.stopStreamRecording(media.streamId);
            // Delete Wowza Recorder
            if (feed.streamToYt) {
              wowza.deleteStreamTarget(media.streamId, 'yt');
            }

            if (feed.streamToFb) {
              wowza.deleteStreamTarget(media.streamId, 'fb');
            }

            // feedUtils.updateFeedListForUser(req.user._id);
          }
        });
    });

  // Send notification to followers for user was Live!
  // Feed.update({
  //   _id: feedId,
  // }, { streamStatus: 'Ended', feedType: 'LiveStreamVideo' })
  //   .then(() => {
  res.status(200).json({
    msg: req.t('MSG_STREAM_STOPPED'),
  });
  // })
  // .catch((err) => {
  //   logger.error(err);
  //   res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  // });
};

feedCtr.itzlitUp = (req, res) => {
  const { feedId } = req.body;
  const userId = req.user._id;
  const users = { user: req.user._id };

  Feed.aggregate([
    {
      $match: {
        _id: ObjectId(feedId),
      },
    },
    {
      $lookup: {
        from: 'user',
        localField: 'user',
        foreignField: '_id',
        as: 'user',
      },
    },
    {
      $unwind: '$user',
    },
    {
      $match: {
        'itzlitBy.user': {
          $eq: req.user._id,
        },
      },
    },
  ]).then((doc) => {
    const feed = doc[0];
    if (doc.length > 0) {
      if (userId.toString() === doc[0].user._id.toString()) {
        Feed.update({
          _id: feedId,
          'itzlitBy.user': doc[0].user._id,
          'itzlitBy.count': { $ne: 5 },
        }, {
          $inc: { 'itzlitBy.$.count': 1 },
        }).then(() => {
          Feed.aggregate([
            {
              $match: {
                _id: ObjectId(feedId),
              },
            },
            {
              $project: {
                count: { $sum: '$itzlitBy.count' },
              },
            },
          ]).then((data) => {
            const sum = data[0].count;
            res.status(200).json({ count: data[0].count });
            if (sum === constants.maxLit) {
              // Send Notification
              Device.find({
                user: feed.user._id,
                notificationPref: { $ne: false },
              })
                .then((deviceDocs) => {
                  const devices = [];
                  deviceDocs.forEach((device) => {
                    devices.push(device.deviceToken);
                  });
                  // Send Notification
                  // logger.info(feed.user._id);
                  notificationUtils.sendNotification(feed.user._id, devices, 'ItzlitDone', { feed: feedId, userId: req.user._id });
                });
            }
            // Update count in cache
            return feedUtils.updateFeedListForUser(feed.user._id);
          });
        }).catch((err) => {
          logger.error(err);
          res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
        });
      } else {
        Feed.aggregate([
          {
            $match: {
              _id: ObjectId(feedId),
            },
          },
          {
            $project: {
              count: { $sum: '$itzlitBy.count' },
            },
          },
        ]).then((data) => {
          res.status(200).json({ count: data[0].count });
        }).catch((err) => {
          logger.error(err);
          res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
        });
      }
    } else {
      Feed.update({
        _id: feedId,
      }, {
        $push: {
          itzlitBy: users,
        },
      }).then(() => {
        Feed.aggregate([
          {
            $match: {
              _id: ObjectId(feedId),
            },
          },
          {
            $project: {
              user: 1,
              count: { $sum: '$itzlitBy.count' },
            },
          },
        ]).then((data) => {
          const sum = data[0].count;
          res.status(200).json({ count: data[0].count });
          if (sum === constants.maxLit) {
            // Send Notification
            Device.find({
              user: data[0].user,
              notificationPref: { $ne: false },
            })
              .then((deviceDocs) => {
                const devices = [];
                deviceDocs.forEach((device) => {
                  devices.push(device.deviceToken);
                });
                // Send Notification
                // logger.info(data[0].user);
                notificationUtils.sendNotification(data[0].user, devices, 'ItzlitDone', { feed: feedId, userId: req.user._id });
              });
          }
          // Update count in cache
          return feedUtils.updateFeedListForUser(data[0].user);
        }).catch((err) => {
          logger.error(err);
          res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
        });
      }).catch((err) => {
        logger.error(err);
        res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
      });
    }
  }).catch((err) => {
    logger.error(err);
    res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  });
};

feedCtr.hideByUser = (req, res) => {
  const { feedId } = req.body;
  const user = req.user._id;

  Feed.update({
    _id: feedId,
  }, {
    $push: {
      hideByUsers: { user },
    },
  })
    .then(() => {
      Feed.aggregate([
        {
          $match: {
            _id: ObjectId(feedId),
          },
        },
        {
          $project: {
            user: 1,
          },
        },
      ]).then((data) => {
        res.status(200).json({ msg: req.t('MSG_HIDE_FEED') });
        feedUtils.updateFeedListForUser(data[0].user);
      });
    })
    .catch((err) => {
      logger.error(err);
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
};

feedCtr.feedDetail = (req, res) => {
  const { feedId } = req.params;

  Feed.aggregate([
    {
      $match: { _id: ObjectId(feedId) },
    }, {
      $lookup: {
        from: 'media',
        localField: 'media',
        foreignField: '_id',
        as: 'media',
      },
    }, {
      $unwind: '$media',
    }, {
      $lookup: {
        from: 'user',
        localField: 'user',
        foreignField: '_id',
        as: 'user',
      },
    }, {
      $unwind: '$user',
    }, {
      $addFields: {
        comment: {
          $size: { $ifNull: ['$comments', []] },
        },
        viewers: {
          $size: { $ifNull: ['$seenBy', []] },
        },
        itzlitCount: { $sum: '$feed.itzlitBy.count' },
        isItzlit: {
          $arrayElemAt: [{
            $filter: {
              input: '$user.goLiveReq',
              as: 'user',
              cond: { $eq: ['$$user.user', req.user._id] },
            },
          }, 0], // Returns first index, because a user can follow a user only once
        },
      },
    }, {
      $project: {
        _id: 1,
        'user._id': 1,
        'user.fullName': 1,
        'user.profilePic': 1,
        'media._id': 1,
        'media.mimeType': 1,
        'media.path': 1,
        'media.thumbs': 1,
        'media.streamId': 1,
        'media.duration': 1,
        feedType: 1,
        caption: 1,
        streamStatus: 1,
        storyExpiration: 1,
        updatedAt: 1,
        createdAt: 1,
        privacy: 1,
        comment: 1,
        viewers: 1,
        itzlitCount: 1,
        branchLink: 1,
        isItzlit: {
          $cond: {
            if: { $gte: ['$isItzlit', 0] },
            then: true,
            else: false,
          },
        },
      },
    }]).then((doc) => { res.status(200).json({ doc }); })
    .catch(() => { res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') }); });
};

feedCtr.myStories = (req, res) => {
  // console.log(req);
  FeedList.aggregate([
    {
      $match: {
        user: req.user._id,
      },
    },
    /* {
      $unwind: {
        path: '$liveStreams',
        preserveNullAndEmptyArrays: true,
      },
    }, {
      $match: {
        'liveStreams.feed.hideByUsers.user': {
          $ne: req.user._id,
        },
      },
    }, 
    {
      $group: {
        _id: '$_id',
        user: { $first: '$user' },
        stories: { $first: '$stories' },
        isItzlit: { $first: '$isItzlit' },
        liveStreams: { $push: { feed: '$liveStreams.feed' } },
      },
    }, {
      $unwind: {
        path: '$stories',
        preserveNullAndEmptyArrays: true,
      },
    }, {
      $match: {
        'stories.feed.hideByUsers.user': { $ne: req.user._id },
      },
    },
    {
      $group: {
        _id: '$_id',
        // user: { $first: '$user' },
        stories: { $push: { feed: '$stories.feed' } },
        isItzlit: { $first: '$isItzlit' },
        liveStreams: { $first: '$liveStreams' },
      },
    }, */
    {
      $sort: {
        lastActive: -1,
      },
    },
    {
      $addFields: {
        comment: {
          $size: { $ifNull: ['$comments', []] },
        },
        viewers: {
          $size: { $ifNull: ['$seenBy', []] },
        },
        itzlitCount: { $sum: '$itzlitBy.count' },
      },
    }, {
      $project: {
        _id: 1,
        liveStreams: {
          $filter: {
            input: '$liveStreams',
            as: 'liveStream',
            cond: { $not: { $setIsSubset: [[req.user._id], '$$liveStream.hideByUsers'] } },
          },
        },

        stories: {
          $filter: {
            input: '$stories',
            as: 'story',
            cond: { $not: { $setIsSubset: [[req.user._id], '$$story.hideByUsers'] } },
          },
        },
        comment: 1,
        viewers: 1,
        itzlitCount: 1,
      },
    },
  ]).then((resultDocs) => {
    const docs = feedUtils.filterDocs(resultDocs);
    res.status(200).json({ docs });
  }).catch(() => {
    res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  });
};

feedCtr.snsNotification = (req, res) => {
  const messageType = req.body.Type;
  const message = JSON.parse(req.body.Message);

  if (messageType === 'Notification') {
    if (message.Records && message.Records[0].s3 && message.Records[0].s3.object) {
      const { key } = message.Records[0].s3.object;
      const streamId = path.basename(key).replace(path.extname(key), '');
      Media.aggregate([{
        $match: {
          streamId,
        },
      },
      {
        $lookup: {
          from: 'feed',
          localField: '_id',
          foreignField: 'media',
          as: 'feed',
        },
      },
      {
        $unwind: '$feed',
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
        $unwind: '$user',
      },

      ]).then((medias) => {
        const media = medias[0];

        if (media && media.streamId) {
          const _media = media;
          // Update to recorded Live Stream
          _media.path = `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaPort}/vods3/_definst_/mp4:amazons3/${process.env.AwsS3BucketLiveStream}/liveStream/${media.streamId}.mp4/playlist.m3u8`;

          media.feed.feedType = 'LiveStreamVideo';
          media.feed.streamStatus = 'Ended';

          Feed
            .update({ _id: media.feed._id }, media.feed)
            .then(() => {
              logger.info('Feed updated');
            })
            .catch((err) => {
              logger.error(err);
              res.status(200).json({});
            });

          aws.downloadObject(key)
            .then((file) => {
              feedUtils.prepareFilesForUploads(file, false)
                .then((uploadInfo) => {
                  logger.info(uploadInfo.files);
                  const originals = _.remove(uploadInfo.files, (f) => {
                    return f.id === 'original';
                  });

                  logger.info(uploadInfo.files);

                  const original = originals[0] || {};

                  if (!_.isEmpty(original)) {
                    aws.uploadFolder(uploadInfo.tempLocation, uploadInfo.files, 'liveStream')
                      .then((data) => {
                        const s3Files = _.keyBy(data, 'id');
                        logger.info(s3Files);
                        const thumbs = [];
                        Object.keys(s3Files).forEach((id) => {
                          const thumb = s3Files[id];
                          thumbs.push({
                            size: thumb.id,
                            path: thumb.url,
                          });
                        });

                        _media.mimeType = original.mime;
                        _media.thumbs = thumbs;
                        _media.duration = original.duration;

                        Media
                          .update({ _id: _media._id }, _media)
                          .then(() => {
                            logger.info('Media updated');
                            feedUtils.updateFeedListForUser(media.user._id);
                            res.status(200).json({});
                          })
                          .catch((err) => {
                            logger.error(err);
                            res.status(200).json({});
                          });

                        feedUtils.deleteTempFiles(uploadInfo.tempLocation);

                        // Create Branch Link
                        branch.link(media.feed._id, `${media.user.fullName} was live on ITZLIT!`, 'ITZLIT - Go Live on multiple platforms simultaneously and share stories with friends! 😎', s3Files.thumb_750x1334.url)
                          .then((link) => {
                            logger.info(`Branch URL : ${link.url}`);
                            media.feed.branchLink = link.url;
                            return Feed
                              .update({ _id: media.feed._id }, media.feed);
                          })
                          .catch((err) => {
                            logger.error(err);
                          });
                      })
                      .catch((err) => {
                        logger.error(err);
                        res.status(200).json({});
                      });
                  }
                })
                .catch((err) => {
                  logger.error(err);
                  res.status(200).json({});
                });
            })
            .catch((err) => {
              logger.error(err);
              res.status(200).json({});
            });

          // Delete Wowza Recorder
          if (media.feed.streamToYt) {
            wowza.deleteStreamTarget(media.streamId, 'yt');
          }

          if (media.feed.streamToFb) {
            wowza.deleteStreamTarget(media.streamId, 'fb');
          }
        }

        // res.status(200).json({});
      }).catch((err) => {
        logger.error(err);
        res.status(200).json({});
      });
    }
  }

  // res.status(200).json({ msg: 'Proccesed' });
};

feedCtr.removeFeed = (req, res) => {
  const { feedId } = req.body;
  Feed.findOneAndRemove({
    _id: feedId,
    user: req.user._id,
  })
    .then((doc) => {
      feedUtils.updateFeedListForUser(req.user._id);
      if (_.isEmpty(doc)) {
        res.status(401).json({ message: req.t('FEED_NOT_FOUND') });
      } else {
        res.status(200).json({ message: req.t('FEED_DELETED_SUCCESS') });
      }
    })
    .catch((err) => {
      logger.error(err);
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
};

feedCtr.report = (req, res) => {
  const { reportType, feedId } = req.body;
  const createdAt = new Date();
  const report = {
    reportType, user: req.user._id, feedId, createdAt,
  };

  Feed.findOneAndUpdate({
    _id: feedId,
    'reportedBy.user': { $ne: req.user._id },
  }, {
    $push: {
      reportedBy: report,
    },
  }).then((feed) => {
    notification.sendMail(process.env.ContactUSAdminEmail, 'report-feed', {
      name: req.user.fullName,
      feed: feedId,
    });

    res.status(200).json({ msg: req.t('MSG_FEED_REPORTED') });
    // Update count in cache
    feedUtils.updateFeedListForUser(ObjectId(feed.user.id));
  }).catch(() => {
    res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
  });
};
module.exports = feedCtr;
