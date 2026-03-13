const nodemailer = require('nodemailer');
const logger = require('./logger');
const aws = require('./aws');
const apn = require('apn');

const options = {
  token: {
    key: process.env.ApnP8,
    keyId: process.env.ApnKeyId,
    teamId: process.env.ApnTeamId,
  },
  production: process.env.ApnPushEnv === 'Production',
};

const apnProvider = new apn.Provider(options);

// const sendmailTransport = require('nodemailer-sendmail-transport');

const user = process.env.SmtpUsername;
const pass = process.env.SmtpPassword;
const host = process.env.SmtpHost;
const port = process.env.SmtpPort;
const transporter = nodemailer.createTransport(`smtp://${user}:${pass}@${host}:${port}`);

const { EmailTemplate } = require('email-templates-v2');
const path = require('path');


// https://github.com/leemunroe/responsive-html-email-template
const sendMail = (to, templateName, data, replyTo) => {
  const templateDir = path.join(__dirname, '../templates', templateName);
  const template = new EmailTemplate(templateDir);
  template.render(data, (err, result) => {
    const { html, subject, text } = result;
    const mailOptions = {
      from: process.env.DefaultFrom,
      to,
      replyTo: replyTo || process.env.DefaultReplyTo,
      subject,
      text,
      html,
    };

    transporter.sendMail(mailOptions, (mailSendErr, info) => {
      if (!mailSendErr) {
        logger.info(`Message sent: ${info.response}`);
      } else {
        logger.error(mailSendErr, info);
      }
    });
  });
};

const sendSms = (to, templateName, data) => {
  const templateDir = path.join(__dirname, '../templates', templateName);
  const template = new EmailTemplate(templateDir);
  template.render(data, (err, result) => {
    if (!err) {
      const { text } = result;
      aws.publishSnsSMS(to, text)
        .then((done) => {
          logger.info(done);
        })
        .catch((publishErr) => {
          logger.error(publishErr);
        });
    } else {
      logger.error(err);
    }
  });
};

const sendPush = (devices, message, payload) => {
  if (devices && devices.length > 0) {
    const notification = new apn.Notification();
    notification.alert = message;
    notification.sound = 'Default';
    notification.topic = process.env.ApnBundleId;
    notification.payload = payload;
    apnProvider.send(notification, devices).then((response) => {
      logger.info(response.sent);
      logger.error(response.failed);
    });
  }
};

module.exports = {
  sendMail,
  sendSms,
  sendPush,
};

