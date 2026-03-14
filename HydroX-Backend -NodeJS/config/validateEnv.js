const logger = require('../helper/logger');

const requiredEnvVars = [
  // Server
  'PORT',
  'DB_URL',
  'JwtSecret',

  // AWS
  'AwsAccessKey',
  'AwsSecretAccessKey',
  'AwsRegion',
  'AwsS3Bucket',

  // SMTP
  'SmtpHost',
  'SmtpPort',
  'SmtpUsername',
  'SmtpPassword',
  'DefaultFrom',

  // APN
  'ApnP8',
  'ApnKeyId',
  'ApnTeamId',
  'ApnBundleId',
];

const validateEnv = () => {
  const missing = requiredEnvVars.filter((envVar) => !process.env[envVar]);

  if (missing.length > 0) {
    logger.error(`Missing required environment variables: ${missing.join(', ')}`);
    logger.error('Please check your .env file or environment configuration.');
    process.exit(1);
  }

  logger.info('Environment variables validated successfully.');
};

module.exports = validateEnv;
