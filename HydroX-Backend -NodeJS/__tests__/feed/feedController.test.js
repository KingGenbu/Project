'use strict';

// ── All external dependencies mocked ─────────────────────────────────────────

jest.mock('../../helper/logger', () => ({ info: jest.fn(), error: jest.fn(), warn: jest.fn() }));
jest.mock('../../helper/aws', () => ({ downloadObject: jest.fn(), uploadFolder: jest.fn(), getCFUrl: jest.fn() }));
jest.mock('../../helper/wowza', () => ({
  createStreamTargetYt: jest.fn().mockResolvedValue({}),
  createStreamTargetFb: jest.fn().mockResolvedValue({}),
  startStreamRecording: jest.fn(),
  stopStreamRecording: jest.fn(),
  deleteStreamTarget: jest.fn(),
}));
jest.mock('../../helper/branch', () => ({ link: jest.fn().mockResolvedValue({ url: 'https://branch.io/link' }) }));
jest.mock('../../helper/notification', () => ({ sendMail: jest.fn() }));

jest.mock('../../modules/notification/notificationUtils', () => ({
  sendBulkNotification: jest.fn(),
  sendNotification: jest.fn(),
}));
jest.mock('../../modules/connection/connectionUtils', () => ({
  getFollowers: jest.fn(),
}));

// Model mocks – each is a jest.fn() constructor with static methods attached below
jest.mock('../../modules/feed/feedModel');
jest.mock('../../modules/media/mediaModel');
jest.mock('../../modules/connection/connectionModel');
jest.mock('../../modules/user/userModel');
jest.mock('../../modules/device/deviceModel');
jest.mock('../../modules/feed/feedListModel');
jest.mock('../../modules/feed/feedUtils', () => ({
  updateFeedListForUser: jest.fn(),
  filterDocs: jest.fn((docs) => docs),
  deleteTempFiles: jest.fn(),
  prepareFilesForUploads: jest.fn(),
}));

jest.mock('fs', () => ({
  existsSync: jest.fn().mockReturnValue(false),
  unlink: jest.fn(),
}));

// ── Load mocked modules so we can configure them per-test ────────────────────
const Feed = require('../../modules/feed/feedModel');
const Media = require('../../modules/media/mediaModel');
const User = require('../../modules/user/userModel');
const Device = require('../../modules/device/deviceModel');
const FeedList = require('../../modules/feed/feedListModel');
const connectionUtils = require('../../modules/connection/connectionUtils');
const notificationUtils = require('../../modules/notification/notificationUtils');
const feedUtils = require('../../modules/feed/feedUtils');
const notification = require('../../helper/notification');

const feedCtr = require('../../modules/feed/feedController');

// ── Helpers ───────────────────────────────────────────────────────────────────

const FAKE_ID = '507f1f77bcf86cd799439011';

const mockRes = () => {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  res.send = jest.fn(() => res);
  return res;
};

const baseReq = (overrides = {}) => ({
  body: {},
  params: {},
  query: {},
  files: {},
  user: { _id: FAKE_ID, fullName: 'Test User' },
  t: (key) => key,
  ...overrides,
});

// Configure model constructors to return mock instances before each test
beforeEach(() => {
  jest.clearAllMocks();

  const feedInstance = { _id: FAKE_ID, user: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
  Feed.mockImplementation(() => feedInstance);
  Feed.aggregate = jest.fn();
  Feed.update = jest.fn();
  Feed.findOne = jest.fn();
  Feed.findOneAndUpdate = jest.fn();
  Feed.findOneAndRemove = jest.fn();

  const mediaInstance = { _id: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
  Media.mockImplementation(() => mediaInstance);
  Media.findOne = jest.fn();
  Media.aggregate = jest.fn();
  Media.update = jest.fn();

  User.aggregate = jest.fn();
  User.update = jest.fn();

  Device.find = jest.fn().mockResolvedValue([]);
  FeedList.aggregate = jest.fn();
});

// ─── recentStories ────────────────────────────────────────────────────────────

describe('feedCtr.recentStories()', () => {
  it('responds 200 with docs from Feed.aggregate', async () => {
    const fakeDocs = [{ _id: FAKE_ID, feedType: 'StoryImage' }];
    Feed.aggregate.mockResolvedValue(fakeDocs);

    const req = baseReq();
    const res = mockRes();
    await feedCtr.recentStories(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ docs: fakeDocs });
  });

  it('responds 500 when Feed.aggregate rejects', async () => {
    Feed.aggregate.mockRejectedValue(new Error('DB error'));

    const req = baseReq();
    const res = mockRes();
    await feedCtr.recentStories(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── removeFeed ───────────────────────────────────────────────────────────────

describe('feedCtr.removeFeed()', () => {
  it('responds 200 when the feed document is found and removed', async () => {
    Feed.findOneAndRemove.mockResolvedValue({ _id: FAKE_ID });

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.removeFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ message: 'FEED_DELETED_SUCCESS' });
  });

  it('responds 401 when no matching feed is found (null result)', async () => {
    Feed.findOneAndRemove.mockResolvedValue(null);

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.removeFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: 'FEED_NOT_FOUND' });
  });

  it('responds 500 when Feed.findOneAndRemove rejects', async () => {
    Feed.findOneAndRemove.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.removeFeed(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });

  it('calls feedUtils.updateFeedListForUser after successful removal', async () => {
    Feed.findOneAndRemove.mockResolvedValue({ _id: FAKE_ID });

    const req = baseReq({ body: { feedId: FAKE_ID } });
    await feedCtr.removeFeed(req, mockRes());

    expect(feedUtils.updateFeedListForUser).toHaveBeenCalledWith(FAKE_ID);
  });
});

// ─── addComment ───────────────────────────────────────────────────────────────

describe('feedCtr.addComment()', () => {
  it('responds 200 and triggers a notification on success', async () => {
    const fakeFeed = { _id: FAKE_ID, user: { id: FAKE_ID } };
    Feed.findOneAndUpdate.mockResolvedValue(fakeFeed);
    Device.find.mockResolvedValue([{ deviceToken: 'tok-1' }]);

    const req = baseReq({ body: { feedId: FAKE_ID, commentText: 'Nice story!' } });
    const res = mockRes();
    await feedCtr.addComment(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_COMMENT_ADDED' });
  });

  it('sends a push notification to device tokens after a comment', async () => {
    const fakeFeed = { _id: FAKE_ID, user: { id: FAKE_ID } };
    Feed.findOneAndUpdate.mockResolvedValue(fakeFeed);
    Device.find.mockResolvedValue([{ deviceToken: 'device-abc' }]);

    const req = baseReq({ body: { feedId: FAKE_ID, commentText: 'Hello!' } });
    await feedCtr.addComment(req, mockRes());

    await Promise.resolve(); // flush Device.find promise
    expect(notificationUtils.sendNotification).toHaveBeenCalledWith(
      fakeFeed.user.id,
      ['device-abc'],
      'FeedComment',
      expect.objectContaining({ feed: fakeFeed._id })
    );
  });

  it('responds 500 when Feed.findOneAndUpdate rejects', async () => {
    Feed.findOneAndUpdate.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID, commentText: 'Oops' } });
    const res = mockRes();
    await feedCtr.addComment(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── activateStory ────────────────────────────────────────────────────────────

describe('feedCtr.activateStory()', () => {
  it('responds 200 with the feedId on success', async () => {
    Feed.findOneAndUpdate.mockResolvedValue({ _id: FAKE_ID, user: FAKE_ID });

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.activateStory(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ feedId: FAKE_ID });
  });

  it('responds 500 when Feed.findOneAndUpdate rejects', async () => {
    Feed.findOneAndUpdate.mockRejectedValue(new Error('Not found'));

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.activateStory(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── hideByUser ───────────────────────────────────────────────────────────────

describe('feedCtr.hideByUser()', () => {
  it('responds 200 when feed is hidden successfully', async () => {
    Feed.update.mockResolvedValue({});
    Feed.aggregate.mockResolvedValue([{ user: FAKE_ID }]);

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.hideByUser(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_HIDE_FEED' });
  });

  it('calls feedUtils.updateFeedListForUser with the feed owner', async () => {
    Feed.update.mockResolvedValue({});
    Feed.aggregate.mockResolvedValue([{ user: 'owner-id' }]);

    const req = baseReq({ body: { feedId: FAKE_ID } });
    await feedCtr.hideByUser(req, mockRes());

    expect(feedUtils.updateFeedListForUser).toHaveBeenCalledWith('owner-id');
  });

  it('responds 500 when Feed.update rejects', async () => {
    Feed.update.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.hideByUser(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── report ───────────────────────────────────────────────────────────────────

describe('feedCtr.report()', () => {
  it('responds 200 and sends a report email on success', async () => {
    Feed.findOneAndUpdate.mockResolvedValue({ _id: FAKE_ID, user: { id: FAKE_ID } });

    const req = baseReq({ body: { feedId: FAKE_ID, reportType: 'spam' } });
    const res = mockRes();
    await feedCtr.report(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_FEED_REPORTED' });
    expect(notification.sendMail).toHaveBeenCalled();
  });

  it('includes the reporter name and feedId in the email', async () => {
    Feed.findOneAndUpdate.mockResolvedValue({ _id: FAKE_ID, user: { id: FAKE_ID } });

    const req = baseReq({ body: { feedId: FAKE_ID, reportType: 'spam' } });
    req.user.fullName = 'Alice';
    await feedCtr.report(req, mockRes());

    expect(notification.sendMail).toHaveBeenCalledWith(
      expect.any(String),
      'report-feed',
      expect.objectContaining({ name: 'Alice', feed: FAKE_ID })
    );
  });

  it('responds 500 when Feed.findOneAndUpdate rejects', async () => {
    Feed.findOneAndUpdate.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID, reportType: 'abuse' } });
    const res = mockRes();
    await feedCtr.report(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── seenBy ───────────────────────────────────────────────────────────────────

describe('feedCtr.seenBy()', () => {
  it('responds 200 with viewer docs on success', async () => {
    const fakeDocs = [{ user: { _id: FAKE_ID, fullName: 'Alice' } }];
    Feed.aggregate.mockResolvedValue(fakeDocs);

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.seenBy(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ doc: fakeDocs });
  });

  it('responds 500 when Feed.aggregate rejects', async () => {
    Feed.aggregate.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.seenBy(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── comments ─────────────────────────────────────────────────────────────────

describe('feedCtr.comments()', () => {
  it('responds 200 with comment docs on success', async () => {
    const fakeDocs = [{ comments: { commentText: 'Great!' }, users: { fullName: 'Bob' } }];
    Feed.aggregate.mockResolvedValue(fakeDocs);

    const req = baseReq({ params: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.comments(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ doc: fakeDocs });
  });

  it('responds 500 when Feed.aggregate rejects', async () => {
    Feed.aggregate.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ params: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.comments(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── feedDetail ───────────────────────────────────────────────────────────────

describe('feedCtr.feedDetail()', () => {
  it('responds 200 with the feed document on success', async () => {
    const fakeDoc = [{ _id: FAKE_ID, feedType: 'StoryImage' }];
    Feed.aggregate.mockResolvedValue(fakeDoc);

    const req = baseReq({ params: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.feedDetail(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ doc: fakeDoc });
  });

  it('responds 500 when Feed.aggregate rejects', async () => {
    Feed.aggregate.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ params: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.feedDetail(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── goLiveStartPublishing ────────────────────────────────────────────────────

describe('feedCtr.goLiveStartPublishing()', () => {
  it('responds 200 and updates the stream status to Publishing', async () => {
    Feed.update.mockResolvedValue({});

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.goLiveStartPublishing(req, res);

    expect(Feed.update).toHaveBeenCalledWith(
      { _id: FAKE_ID },
      { streamStatus: 'Publishing' }
    );
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_STREAM_STARTED' });
  });

  it('responds 500 when Feed.update rejects', async () => {
    Feed.update.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.goLiveStartPublishing(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── goLiveSendNotification ───────────────────────────────────────────────────

describe('feedCtr.goLiveSendNotification()', () => {
  it('responds 200 immediately (synchronous response before async notification)', () => {
    // The controller sends the response synchronously before the promise resolves
    connectionUtils.getFollowers.mockResolvedValue({ users: [], devices: [] });

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    feedCtr.goLiveSendNotification(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_NOTIFICATION_SENT' });
  });

  it('dispatches a bulk notification to followers', async () => {
    const fakeFollowers = {
      users: ['user-a', 'user-b'],
      devices: ['tok-a', 'tok-b'],
    };
    connectionUtils.getFollowers.mockResolvedValue(fakeFollowers);

    const req = baseReq({ body: { feedId: FAKE_ID } });
    feedCtr.goLiveSendNotification(req, mockRes());

    await Promise.resolve(); // flush promise chain
    expect(notificationUtils.sendBulkNotification).toHaveBeenCalledWith(
      fakeFollowers.users,
      fakeFollowers.devices,
      'IsLive',
      expect.objectContaining({ feed: FAKE_ID })
    );
  });
});

// ─── seen ─────────────────────────────────────────────────────────────────────

describe('feedCtr.seen()', () => {
  it('increments the existing seenBy count when the user has already viewed', async () => {
    // aggregate returns a match (user has seen it before)
    Feed.aggregate.mockResolvedValue([{ _id: FAKE_ID }]);
    Feed.update.mockResolvedValue({ nModified: 1 });

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.seen(req, res);

    expect(Feed.update).toHaveBeenCalledWith(
      expect.objectContaining({ _id: FAKE_ID, 'seenBy.user': req.user._id }),
      { $inc: { 'seenBy.$.count': 1 } }
    );
    expect(res.send).toHaveBeenCalled();
  });

  it('adds user to seenBy set when it is their first view', async () => {
    // aggregate returns empty (first view)
    Feed.aggregate.mockResolvedValue([]);
    Feed.update.mockResolvedValue({ nModified: 1 });
    Feed.findOne.mockResolvedValue({ user: FAKE_ID });

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.seen(req, res);

    expect(Feed.update).toHaveBeenCalledWith(
      { _id: FAKE_ID },
      { $addToSet: { seenBy: { user: req.user._id } } }
    );
    expect(res.send).toHaveBeenCalled();
  });

  it('responds 500 when the initial Feed.aggregate rejects', async () => {
    Feed.aggregate.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { feedId: FAKE_ID } });
    const res = mockRes();
    await feedCtr.seen(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── liveReq ──────────────────────────────────────────────────────────────────

describe('feedCtr.liveReq()', () => {
  it('responds 200 with the list of go-live requesters', async () => {
    const fakeDocs = [{ user: { _id: FAKE_ID, fullName: 'Bob' } }];
    User.aggregate.mockResolvedValue(fakeDocs);

    const req = baseReq();
    const res = mockRes();
    await feedCtr.liveReq(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ doc: fakeDocs });
  });

  it('responds 500 when User.aggregate rejects', async () => {
    User.aggregate.mockRejectedValue(new Error('DB error'));

    const req = baseReq();
    const res = mockRes();
    await feedCtr.liveReq(req, res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── newStory ─────────────────────────────────────────────────────────────────

describe('feedCtr.newStory()', () => {
  const storyReq = (overrides = {}) => baseReq({
    body: {
      feedType: 'StoryImage',
      privacyLevel: 'Public',
      caption: 'Hello world',
      ...overrides.body,
    },
    files: {
      story: {
        type: 'image/jpeg',
        path: '/tmp/story-upload.jpg',
        s3Files: {
          original: { id: 'original', url: 'https://cdn.example.com/story.jpg', duration: null },
          thumb_750x1334: { id: 'thumb_750x1334', url: 'https://cdn.example.com/thumb.jpg' },
        },
      },
    },
    ...overrides,
  });

  it('responds 200 with the feedId after saving a new story', async () => {
    const feedInstance = { _id: FAKE_ID, user: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
    Feed.mockImplementation(() => feedInstance);
    connectionUtils.getFollowers.mockResolvedValue({ users: [], devices: [] });

    const req = storyReq();
    const res = mockRes();
    feedCtr.newStory(req, res);

    await feedInstance.save(); // ensure save resolves
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ feedId: FAKE_ID });
  });

  it('builds a Public feed with no sharedWith users', async () => {
    let capturedFeedData;
    Feed.mockImplementation((data) => {
      capturedFeedData = data;
      return { _id: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
    });
    connectionUtils.getFollowers.mockResolvedValue({ users: [], devices: [] });

    const req = storyReq({ body: { feedType: 'StoryImage', privacyLevel: 'Public' } });
    feedCtr.newStory(req, mockRes());
    await Promise.resolve();

    expect(capturedFeedData.privacy.level).toBe('Public');
    expect(capturedFeedData.privacy.sharedWith).toHaveLength(0);
  });

  it('parses sharedWith CSV into individual user entries for Private stories', async () => {
    let capturedFeedData;
    Feed.mockImplementation((data) => {
      capturedFeedData = data;
      return { _id: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
    });
    connectionUtils.getFollowers.mockResolvedValue({ users: [], devices: [] });

    const req = storyReq({
      body: {
        feedType: 'StoryImage',
        privacyLevel: 'Private',
        sharedWith: 'user-a, user-b, user-c',
      },
    });
    feedCtr.newStory(req, mockRes());
    await Promise.resolve();

    expect(capturedFeedData.privacy.sharedWith).toHaveLength(3);
    expect(capturedFeedData.privacy.sharedWith[0].user).toBe('user-a');
  });
});

// ─── goLiveGetStreamId ────────────────────────────────────────────────────────

describe('feedCtr.goLiveGetStreamId()', () => {
  const liveReq = (overrides = {}) => baseReq({
    body: {
      caption: 'My stream',
      streamToYt: '0',
      streamToFb: '0',
      streamToHydroX: '1',
      yt: {},
      fb: {},
      ...overrides.body,
    },
    ...overrides,
  });

  it('responds 200 with feedId and streamId on success', async () => {
    const feedInstance = {
      _id: FAKE_ID,
      save: jest.fn().mockResolvedValue({ _id: FAKE_ID }),
    };
    Feed.mockImplementation(() => feedInstance);

    const req = liveReq();
    const res = mockRes();
    feedCtr.goLiveGetStreamId(req, res);

    await feedInstance.save();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ feedId: FAKE_ID, streamId: expect.any(String) })
    );
  });

  it('always saves with streamStatus Created', async () => {
    let capturedFeedData;
    Feed.mockImplementation((data) => {
      capturedFeedData = data;
      return { _id: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
    });

    feedCtr.goLiveGetStreamId(liveReq(), mockRes());
    await Promise.resolve();

    expect(capturedFeedData.streamStatus).toBe('Created');
    expect(capturedFeedData.feedType).toBe('LiveStream');
    expect(capturedFeedData.privacy.level).toBe('Public');
  });

  it('responds 500 when Feed.save rejects', async () => {
    Feed.mockImplementation(() => ({
      save: jest.fn().mockRejectedValue(new Error('DB error')),
    }));

    const req = liveReq();
    const res = mockRes();
    feedCtr.goLiveGetStreamId(req, res);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── flushLiveReq ─────────────────────────────────────────────────────────────

describe('feedCtr.flushLiveReq()', () => {
  it('calls User.update to clear all goLiveReq arrays', async () => {
    User.update.mockResolvedValue({});

    feedCtr.flushLiveReq();
    await Promise.resolve();

    expect(User.update).toHaveBeenCalledWith(
      {},
      { $set: { goLiveReq: [] } },
      expect.objectContaining({ multi: true })
    );
  });
});
