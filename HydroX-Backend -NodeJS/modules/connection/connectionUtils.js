const Connection = require('./connectionModel');

const connectionUtils = {};

connectionUtils.getFollowers = (user, whiteListed) => {
  const wListed = whiteListed || [];
  return new Promise((resolve, reject) => {
    const match = { followee: user };
    if (wListed.length > 0) {
      match.follower = { $in: wListed };
    }

    // Send notification to followers for user is Live now!
    Connection.aggregate([
      {
        $match: match,
      },
      {
        $lookup: {
          from: 'user',
          localField: 'follower',
          foreignField: '_id',
          as: 'follower',
        },
      }, {
        $unwind: '$follower',
      }, {
        $lookup: {
          from: 'device',
          localField: 'follower._id',
          foreignField: 'user',
          as: 'devices',
        },
      }]).then((followers) => {
      const devices = [];
      const users = [];
      followers.forEach((follower) => {
        users.push(follower.follower);
        if (follower.devices && follower.devices.length > 0) {
          follower.devices.forEach((device) => {
            if (device.notificationPref === true) {
              devices.push(device.deviceToken);
            }
          });
        }
      });

      resolve({ users, devices });
    })
      .catch((err) => {
        reject(err);
      });
  });
};

module.exports = connectionUtils;
