const Notification = require('./notificationModel');
const User = require('../user/userModel');
const notification = require('../../helper/notification');

const notificationUtils = {};

notificationUtils.NoteType = {
  Follow: 'Follow',
  IsLive: 'IsLive',
  // WasLive: 'WasLive',
  ShareStory: 'ShareStory',
  FeedComment: 'FeedComment',
  GoLiveReq: 'GoLiveReq',
  ItzlitDone: 'ItzlitDone',
};

const messageBuilder = (notificationType, extras) => {
  return new Promise((resolve, reject) => {
    if (notificationType === notificationUtils.NoteType.Follow) {
      User.findOne({ _id: extras.connection.follower })
        .then((doc) => {
          resolve(`${doc.fullName} started following you`);
        })
        .catch((err) => {
          reject(err);
        });
    } else if (notificationType === notificationUtils.NoteType.IsLive) {
      User.findOne({ _id: extras.userId })
        .then((doc) => {
          resolve(`${doc.fullName} is live now!`);
        })
        .catch((err) => {
          reject(err);
        });
    } else if (notificationType === notificationUtils.NoteType.ShareStory) {
      User.findOne({ _id: extras.userId })
        .then((doc) => {
          resolve(`${doc.fullName} just shared a new story!`);
        })
        .catch((err) => {
          reject(err);
        });
    } else if (notificationType === notificationUtils.NoteType.FeedComment) {
      User.findOne({ _id: extras.userId })
        .then((doc) => {
          resolve(`${doc.fullName} just commented on your story!`);
        })
        .catch((err) => {
          reject(err);
        });
    } else if (notificationType === notificationUtils.NoteType.GoLiveReq) {
      User.findOne({ _id: extras.userId })
        .then((doc) => {
          resolve(`${doc.fullName}  has Requested you to go live!`);
        })
        .catch((err) => {
          reject(err);
        });
    } else if (notificationType === notificationUtils.NoteType.ItzlitDone) {
      resolve('Your Live Stream is Lit! 😎');
    } else {
      reject(new Error('Not a valid notification'));
    }
  });
};

notificationUtils.addNotification = (user, notificationType, feed, connection) => {
  return new Promise((resolve, reject) => {
    messageBuilder(notificationType, { connection: connection.follower })
      .then((message) => {
        const note = new Notification({
          user,
          message,
          notificationType,
          feed,
          connection: connection._id,
        });
        note.save()
          .then(() => {
            resolve();
          })
          .catch((err) => {
            reject(err);
          });

        // Send push notification
      })
      .catch((err) => {
        reject(err);
      });
  });
};


notificationUtils.addBulkNotification = (users, notificationType, extras, message) => {
  return new Promise((resolve, reject) => {
    const notifications = [];
    users.forEach((user) => {
      const noteDoc = {
        user,
        message,
        notificationType,
      };

      if (extras.feed) {
        noteDoc.feed = extras.feed;
      }

      if (extras.connection) {
        noteDoc.connection = extras.connection._id;
      }

      if (extras.userId) {
        noteDoc.goLiveReqBy = extras.userId;
      }

      notifications.push(noteDoc);
    });

    Notification.insertMany(notifications)
      .then(() => {
        resolve();
      })
      .catch((err) => {
        reject(err);
      });
  });
};

notificationUtils.sendBulkNotification = (users, devices, notificationType, extras) => {
  messageBuilder(notificationType, extras)
    .then((message) => {
      // Send push
      notification.sendPush(devices, message, {
        type: notificationType,
        extras,
      });

      // Added to DB
      notificationUtils.addBulkNotification(users, notificationType, extras, message);
    });
};

notificationUtils.sendNotification = (user, devices, notificationType, extras) => {
  notificationUtils.sendBulkNotification([user], devices, notificationType, extras);
};
module.exports = notificationUtils;
