const _ = require('lodash');
const User = require('./userModel.js');
const Device = require('../device/deviceModel.js');
const Connection = require('../connection/connectionModel');
const logger = require('../../helper/logger');
const awsUtils = require('../../helper/aws');
const md5 = require('md5');
const Q = require('q');
const auth = require('../../helper/auth');
const jwt = require('../../helper/jwt');
const uuid = require('node-uuid');
const generatePassword = require('password-generator');
const notification = require('../../helper/notification');
const PhoneNumber = require('awesome-phonenumber');
const constants = require('../../config/constants');
const l10n = require('jm-ez-l10n');

const userCtr = {};

userCtr.test = (req, res) => {
  notification.sendSms('+919725505555', 'phone-verification-otp', {
    link: `${process.env.DeepLinkRoot}/verify?otp=12345`,
  });
  res.send();

  // ffmpeg('/Users/jay.mehta/Downloads/IMG_5496.MOV')
  //   .on('filenames', (filenames) => {
  //     logger.info(`Will generate ${filenames.join(', ')}`);
  //   })
  //   .on('end', () => {
  //     logger.info('Screenshots taken');
  //   })
  //   .takeScreenshots({
  //     count: 1,
  //     timemarks: ['6', '1', '10'],
  //     folder: '/tmp',
  //   });
};
const sendVerificationOtp = (userId, onlySms) => {
  User.findOne({ _id: userId })
    .then((doc) => {
      const user = doc;
      const date = new Date();
      const phoneOtpExpires = new Date(date.setTime(date.getTime() + (15 * 60 * 1000))); // 15min

      user.verification.phone.status = false;
      user.verification.phone.code = auth.generateOtp();
      user.verification.phone.expires = phoneOtpExpires;

      if (onlySms !== true) {
        const emailOtpExpires =
          new Date(date.setTime(date.getTime() + (48 * 3600 * 1000))); // 2 days
        user.verification.email.status = false;
        user.verification.email.code = auth.generateOtpEmail();
        user.verification.email.expires = emailOtpExpires;
      }

      user.save()
        .then(() => {
          // Send OTP
          if (process.env.SendOtp !== 'false') {
            notification.sendSms(user.phoneNumber, 'phone-verification-otp', {
              link: `${process.env.DeepLinkRoot}/verify?otp=${user.verification.phone.code}`,
            });
          }

          if (onlySms !== true) {
            // Send Email Verification
            notification.sendMail(user.email, 'email-verification', {
              name: user.fullName,
              link: `${process.env.RootUrl}/api/v1/user/verify-email/${user._id}/${user.verification.email.code}`,
            });
          }
        });
    })
    .catch((err) => { logger.error(err); });
};

userCtr.create = (req, res) => {
  const { body } = req;
  const {
    fullName, email, phoneNumber, password, profilePic, deviceId, fbProvider, regionCode,
  } = body;

  const formattedPhoneNumber = PhoneNumber(phoneNumber, regionCode || 'US').getNumber('e164');

  // Check Email is not already taken
  const conditions = [{ email }, { phoneNumber: formattedPhoneNumber }];
  if (!_.isEmpty(fbProvider)) {
    conditions.push({ 'fbProvider.id': fbProvider.id });
  }

  User.findOne({ $or: conditions })
    .then((doc) => {
      if (doc) {
        if (doc.email === email) {
          return res.status(400).json({ error: req.t('ERR_EMAIL_ALREADY_EXIST') });
        } else if (doc.phoneNumber === formattedPhoneNumber) {
          return res.status(400).json({ error: req.t('ERR_PHONE_ALREADY_EXIST') });
        }
        return res.status(400).json({ error: req.t('FB_ALREADY_EXIST') });
      }

      const _user = {
        fullName,
        email,
        phoneNumber: formattedPhoneNumber,
        profilePic,
        fbProvider,
      };

      let fbPromise = null;

      if (!_.isEmpty(fbProvider)) {
        // Login Type - FB
        // Test FB details are valid
        fbPromise = auth.fbCheck(fbProvider);
      } else {
        _user.password = md5(password);
        const deferred = Q.defer();
        setTimeout(() => {
          deferred.resolve();
        });
        fbPromise = deferred.promise;
      }

      fbPromise
        .then(() => {
          const user = new User(_user);

          user.save()
            .then((result) => {
              // Follow to default followings
              const defaultFollowings = (process.env.DefaultFollowings || '').split(',');
              if (defaultFollowings.length > 0) {
                defaultFollowings.forEach((followee) => {
                  const connection = new Connection({
                    followee,
                    follower: user,
                  });

                  connection.save()
                    .then(() => { logger.info(`Followed - ${followee}`); })
                    .catch((err) => { logger.error(err); });
                });
              }
              // Update Device Document with `user` field
              Device.update({ _id: deviceId }, { user: user })
                .then((done) => { logger.info(done); })
                .catch((err) => { logger.error(err); });
              const token = jwt.getAuthToken({ id: result._id });
              res.status(200).json({ token, isVerified: false });
              sendVerificationOtp(user._id);
            })
            .catch((err) => {
              logger.error(err);
            });
        })
        .catch((err) => {
          res.status(200).json({ error: err });
        });
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.profilePicAWSPreSignedURL = (req, res) => {
  awsUtils.getPreSignedURL('profile-pic')
    .then((data) => {
      res.status(200).json(data);
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.login = (req, res) => {
  const {
    email, password, deviceId,
  } = req.body;

  User.findOne({ email, password: md5(password) })
    .then((user) => {
      if (user) {
        // Update Device Document with `user` field
        Device.update({ _id: deviceId }, { user: user })
          .then((done) => { logger.info(done); })
          .catch((err) => { logger.error(err); });
        // Generate JWT token
        const token = jwt.getAuthToken({ id: user._id });
        res.status(200).json({ token, isVerified: user.verification.phone.status });
      } else {
        res.status(400).json({
          error: req.t('WRONG_CREDENTIALS'),
        });
      }
    })
    .catch((err) => { logger.error(err); });
};

userCtr.fbLogin = (req, res) => {
  const { fbProvider, deviceId } = req.body;
  const {
    id,
  } = fbProvider;

  User.findOne({ 'fbProvider.id': id })
    .then((user) => {
      if (user) {
        // Generate JWT token
        auth.fbCheck(fbProvider)
          .then(() => {
            // Update Device Document with `user` field
            Device.update({ _id: deviceId }, { user: user })
              .then((done) => { logger.info(done); })
              .catch((err) => { logger.error(err); });
            const token = jwt.getAuthToken({ id: user._id });
            res.status(200).json({ token, isVerified: user.verification.phone.status });
          })
          .catch((err) => {
            res.status(400).json({
              error: err,
            });
          });
      } else {
        res.status(constants.statusCode.fbAccountNotFound).json({
          error: req.t('FB_LOGIN_FAILED'),
        });
      }
    })
    .catch((err) => { logger.error(err); });
};

userCtr.forgetPassword = (req, res) => {
  const { email } = req.body;

  User.findOne({ email })
    .then((doc) => {
      if (doc) {
        const user = doc;
        const randomPassword = generatePassword();
        const date = new Date();
        const expires = new Date(date.setTime(date.getTime() + (1 * 3600 * 1000)));
        user.resetPassword = {
          newPassword: md5(randomPassword),
          confirmationToken: uuid.v1(),
          expires,
        };
        user.save();
        notification.sendMail(user.email, 'forget-password', { name: user.fullName, link: `${process.env.RootUrl}/api/v1/user/reset-password/${user._id}/${user.resetPassword.confirmationToken}`, password: randomPassword });
        res.status(200).json({
          msg: req.t('RESET_PASSWORD_INSTRUCTION'),
        });
      } else {
        res.status(400).json({
          error: req.t('EMAIL_NOT_FOUND'),
        });
      }
    });
};

userCtr.resetPassword = (req, res) => {
  const { userId, cToken } = req.params;

  User.findOne({ _id: userId, 'resetPassword.confirmationToken': cToken, 'resetPassword.expires': { $gte: new Date() } })
    .then((doc) => {
      const user = doc;
      if (user) {
        if (!_.isEmpty(user.resetPassword) && !_.isEmpty(user.resetPassword.newPassword)) {
          user.password = user.resetPassword.newPassword;
          user.resetPassword = {};
          user.save();
        }

        res.writeHead(200, { 'content-type': 'text/html' });
        res.end(`<h3>${req.t('MSG_PASSWORD_CHANGED')}</h3>`);
      } else {
        res.writeHead(200, { 'content-type': 'text/html' });
        res.end(`<h3>${req.t('ERR_PASSWORD_RESET_LINK_EXP')}</h3>`);
      }
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.verifyEmail = (req, res) => {
  const { userId, vToken } = req.params;
  User.findOne({ _id: userId, 'verification.email.code': vToken, 'verification.email.expires': { $gte: new Date() } })
    .then((doc) => {
      const user = doc;
      if (user) {
        user.verification.email.status = true;
        user.verification.email.code = null;
        user.verification.email.expires = null;

        user.save();

        res.writeHead(200, { 'content-type': 'text/html' });
        res.end(`<h3>${req.t('MSG_EMAIL_VERIFIED')}</h3>`);
      } else {
        res.writeHead(200, { 'content-type': 'text/html' });
        res.end(`<h3>${req.t('ERR_EMAIL_LINK_EXP')}</h3>`);
      }
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.verifyNumber = (req, res) => {
  const { vCode } = req.params;

  User.findOne({ _id: req.user._id, 'verification.phone.code': vCode, 'verification.phone.expires': { $gte: new Date() } })
    .then((doc) => {
      const user = doc;
      if (user) {
        user.verification.phone.status = true;
        user.verification.phone.code = null;
        user.verification.phone.expires = null;
        user.save();

        res.status(200).json({ msg: req.t('MSG_PHONE_VERIFIED') });
      } else {
        res.status(400).json({ error: req.t('ERR_PHONE_LINK_EXP') });
      }
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.resendOtp = (req, res) => {
  User.findOne({ _id: req.user._id })
    .then((doc) => {
      const user = doc;
      if (user) {
        if (user.verification.phone.status === false) {
          sendVerificationOtp(user._id, true);
          res.status(200).json({ msg: req.t('MSG_PHONE_OTP_SEND') });
        } else {
          res.status(400).json({ error: req.t('ERR_PHONE_OTP_ALREADY_VERIFIED') });
        }
      } else {
        res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
      }
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.changePassword = (req, res) => {
  const { password, newPassword } = req.body;

  User.findOne({ _id: req.user._id, password: md5(password) })
    .then((doc) => {
      const user = doc;
      if (user) {
        user.password = md5(newPassword);
        user.save();
        res.status(200).json({ msg: req.t('MSG_PASSWORD_CHANGED') });
      } else {
        res.status(400).json({ error: req.t('ERR_OLD_PASSWORD_INCORRECT') });
      }
    })
    .catch((err) => {
      logger.error(err);
    });
};

userCtr.me = (req, res) => {
  const {
    email, fullName, phoneNumber, _id, profilePic,
  } = req.user;

  res.status(200).json({
    email, fullName, phoneNumber, _id, profilePic,
  });
};

userCtr.logout = (req, res) => {
  const { deviceId } = req.body;
  // Clean device token when user logout so that he don't get Push Notification
  Device.update({ _id: deviceId }, { deviceToken: '' })
    .then(() => {
      res.status(200).json({ msg: req.t('MSG_LOGOUT') });
    })
    .catch((err) => {
      res.status(400).json({ error: err });
    });
};

const isEmailExist = (email, userId) => {
  return new Promise((resolve, reject) => {
    User.findOne({ email, _id: { $ne: userId } })
      .then((doc) => {
        if (doc) {
          if (doc.email === email) {
            return reject(l10n.t('ERR_EMAIL_ALREADY_EXIST'));
          }
        }
        resolve();
      });
  });
};

const resolveEmailValidation = (aSyncValidations, email, user) => {
  return new Promise((resolve, reject) => {
    const _user = user;
    if (aSyncValidations.length > 0) {
      Q.allSettled(aSyncValidations)
        .then((results) => {
          results.forEach((result) => {
            if (result.state === 'fulfilled') {
              // Hack as it's only one promise for,
              //  to be fixed when multiple aSync validations will be there
              _user.email = email;
              resolve(_user);
            } else {
              reject(result.reason);
            }
          });
        });
    } else {
      setTimeout(() => {
        resolve(_user);
      });
    }
  });
};
userCtr.updateProfile = (req, res) => {
  const { fullName, email, profilePic } = req.body;

  const _user = {};
  if (!_.isEmpty(fullName)) {
    _user.fullName = fullName;
  }

  if (!_.isEmpty(profilePic)) {
    _user.profilePic = profilePic;
  }

  const aSyncValidations = [];
  if (!_.isEmpty(email)) {
    aSyncValidations.push(isEmailExist(email, req.user._id));
  }

  resolveEmailValidation(aSyncValidations, email, _user)
    .then((user) => {
      // Update user object
      User.update({ _id: req.user._id }, user)
        .then(() => { res.status(200).json({ msg: req.t('MSG_USER_PROFILE_UPDATED') }); })
        .catch((err) => { res.status(400).json({ error: err }); });
    })
    .catch((err) => {
      res.status(400).json({ error: err });
    });
};

userCtr.sendInvitation = (req, res) => {
  const { phoneNumber } = req.body;

  if (phoneNumber && !_.isEmpty(phoneNumber)) {
    notification.sendSms(phoneNumber, 'send-invitation');
  }
  res.status(200).json({ message: req.t('MSG_INVITATION_SENT') });
};

module.exports = userCtr;
