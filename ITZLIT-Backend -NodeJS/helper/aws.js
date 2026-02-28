const logger = require('./logger');
const aws = require('aws-sdk');
const uuid = require('node-uuid');
const Q = require('q');
const fs = require('fs');
const path = require('path');

aws.config = {
  accessKeyId: process.env.AwsAccessKey,
  secretAccessKey: process.env.AwsSecretAccessKey,
  region: process.env.AwsRegion,
  signatureVersion: 'v4',
};

const s3 = new aws.S3();
const sns = new aws.SNS({
  region: process.env.SnsAwsRegion,
});

const awsUtils = {};

awsUtils.getS3 = () => {
  return s3;
};

awsUtils.getPreSignedURL = (prefix) => {
  const s3ObjectKey = `${prefix}/${uuid.v1()}`;
  const deferred = Q.defer();

  s3.getSignedUrl('putObject', {
    Bucket: process.env.AwsS3Bucket,
    Expires: parseInt(process.env.PreSignedUrlExpiration, 10),
    Key: s3ObjectKey,
    ACL: 'public-read',
  }, (err, url) => {
    if (err == null) {
      deferred.resolve({
        preSignedUrl: url,
        key: s3ObjectKey,
        url: awsUtils.getS3Url(s3ObjectKey),
      });
    } else {
      logger.error(err);
    }
  });

  return deferred.promise;
};

awsUtils.getS3Url = (key) => {
  return `https://${process.env.AwsS3Bucket}.s3.amazonaws.com/${key}`;
};
awsUtils.getCFUrl = (key) => {
  return `https://${process.env.AwsCloudFront}/${key}`;
};
awsUtils.publishSnsSMS = (to, message) => {
  const deferred = Q.defer();
  const params = {
    Message: message,
    MessageStructure: 'string',
    PhoneNumber: to,
  };

  const paramsAtt = {
    attributes: { /* required */
      DefaultSMSType: 'Transactional',
      DefaultSenderID: 'ITZLIT',
    },
  };

  sns.setSMSAttributes(paramsAtt, (err, data) => {
    if (err) {
      logger.error(err, err.stack);
    } else {
      logger.info(data);
      sns.publish(params, (snsErr, snsData) => {
        if (snsErr) {
          // an error occurred
          logger.error(snsErr);
          deferred.reject(snsErr);
        } else {
          // successful response
          // logger.info(data);
          deferred.resolve(snsData);
        }
      });
    }
  });

  return deferred.promise;
};

awsUtils.getNewKey = (prefix, ext, thumbs) => {
  const id = uuid.v1();
  const thumbPaths = {};
  if (thumbs) {
    thumbs.forEach((thumb) => {
      thumbPaths[thumb.prefix] = {
        key: `${prefix}/${id}_${thumb.prefix}.${ext}`,
        width: thumb.width,
        height: thumb.height,
      };
    });
  }
  return thumbPaths;
};

awsUtils.putObject = (file, key) => {
  return new Promise((resolve, reject) => {
    fs.readFile(file.path, (error, fileContent) => {
      // if unable to read file contents, throw exception
      if (error) { throw error; }

      const params = {
        Body: fileContent,
        Bucket: process.env.AwsS3Bucket,
        Key: key,
        ACL: 'public-read',
        ContentType: file.mime,
        ContentDisposition: 'inline',
      };

      s3.putObject(params, (err, data) => {
        if (err) {
          reject(err);
        } else {
          logger.info(data);
          resolve({
            id: file.id, key, url: awsUtils.getCFUrl(key), duration: file.duration,
          });
        }
      });
    });
  });
};

awsUtils.uploadFolder = (folder, files, videoType) => {
  const vType = videoType || 'story';
  return new Promise((resolve, reject) => {
    const distFolderPath = `${vType}/${uuid.v1()}`;

    const promises = [];

    // Can use `forEach`, but used `every` as hack to break the loop
    files.every((file) => {
      // get the full path of the file
      const key = path.join(distFolderPath, path.basename(file.path));

      promises.push(awsUtils.putObject(file, key));
      return true;
    });

    Q.allSettled(promises)
      .then((results) => {
        const s3Files = [];
        results.forEach((result) => {
          if (result.state === 'fulfilled') {
            s3Files.push(result.value);
          } else {
            reject(result.reason);
          }
        });
        resolve(s3Files);
      });
  });
  // });
};

awsUtils.downloadObject = (key) => {
  return new Promise((resolve, reject) => {
    const params = {
      Bucket: process.env.AwsS3BucketLiveStream,
      Key: key,
    };

    const filePath = `/tmp/${path.basename(key)}`;
    logger.info('Started');
    s3.getObject(params, (err, data) => {
      if (err) {
        return reject(err);
      }

      fs.writeFile(filePath, data.Body, (errFile) => {
        if (errFile) {
          return reject(errFile);
        }
        logger.info('The file has been saved!', filePath);
        resolve({ path: filePath, type: data.ContentType });
      });
    });
  });
};

module.exports = awsUtils;
