const logger = require('../../helper/logger');
const { EmailTemplate } = require('email-templates-v2');
const path = require('path');

const staticUtils = {};

staticUtils.getStaticContent = (templateName, data) => {
  const templateDir = path.join(__dirname, '../../templates', templateName);
  const template = new EmailTemplate(templateDir);
  return new Promise((resolve, reject) => {
    template.render(data, (err, result) => {
      if (!err) {
        const { html } = result;
        resolve(html);
      } else {
        logger.error(err);
        reject.error(err);
      }
    });
  });
};

module.exports = staticUtils;
