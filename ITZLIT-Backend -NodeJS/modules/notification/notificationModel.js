const mongoose = require('mongoose');
const mongooseAggregatePaginate = require('mongoose-aggregate-paginate');

const notificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
  },
  notificationType: {
    type: String,
    enum: ['Follow', 'NewFeed', 'FeedLike', 'FeedComment', 'IsLive', 'WasLive', 'ShareStory', 'GoLiveReq', 'ItzlitDone'],
  },
  message: {
    type: String,
  },
  feed: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'feed',
  },
  connection: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'connection',
  },
  goLiveReqBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
  },
}, { collection: 'notification', timestamps: true });

notificationSchema.plugin(mongooseAggregatePaginate);
const notification = mongoose.model('notification', notificationSchema);
module.exports = notification;  
