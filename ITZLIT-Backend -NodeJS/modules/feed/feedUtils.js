const constants = require('../../config/constants');
const logger = require('../../helper/logger');
const FeedList = require('./feedListModel');
const Feed = require('./feedModel');

const fs = require('fs');
const path = require('path');
const uuid = require('node-uuid');
const ffmpeg = require('fluent-ffmpeg');
const sharp = require('sharp');
const rmdir = require('rmdir');
const Q = require('q');
const probe = require('node-ffprobe');
const _ = require('lodash');

const feedUtils = {};

const getVideoImageThumb = (file, originalFile, tempLocation, shouldRotate) => {
  return new Promise((resolveMain, rejectMain) => {
    return new Promise((resolve, reject) => {
      // Capture Frames if Video
      if (constants.supportedMime.video.indexOf(file.type) !== -1) {
        // File is video, generate Thumb from Video file
        feedUtils.generateScreenShot(originalFile, tempLocation, shouldRotate)
          .then((screenshot) => {
            resolve(`${tempLocation}/${screenshot}`);
          })
          .catch((err) => {
            reject(err);
          });
      } else {
        setTimeout(() => {
          resolve(originalFile);
        });
      }
    })
      .then((image) => {
        // Generate various thumbnails
        const ext = path.extname(image);
        const mime = `image/${ext.replace('.', '')}`;
        const thumbs = [
          {
            id: 'thumb_750x1334',
            width: 750,
            height: 1334,
            pathSufix: '750x1334',
            mime,
          },
          {
            id: 'thumb_300x300',
            width: 300,
            height: 300,
            pathSufix: '300x300',
            mime,
          },
        ];

        const resizePromises = [];
        thumbs.forEach((thumb) => {
          const _thumb = thumb;
          const thumbPromise = new Promise((resolveThumb, rejectThumb) => {
            _thumb.thumbPath = `${tempLocation}/${path.basename(image, ext)}_${thumb.pathSufix}${ext}`;
            sharp(image)
              .rotate()
              .resize(_thumb.width, _thumb.height).toFile(_thumb.thumbPath, (err) => {
                if (!err) {
                  resolveThumb(_thumb);
                } else {
                  rejectThumb(err);
                }
              });
          });
          resizePromises.push(thumbPromise);
        });


        Q.allSettled(resizePromises)
          .then((results) => {
            const thumbnails = [];
            results.forEach((result) => {
              thumbnails.push(result.value);
            });

            resolveMain({
              bigPath: image,
              thumbnails,
            });
          })
          .catch((err) => {
            rejectMain(err);
          });
      })
      .catch((err) => {
        rejectMain(err);
      });
  });
};

const getVideoDuration = (file, pFiles) => {
  const files = pFiles;
  return new Promise((resolve, reject) => {
    if (constants.supportedMime.video.indexOf(file.type) !== -1) {
      probe(file.path, (err, probeData) => {
        if (!err) {
          const original = _.find(files, 'id', 'original');
          const { duration } = probeData.format || 0;
          original.duration = duration;
          resolve(files);
        } else {
          reject(err);
        }
      });
    } else {
      const original = _.find(files, 'id', 'original');
      original.duration = constants.story.imageDuration;
      resolve(files);
    }
  });
};

feedUtils.prepareFilesForUploads = (pFile, shouldRotate) => {
  const file = pFile;
  return new Promise((resolve, reject) => {
    // logger.info(file);

    // Create temp location folder
    const tempLocation = `${__dirname}/../../uploads/${uuid.v1()}`;
    fs.mkdirSync(tempLocation);

    // Move original file to temp location
    const originalFile = `${tempLocation}/${path.basename(file.path)}`;
    fs.renameSync(file.path, originalFile);
    file.path = originalFile;

    // Generate thumbnail
    getVideoImageThumb(file, originalFile, tempLocation, shouldRotate)
      .then((images) => {
        const files = [];
        files.push({
          id: 'original',
          path: originalFile,
          mime: file.type,
        });

        images.thumbnails.forEach((thumb) => {
          files.push({
            id: thumb.id,
            path: thumb.thumbPath,
            mime: thumb.mime,
          });
        });

        return getVideoDuration(file, files);
      }).then((files) => {
        resolve({
          tempLocation,
          files,
        });
      })
      .catch((err) => {
        reject(err);
      });
  });
};

feedUtils.deleteTempFiles = (filePath) => {
  // Delete all files geenrated by `prepareFilesForUploads` Method
  rmdir(filePath);
};

feedUtils.generateScreenShot = (videoPath, tempLocation, shouldRotate) => {
  const rotate = shouldRotate ? 90 : 0;
  return new Promise((resolve, reject) => {
    let thumbFile = null;
    ffmpeg(videoPath)
      .on('filenames', (filenames) => {
        const ignore = [];
        [thumbFile, ...ignore.others] = filenames;
        logger.info(`Will generate screenshots ${filenames.join(', ')}`);
      })
      .on('end', () => {
        logger.info('Screenshots taken');
        sharp(`${tempLocation}/${thumbFile}`)
          .rotate(rotate)
          // .flop()
          .toFile(`${tempLocation}/rotate_${thumbFile}`, (err) => {
            if (!err) {
              resolve(`rotate_${thumbFile}`);
            } else {
              reject(err);
            }
          });
      })
      .on('error', (err) => {
        reject(err);
      })
      .takeScreenshots({
        count: 1,
        timemarks: ['1'],
        folder: tempLocation,
        filename: '%b_%i',
      });
  });
};

feedUtils.updateFeedListForUser = (userId) => {
  // Remove all existing
  FeedList.find({
    user: userId,
  }).remove()
    .then(() => {
      logger.info(`FeedList empty : ${userId}`);
      // Find and update list
      return Feed.aggregate([
        {
          $match: {
            user: userId,
            storyExpiration: {
              $gte: new Date(),
            },
          },
        },
        {
          $lookup: {
            from: 'media',
            localField: 'media',
            foreignField: '_id',
            as: 'media',
          },
        },
        {
          $unwind: '$media',
        },
        {
          $sort: {
            lastActive: -1,
          },
        },
        {
          $addFields: {
            itzlitCount: { $sum: '$itzlitBy.count' },
            totalComments: {
              $size: { $ifNull: ['$comments', []] },
            },
            totalViewers: {
              $size: { $ifNull: ['$seenBy', []] },
            },
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
          $project: {
            user: 1,
            hideByUsers: 1,
            feedType: 1,
            caption: 1,
            storyExpiration: 1,
            updatedAt: 1,
            createdAt: 1,
            privacy: 1,
            streamStatus: 1,
            media: 1,
            totalComments: 1,
            totalViewers: 1,
            itzlitCount: 1,
            branchLink: 1,
            lastActive: 1,
          },
        },
      ]);
    })
    .then((feeds) => {
      logger.info(`FeedList Updating : ${userId}`);
      const storyFeeds = [];
      const liveFeeds = [];

      const feedListItems = [];
      let lastAct;

      _.forEach(feeds, (feed) => {
        if (!lastAct || lastAct < feed.lastActive) {
          lastAct = feed.lastActive;
        }
        if (feed.feedType === 'StoryImage' || feed.feedType === 'StoryVideo') {
          const feedV2 = _.clone(feed);
          const hideByUsers = [];
          _.forEach(feedV2.hideByUsers, (hideByUser) => {
            hideByUsers.push(hideByUser.user);
          });
          feedV2.hideByUsers = hideByUsers;
          storyFeeds.push(feedV2);
        } else if (feed.feedType === 'LiveStream' || feed.feedType === 'LiveStreamVideo') {
          const feedV2 = _.clone(feed);
          const hideByUsers = [];
          _.forEach(feedV2.hideByUsers, (hideByUser) => {
            hideByUsers.push(hideByUser.user);
          });
          feedV2.hideByUsers = hideByUsers;
          liveFeeds.push(feedV2);
        }
      });

      if (storyFeeds.length > 0 || liveFeeds.length > 0) {
        const feedListStoryItem = {
          user: userId,
          stories: storyFeeds,
          liveStreams: liveFeeds,
          lastActive: lastAct,
        };
        feedListItems.push(feedListStoryItem);
      }

      return FeedList.insertMany(feedListItems);
    })
    .then(() => {
      logger.info(`FeedList Updated : ${userId}`);
    })
    .catch((err) => {
      logger.error(err);
    });
};

feedUtils.filterDocs = (docs) => {
  const filterDocs = [];
  for (let i = 0; i < docs.length; i += 1) {
    const singleDoc = docs[i];
    const liveStreams = [];
    _.forEach(singleDoc.liveStreams, (liveStream) => {
      if (!_.isEmpty(liveStream)) {
        liveStreams.push(liveStream);
      }
    });
    singleDoc.liveStreams = liveStreams;
    const stories = [];
    _.forEach(docs[i].stories, (story) => {
      if (!_.isEmpty(story)) {
        stories.push(story);
      }
    });
    singleDoc.stories = stories;
    if (stories.length > 0 || liveStreams.length > 0) {
      filterDocs.push(singleDoc);
    }
  }
  return filterDocs;
};

module.exports = feedUtils;
