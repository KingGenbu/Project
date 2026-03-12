'use strict';

// ── Mocks ─────────────────────────────────────────────────────────────────────

jest.mock('../../modules/notification/notificationModel');
jest.mock('../../modules/user/userModel');
jest.mock('../../helper/notification', () => ({
  sendPush: jest.fn(),
}));
jest.mock('../../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
}));

const Notification = require('../../modules/notification/notificationModel');
const User = require('../../modules/user/userModel');
const helperNotification = require('../../helper/notification');
const notificationUtils = require('../../modules/notification/notificationUtils');

const FAKE_USER_ID = '000000000000000000000001';
const FAKE_FEED_ID = '000000000000000000000002';
const FAKE_CONN_ID = '000000000000000000000003';

// ─── NoteType enum ────────────────────────────────────────────────────────────

describe('notificationUtils.NoteType', () => {
  it('exports expected notification type keys', () => {
    expect(notificationUtils.NoteType.Follow).toBe('Follow');
    expect(notificationUtils.NoteType.IsLive).toBe('IsLive');
    expect(notificationUtils.NoteType.ShareStory).toBe('ShareStory');
    expect(notificationUtils.NoteType.FeedComment).toBe('FeedComment');
    expect(notificationUtils.NoteType.GoLiveReq).toBe('GoLiveReq');
    expect(notificationUtils.NoteType.ItzlitDone).toBe('ItzlitDone');
  });
});

// ─── addBulkNotification ──────────────────────────────────────────────────────

describe('notificationUtils.addBulkNotification', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Notification.insertMany = jest.fn();
  });

  it('inserts a notification doc per user', async () => {
    Notification.insertMany.mockResolvedValue([]);

    await notificationUtils.addBulkNotification(
      [FAKE_USER_ID, FAKE_USER_ID + '1'],
      notificationUtils.NoteType.IsLive,
      {},
      'Someone is live now!',
    );

    expect(Notification.insertMany).toHaveBeenCalledTimes(1);
    const docs = Notification.insertMany.mock.calls[0][0];
    expect(docs).toHaveLength(2);
    expect(docs[0].message).toBe('Someone is live now!');
    expect(docs[0].notificationType).toBe(notificationUtils.NoteType.IsLive);
  });

  it('attaches feed when extras.feed is present', async () => {
    Notification.insertMany.mockResolvedValue([]);

    await notificationUtils.addBulkNotification(
      [FAKE_USER_ID],
      notificationUtils.NoteType.ShareStory,
      { feed: FAKE_FEED_ID },
      'New story!',
    );

    const docs = Notification.insertMany.mock.calls[0][0];
    expect(docs[0].feed).toBe(FAKE_FEED_ID);
  });

  it('attaches connection._id when extras.connection is present', async () => {
    Notification.insertMany.mockResolvedValue([]);
    const connection = { _id: FAKE_CONN_ID };

    await notificationUtils.addBulkNotification(
      [FAKE_USER_ID],
      notificationUtils.NoteType.Follow,
      { connection },
      'Followed',
    );

    const docs = Notification.insertMany.mock.calls[0][0];
    expect(docs[0].connection).toBe(FAKE_CONN_ID);
  });

  it('attaches goLiveReqBy when extras.userId is present', async () => {
    Notification.insertMany.mockResolvedValue([]);

    await notificationUtils.addBulkNotification(
      [FAKE_USER_ID],
      notificationUtils.NoteType.GoLiveReq,
      { userId: FAKE_USER_ID },
      'Go live req',
    );

    const docs = Notification.insertMany.mock.calls[0][0];
    expect(docs[0].goLiveReqBy).toBe(FAKE_USER_ID);
  });

  it('rejects when insertMany fails', async () => {
    Notification.insertMany.mockRejectedValue(new Error('DB error'));

    await expect(
      notificationUtils.addBulkNotification([FAKE_USER_ID], 'Follow', {}, 'msg'),
    ).rejects.toThrow('DB error');
  });
});

// ─── sendBulkNotification ─────────────────────────────────────────────────────

describe('notificationUtils.sendBulkNotification', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    User.findOne = jest.fn();
    Notification.insertMany = jest.fn().mockResolvedValue([]);
  });

  it('resolves message from User.findOne for IsLive type and calls sendPush', async () => {
    User.findOne.mockResolvedValue({ fullName: 'Alice' });

    notificationUtils.sendBulkNotification(
      [FAKE_USER_ID],
      ['device-token-1'],
      notificationUtils.NoteType.IsLive,
      { userId: FAKE_USER_ID },
    );

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(helperNotification.sendPush).toHaveBeenCalledWith(
      ['device-token-1'],
      'Alice is live now!',
      expect.objectContaining({ type: notificationUtils.NoteType.IsLive }),
    );
  });

  it('resolves ItzlitDone message without a DB lookup', async () => {
    notificationUtils.sendBulkNotification(
      [FAKE_USER_ID],
      ['device-token-1'],
      notificationUtils.NoteType.ItzlitDone,
      {},
    );

    await Promise.resolve();
    await Promise.resolve();

    expect(helperNotification.sendPush).toHaveBeenCalledWith(
      ['device-token-1'],
      'Your Live Stream is Lit! 😎',
      expect.anything(),
    );
    expect(User.findOne).not.toHaveBeenCalled();
  });
});

// ─── sendNotification (wrapper) ───────────────────────────────────────────────

describe('notificationUtils.sendNotification', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    User.findOne = jest.fn().mockResolvedValue({ fullName: 'Bob' });
    Notification.insertMany = jest.fn().mockResolvedValue([]);
  });

  it('delegates to sendBulkNotification with a single-element user array', async () => {
    notificationUtils.sendNotification(
      FAKE_USER_ID,
      ['device-1'],
      notificationUtils.NoteType.IsLive,
      { userId: FAKE_USER_ID },
    );

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(helperNotification.sendPush).toHaveBeenCalledWith(
      ['device-1'],
      expect.any(String),
      expect.anything(),
    );
  });
});
