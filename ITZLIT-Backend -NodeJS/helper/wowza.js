const wowza = {};
const url = require('url');
const request = require('request');
const logger = require('./logger');

wowza.createStreamTargetYt = (ingestionUrl, streamName, sourceStreamId) => {
  const { hostname, path } = url.parse(ingestionUrl);
  const application = path.replace('/', '');
  return wowza.createStreamTarget(hostname, application, streamName, sourceStreamId, 'yt');
};

wowza.createStreamTargetFb = (streamUrl, sourceStreamId) => {
  const { hostname, path } = url.parse(streamUrl);
  const application = 'rtmp';
  const streamName = path.replace('/rtmp', '').replace('/', '');
  return wowza.createStreamTarget(hostname, application, streamName, sourceStreamId, 'fb');
};

wowza.createStreamTarget = (hostname, application, streamName, sourceStreamId, publishTo) => {
  return new Promise((resolve, reject) => {
    const reqBody = {
      serverName: '_defaultServer_',
      sourceStreamName: sourceStreamId,
      entryName: `${publishTo}-${sourceStreamId}`,
      profile: 'rtmp',
      host: hostname,
      application,
      userName: process.env.WowzaUsername,
      password: process.env.WowzaPassword,
      streamName,
    };

    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    };
    const options = {
      method: 'POST',
      body: reqBody,
      headers,
      json: true,
      url: `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/pushpublish/mapentries/${reqBody.entryName}`,
    };

    request(options, (error, response, body) => {
      if (error) {
        return reject(error);
      }
      logger.info(body);
      resolve(body);
    });
  });
};

wowza.deleteStreamTarget = (sourceStreamId, publishTo) => {
  return new Promise((resolve, reject) => {
    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    };
    const options = {
      method: 'DELETE',
      headers,
      json: true,
      url: `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/pushpublish/mapentries/${publishTo}-${sourceStreamId}`,
    };

    request(options, (error, response, body) => {
      if (error) {
        return reject(error);
      }
      logger.info(body);
      resolve(body);
    });
  });
};

wowza.startStreamRecording = (sourceStreamId) => {
  return new Promise((resolve, reject) => {
    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    };
    const reqBody = {
      instanceName: '',
      fileVersionDelegateName: '',
      serverName: '',
      recorderName: sourceStreamId,
      currentSize: 0,
      segmentSchedule: '',
      startOnKeyFrame: false,
      outputPath: '',
      currentFile: '',
      saveFieldList: [
        '',
      ],
      recordData: false,
      applicationName: '',
      moveFirstVideoFrameToZero: false,
      recorderErrorString: '',
      segmentSize: 0,
      defaultRecorder: false,
      splitOnTcDiscontinuity: false,
      version: '',
      baseFile: '',
      segmentDuration: 0,
      recordingStartTime: '',
      fileTemplate: '',
      backBufferTime: 0,
      segmentationType: '',
      currentDuration: 0,
      fileFormat: '',
      recorderState: '',
      option: '',
    };

    const options = {
      method: 'POST',
      body: reqBody,
      headers,
      json: true,
      url: `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/instances/_definst_/streamrecorders/${sourceStreamId}`,
    };

    request(options, (error, response, body) => {
      if (error) {
        return reject(error);
      }
      logger.info(body);
      resolve(body);
    });
  });
};

wowza.stopStreamRecording = (sourceStreamId) => {
  return new Promise((resolve, reject) => {
    const headers = {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    };
    const options = {
      method: 'PUT',
      headers,
      json: true,
      url: `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/instances/_definst_/streamrecorders/${sourceStreamId}/actions/stopRecording`,
    };

    request(options, (error, response, body) => {
      if (error) {
        return reject(error);
      }
      logger.info(body);
      resolve(body);
    });
  });
};

module.exports = wowza;
