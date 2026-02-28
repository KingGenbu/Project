const mongoose = require('mongoose');
const mongooseAggregatePaginate = require('mongoose-aggregate-paginate');

// Indexes
// db.getCollection('connection').createIndex( { followee: 1, follower: 1 }, { unique: true } )

const connectionSchema = new mongoose.Schema({
  followee: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
    required: true,
  },
  follower: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'user',
    required: true,
  },
  isBlocked: {
    type: Boolean,
    default: false,
  },
}, { collection: 'connection', timestamps: true });

connectionSchema.index({ followee: 1, follower: 1 }, { unique: true });
connectionSchema.plugin(mongooseAggregatePaginate);
const connection = mongoose.model('connection', connectionSchema);
module.exports = connection;  
