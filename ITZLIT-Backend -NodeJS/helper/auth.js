const auth = {};
const request = require('request');
const Q = require('q');
const l10n = require('jm-ez-l10n');
const rn = require('random-number');
const uuid = require('node-uuid');

auth.generateOtp = () => {
  const options = {
    min: 100000,
    max: 999999,
    integer: true,
  };
  return rn(options);
};

auth.generateOtpEmail = () => {
  return uuid.v1();
};

auth.fbCheck = (fbProvider) => {
  const { id, accessToken } = fbProvider;
  const deferred = Q.defer();
  request(`https://graph.facebook.com/me?access_token=${accessToken}`, (err, response, data) => {
    if (!err) {
      const me = JSON.parse(data);
      if (response.statusCode === 200 && me.id === id) {
        // Valid user - allow to go forward
        deferred.resolve();
      } else {
        deferred.reject(l10n.t('FB_ACCESS_TOKEN_EXP'));
      }
    } else {
      deferred.reject(l10n.t('FB_ACCESS_TOKEN_EXP'));
    }
  });
  return deferred.promise;
};
module.exports = auth;
