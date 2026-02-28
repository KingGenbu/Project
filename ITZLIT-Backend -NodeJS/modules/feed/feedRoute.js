const _ = require('lodash');
const express = require('express');
const feedCtr = require('./feedController.js');
const middleware = require('../../middleware.js');
const validationRules = require('./feedValidationRules.js');
const constants = require('../../config/constants');
const logger = require('../../helper/logger');
const aws = require('../../helper/aws');
const multipart = require('connect-multiparty');
const feedUtils = require('./feedUtils.js');

const multipartMiddleware = multipart();

const feedRouter = express.Router();

// Convert 
feedRouter.use(multipartMiddleware);

// Inject Validation Rules
feedRouter.use((req, res, next) => {
  req.validations = validationRules.get(req.path);
  next();
});

// Perform Validations
feedRouter.use(middleware.reqValidator);

// Load Logged in user
feedRouter.use([(req, res, next) => {
  req.byPassRoutes = ['/sns-notification']; // Add Urls to by pass auth protection
  next();
}, middleware.loadUser]);

const upload = {
  single: (field) => {
    return (req, res, next) => {
      // const keys = aws.getNewKey('story', 'jpg', [
      //   { prefix: 'original', width: 750, height: 1334 },
      //   { prefix: 'thumb_100x100', width: 100, height: 100 },
      // ]);

      // logger.info(keys);
      const file = req.files[field];
      // Custome Validations
      if (req.body.feedType === 'StoryImage' && constants.supportedMime.image.indexOf(file.type) === -1) {
        return res.status(400).json({ error: req.t('ERR_UNSUPPORTED_FILE') });
      } else if (req.body.feedType === 'StoryVideo' && constants.supportedMime.video.indexOf(file.type) === -1) {
        return res.status(400).json({ error: req.t('ERR_UNSUPPORTED_FILE') });
      }

      // Prepare files for S3 Uploads - Resize, Create Thumbs from Video, etc.
      feedUtils.prepareFilesForUploads(req.files[field], true)
        .then((uploadInfo) => {
          aws.uploadFolder(uploadInfo.tempLocation, uploadInfo.files)
            .then((data) => {
              req.files[field].s3Files = _.keyBy(data, 'id');
              feedUtils.deleteTempFiles(uploadInfo.tempLocation);
              next();
            });
        })
        .catch((err) => {
          logger.info(err);
          res.status(500).json({ error: req.t('ERR_FILE_PROCESS_ERROR') });
        });
    };
  },
};

// Routes
feedRouter.post('/new-story', upload.single('story'), feedCtr.newStory);
feedRouter.get('/recent-stories', feedCtr.recentStories);
feedRouter.get('/stories', feedCtr.stories);
feedRouter.post('/go-live-req', feedCtr.goLiveReq);
feedRouter.get('/live-req-count', feedCtr.liveReqCount);
feedRouter.get('/live-req', feedCtr.liveReq);
feedRouter.post('/activate-story', feedCtr.activateStory);
feedRouter.post('/add-comment', feedCtr.addComment);
feedRouter.post('/report', feedCtr.report);
feedRouter.get('/comments/:feedId', feedCtr.comments);
feedRouter.post('/seen', feedCtr.seen);
feedRouter.post('/seen-by', feedCtr.seenBy);
feedRouter.post('/go-live-get-stream-id', feedCtr.goLiveGetStreamId);
feedRouter.post('/go-live-start-publishing', feedCtr.goLiveStartPublishing);
feedRouter.post('/go-live-send-notification', feedCtr.goLiveSendNotification);
feedRouter.post('/go-live-stop-publishing', feedCtr.goLiveStopPublishing);
feedRouter.post('/itzlit-up', feedCtr.itzlitUp);
feedRouter.post('/hide-by-user', feedCtr.hideByUser);
feedRouter.get('/feed-detail/:feedId', feedCtr.feedDetail);
feedRouter.get('/my-stories', feedCtr.myStories);
feedRouter.post('/sns-notification', feedCtr.snsNotification);
feedRouter.post('/remove-feed', feedCtr.removeFeed);

module.exports = feedRouter;

