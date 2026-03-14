const wowza = {};
const logger = require('./logger');

wowza.createStreamTargetYt = (ingestionUrl, streamName, sourceStreamId) => {
  const parsed = new URL(ingestionUrl);
  const application = parsed.pathname.replace('/', '');
  return wowza.createStreamTarget(parsed.hostname, application, streamName, sourceStreamId, 'yt');
};

wowza.createStreamTargetFb = (streamUrl, sourceStreamId) => {
  const parsed = new URL(streamUrl);
  const application = 'rtmp';
  const streamName = parsed.pathname.replace('/rtmp', '').replace('/', '');
  return wowza.createStreamTarget(parsed.hostname, application, streamName, sourceStreamId, 'fb');
};

wowza.createStreamTarget = (hostname, application, streamName, sourceStreamId, publishTo) => {
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

  const apiUrl = `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/pushpublish/mapentries/${reqBody.entryName}`;

  return fetch(apiUrl, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(reqBody),
  })
    .then((response) => response.json())
    .then((body) => {
      logger.info(body);
      return body;
    });
};

wowza.deleteStreamTarget = (sourceStreamId, publishTo) => {
  const apiUrl = `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/pushpublish/mapentries/${publishTo}-${sourceStreamId}`;

  return fetch(apiUrl, {
    method: 'DELETE',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
  })
    .then((response) => response.json())
    .then((body) => {
      logger.info(body);
      return body;
    });
};

wowza.startStreamRecording = (sourceStreamId) => {
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

  const apiUrl = `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/instances/_definst_/streamrecorders/${sourceStreamId}`;

  return fetch(apiUrl, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(reqBody),
  })
    .then((response) => response.json())
    .then((body) => {
      logger.info(body);
      return body;
    });
};

wowza.stopStreamRecording = (sourceStreamId) => {
  const apiUrl = `${process.env.WowzaProtocol}://${process.env.WowzaHost}:${process.env.WowzaApiPort}/v2/servers/_defaultServer_/vhosts/_defaultVHost_/applications/live/instances/_definst_/streamrecorders/${sourceStreamId}/actions/stopRecording`;

  return fetch(apiUrl, {
    method: 'PUT',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
  })
    .then((response) => response.json())
    .then((body) => {
      logger.info(body);
      return body;
    });
};

module.exports = wowza;
