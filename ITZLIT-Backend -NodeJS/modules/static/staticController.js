const staticUtils = require('./staticUtils');

const staticCtr = {};

staticCtr.privacyPolicy = (req, res) => {
  staticUtils.getStaticContent('privacy-policy')
    .then((content) => {
      res.send(content);
    })
    .catch(() => {
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
};

staticCtr.termsOfUse = (req, res) => {
  staticUtils.getStaticContent('terms-of-use')
    .then((content) => {
      res.send(content);
    })
    .catch(() => {
      res.status(500).json({ error: req.t('ERR_INTERNAL_SERVER_ERROR') });
    });
};

module.exports = staticCtr;
