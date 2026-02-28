const mongoose = require('mongoose');
const mongooseAggregatePaginate = require('mongoose-aggregate-paginate');

const feedListSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
    required: true,
  },
  stories: [{
    type: mongoose.Schema.Types.Mixed,
  }],
  liveStreams: [{
    type: mongoose.Schema.Types.Mixed,
  }],
  lastActive: {
    type: Date,
  },
}, { collection: 'feedList', timestamps: true });

feedListSchema.plugin(mongooseAggregatePaginate);
const feed = mongoose.model('feedList', feedListSchema);
module.exports = feed;  
