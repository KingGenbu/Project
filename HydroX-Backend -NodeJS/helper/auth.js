const auth = {};
const { randomUUID, randomInt } = require('crypto');
const l10n = require('jm-ez-l10n');

auth.generateOtp = () => {
  return randomInt(100000, 1000000);
};

auth.generateOtpEmail = () => {
  return randomUUID();
};

auth.fbCheck = (fbProvider) => {
  const { id, accessToken } = fbProvider;
  return fetch(`https://graph.facebook.com/me?access_token=${accessToken}`)
    .then((response) => {
      if (!response.ok) {
        return Promise.reject(l10n.t('FB_ACCESS_TOKEN_EXP'));
      }
      return response.json();
    })
    .then((me) => {
      if (me.id === id) {
        return Promise.resolve();
      }
      return Promise.reject(l10n.t('FB_ACCESS_TOKEN_EXP'));
    })
    .catch(() => {
      return Promise.reject(l10n.t('FB_ACCESS_TOKEN_EXP'));
    });
};
module.exports = auth;
