const mongoose = require('mongoose');

mongoose.Promise = global.Promise;

const deviceSchema = new mongoose.Schema({
  timeZone: {
    type: String,
    required: true,
  },
  deviceType: {
    type: String,
    required: true,
  },
  apiVersion: {
    type: String,
    required: true,
  },
  appIdentifier: {
    type: String,
    required: true,
  },
  badge: {
    type: Number,
    default: 0,
  },
  appName: {
    type: String,
    required: true,
  },
  appVersion: {
    type: String,
    required: true,
  },
  appBuildNumber: {
    type: String,
    required: true,
  },
  deviceToken: {
    type: String,
    required: false,
    default: '',
  },
  notificationPref: {
    type: Boolean,
    default: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
  },
}, { collection: 'device', timestamps: true });

const device = mongoose.model('device', deviceSchema);
module.exports = device;  
