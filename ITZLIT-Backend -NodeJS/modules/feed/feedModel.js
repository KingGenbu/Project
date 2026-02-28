const mongoose = require('mongoose');

const feedSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
    required: true,
  },
  media: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'media',
    required: true,
  },
  feedType: {
    type: String,
    required: true,
    enum: ['StoryImage', 'StoryVideo', 'LiveStream', 'LiveStreamVideo'],
  },
  streamStatus: {
    type: String,
    default: null,
    enum: [null, 'Created', 'Publishing', 'Ended'],
  },
  streamToYt: {
    type: Boolean,
    default: false,
  },
  streamToItzlit: {
    type: Boolean,
    default: false,
  },
  streamToFb: {
    type: Boolean,
    default: false,
  },
  caption: {
    type: String,
  },
  lastActive: {
    type: Date,
  },
  storyExpiration: {
    type: Date,
  },
  branchLink: {
    type: String,
  },
  privacy: {
    level: {
      type: String,
      required: true,
      enum: ['Public', 'Private'],
    },
    sharedWith: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'user',
        },
      },
    ],
  },
  hideByUsers: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'user',
    },
  }],
  comments: [{
    commentText: {
      type: String,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'user',
    },
    createdAt: {
      type: Date,
    },
  }],
  reportedBy: [{
    reportType: {
      type: String,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'user',
    },
    createdAt: {
      type: Date,
    },
  }],
  seenBy: [{
    count: {
      type: Number,
      default: 1,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'user',
    },
  }],
  itzlitBy: [{
    count: {
      type: Number,
      default: 1,
    },
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'user',
    },
  }],
}, { collection: 'feed', timestamps: true });

const feed = mongoose.model('feed', feedSchema);
module.exports = feed;  
