const mongoose = require('mongoose');

const mediaSchema = new mongoose.Schema({
  mimeType: {
    type: String,
    required: true,
  },
  path: {
    type: String,
    required: true,
  },
  duration: {
    type: Number,
  },
  thumbs: [{
    size: {
      type: String,
      required: true,
      enum: ['thumb_300x300', 'thumb_100x100', 'original', 'thumb_750x1334'],
    },
    path: {
      type: String,
      required: true,
    },
  }],
  streamId: {
    type: String,
  },
}, { collection: 'media', timestamps: true });

const media = mongoose.model('media', mediaSchema);
module.exports = media;  
