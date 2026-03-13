const mongoose = require('mongoose');
const mongooseAggregatePaginate = require('mongoose-aggregate-paginate');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
  },
  password: {
    type: String,
  },
  phoneNumber: {
    type: String,
  },
  verification: {
    phone: {
      status: Boolean,
      code: String,
      expires: Date,
    },
    email: {
      status: Boolean,
      code: String,
      expires: Date,
    },
  },
  fbProvider:
    {
      id: {
        type: String,
      },
      accessToken: {
        type: String,
      },
    },
  profilePic: {
    type: String,
  },
  resetPassword: {
    newPassword: {
      type: String,
    },
    confirmationToken: {
      type: String,
    },
    expires: {
      type: Date,
    },
  },
  isBlocked: {
    type: Boolean,
  },
  goLiveReq: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'user',
    },
    reqCount: {
      type: Number,
      default: 1,
    },
  }],
}, { collection: 'user', timestamps: true });

userSchema.index({ email: 1 }, { unique: true });
userSchema.plugin(mongooseAggregatePaginate);
const user = mongoose.model('user', userSchema);
module.exports = user;  
