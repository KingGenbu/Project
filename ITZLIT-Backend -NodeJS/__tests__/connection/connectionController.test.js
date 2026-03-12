'use strict';

// ── Mocks ─────────────────────────────────────────────────────────────────────

jest.mock('../../helper/logger', () => ({ info: jest.fn(), error: jest.fn(), warn: jest.fn() }));
jest.mock('../../modules/notification/notificationUtils', () => ({ sendNotification: jest.fn() }));

jest.mock('awesome-phonenumber', () =>
  jest.fn().mockImplementation(() => ({
    isValid: jest.fn().mockReturnValue(true),
    isMobile: jest.fn().mockReturnValue(true),
    getNumber: jest.fn().mockReturnValue('+15555550100'),
  }))
);

jest.mock('../../modules/connection/connectionModel');
jest.mock('../../modules/user/userModel');
jest.mock('../../modules/device/deviceModel');

const Connection = require('../../modules/connection/connectionModel');
const User = require('../../modules/user/userModel');
const Device = require('../../modules/device/deviceModel');
const notificationUtils = require('../../modules/notification/notificationUtils');

const connectionCtr = require('../../modules/connection/connectionController');

// ── Helpers ───────────────────────────────────────────────────────────────────

const FAKE_ID = '507f1f77bcf86cd799439011';
const OTHER_ID = '507f1f77bcf86cd799439022';

const mockRes = () => {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
};

const baseReq = (overrides = {}) => ({
  body: {},
  query: {},
  user: { _id: FAKE_ID },
  t: (key) => key,
  ...overrides,
});

let connInstance;

beforeEach(() => {
  jest.clearAllMocks();

  connInstance = { _id: OTHER_ID, save: jest.fn().mockResolvedValue({}) };
  Connection.mockImplementation(() => connInstance);
  Connection.findOne = jest.fn();
  Connection.findOneAndRemove = jest.fn();
  Connection.aggregate = jest.fn().mockResolvedValue([]);
  Connection.aggregatePaginate = jest.fn();

  User.aggregate = jest.fn().mockResolvedValue([]);
  User.aggregatePaginate = jest.fn();

  Device.find = jest.fn().mockResolvedValue([]);
});

// ─── follow() ─────────────────────────────────────────────────────────────────

describe('connectionCtr.follow()', () => {
  it('responds 400 when the user tries to follow themselves', () => {
    const req = baseReq({ body: { followee: FAKE_ID } }); // same as req.user._id
    const res = mockRes();

    connectionCtr.follow(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ msg: 'ERR_FOLLOWED_YOURSELF' });
    expect(connInstance.save).not.toHaveBeenCalled();
  });

  it('responds 200 with connectionId and MSG_FOLLOWED on success', async () => {
    connInstance.save.mockResolvedValue({});
    Device.find.mockResolvedValue([]);

    const req = baseReq({ body: { followee: OTHER_ID } });
    const res = mockRes();
    connectionCtr.follow(req, res);

    await connInstance.save();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      connectionId: connInstance._id,
      msg: 'MSG_FOLLOWED',
    });
  });

  it('dispatches a follow notification after a successful follow', async () => {
    connInstance.save.mockResolvedValue({});
    Device.find.mockResolvedValue([{ deviceToken: 'tok-1' }]);

    const req = baseReq({ body: { followee: OTHER_ID } });
    connectionCtr.follow(req, mockRes());

    await connInstance.save();
    await Promise.resolve();
    await Promise.resolve();

    expect(notificationUtils.sendNotification).toHaveBeenCalledWith(
      OTHER_ID,
      ['tok-1'],
      'Follow',
      expect.objectContaining({ connection: connInstance })
    );
  });

  it('responds 200 with existing connectionId on duplicate key error (11000)', async () => {
    const dupError = Object.assign(new Error('Duplicate'), { code: 11000 });
    connInstance.save.mockRejectedValue(dupError);

    const existingConn = { _id: 'existing-conn-id' };
    Connection.findOne.mockResolvedValue(existingConn);

    const req = baseReq({ body: { followee: OTHER_ID } });
    const res = mockRes();
    connectionCtr.follow(req, res);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      connectionId: existingConn._id,
      msg: 'MSG_FOLLOWED',
    });
  });

  it('responds 500 on a non-duplicate save error', async () => {
    connInstance.save.mockRejectedValue(new Error('Generic DB error'));

    const req = baseReq({ body: { followee: OTHER_ID } });
    const res = mockRes();
    connectionCtr.follow(req, res);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(500);
  });

  it('queries Device.find with the followee's user id', async () => {
    connInstance.save.mockResolvedValue({});
    Device.find.mockResolvedValue([]);

    const req = baseReq({ body: { followee: OTHER_ID } });
    connectionCtr.follow(req, mockRes());

    await connInstance.save();
    await Promise.resolve();

    expect(Device.find).toHaveBeenCalledWith(
      expect.objectContaining({ user: OTHER_ID })
    );
  });
});

// ─── unfollow() ───────────────────────────────────────────────────────────────

describe('connectionCtr.unfollow()', () => {
  it('responds 200 MSG_UNFOLLOWED when the connection is found and removed', async () => {
    Connection.findOneAndRemove.mockResolvedValue({ _id: OTHER_ID });

    const req = baseReq({ body: { connectionId: OTHER_ID } });
    const res = mockRes();
    await connectionCtr.unfollow(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_UNFOLLOWED' });
  });

  it('responds 400 ERR_CONNECTION_NOT_FOUND when the connection does not exist', async () => {
    Connection.findOneAndRemove.mockResolvedValue(null);

    const req = baseReq({ body: { connectionId: OTHER_ID } });
    const res = mockRes();
    await connectionCtr.unfollow(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ msg: 'ERR_CONNECTION_NOT_FOUND' });
  });

  it('only removes the connection belonging to the logged-in user (follower guard)', async () => {
    Connection.findOneAndRemove.mockResolvedValue({ _id: OTHER_ID });

    const req = baseReq({ body: { connectionId: OTHER_ID } });
    await connectionCtr.unfollow(req, mockRes());

    expect(Connection.findOneAndRemove).toHaveBeenCalledWith({
      _id: OTHER_ID,
      follower: FAKE_ID,
    });
  });
});

// ─── followers() ──────────────────────────────────────────────────────────────

describe('connectionCtr.followers()', () => {
  beforeEach(() => {
    // getFollowersFollowings makes two aggregate calls then aggregatePaginate
    Connection.aggregate
      .mockResolvedValueOnce([{ followingsCount: 5 }])  // followings count
      .mockResolvedValueOnce([{ followersCount: 3 }]);  // followers count
    Connection.aggregatePaginate.mockImplementation((rules, opts, cb) => {
      cb(null, [{ _id: OTHER_ID }], 1, 1);
    });
  });

  it('responds 200 with a followers key', async () => {
    const req = baseReq({ query: {} });
    const res = mockRes();
    await connectionCtr.followers(req, res);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ followers: expect.any(Object) })
    );
  });

  it('defaults to page 1 when page is not in the query', async () => {
    const req = baseReq({ query: {} });
    connectionCtr.followers(req, mockRes());

    await Promise.resolve();
    await Promise.resolve();

    // aggregatePaginate should have been called with page 1
    expect(Connection.aggregatePaginate).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ page: 1 }),
      expect.any(Function)
    );
  });
});

// ─── followings() ─────────────────────────────────────────────────────────────

describe('connectionCtr.followings()', () => {
  beforeEach(() => {
    Connection.aggregate
      .mockResolvedValueOnce([{ followingsCount: 2 }])
      .mockResolvedValueOnce([{ followersCount: 4 }]);
    Connection.aggregatePaginate.mockImplementation((rules, opts, cb) => {
      cb(null, [{ _id: OTHER_ID }], 1, 1);
    });
  });

  it('responds 200 with a followings key', async () => {
    const req = baseReq({ query: {} });
    const res = mockRes();
    await connectionCtr.followings(req, res);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({ followings: expect.any(Object) })
    );
  });
});

// ─── itzlitUsers() ────────────────────────────────────────────────────────────

describe('connectionCtr.itzlitUsers()', () => {
  it('responds 200 with contacts annotated with their connection info', async () => {
    const matchedUser = { _id: OTHER_ID, phoneNumber: '+15555550100', fullName: 'Bob', isFollowed: false };
    User.aggregate.mockResolvedValue([matchedUser]);

    const req = baseReq({
      body: {
        contacts: [{ number: '+15555550100', name: 'Bob' }],
        regionCode: 'US',
      },
    });
    const res = mockRes();
    await connectionCtr.itzlitUsers(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    const responseBody = res.json.mock.calls[0][0];
    expect(Array.isArray(responseBody)).toBe(true);
  });

  it('annotates each contact with the matching user's connection data', async () => {
    const matchedUser = { phoneNumber: '+15555550100', fullName: 'Bob', isFollowed: true };
    User.aggregate.mockResolvedValue([matchedUser]);

    const req = baseReq({
      body: {
        contacts: [{ number: '+15555550100', name: 'Bob' }],
        regionCode: 'US',
      },
    });
    const res = mockRes();
    await connectionCtr.itzlitUsers(req, res);

    const data = res.json.mock.calls[0][0];
    expect(data[0]).toHaveProperty('connection');
    expect(data[0].connection.fullName).toBe('Bob');
  });

  it('responds 200 with empty contact list when no contacts are provided', async () => {
    User.aggregate.mockResolvedValue([]);

    const req = baseReq({ body: { contacts: [], regionCode: 'US' } });
    const res = mockRes();
    await connectionCtr.itzlitUsers(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith([]);
  });
});

// ─── search() ─────────────────────────────────────────────────────────────────

describe('connectionCtr.search()', () => {
  it('responds 200 with paginated search results', () => {
    User.aggregate.mockReturnValue('aggregateObject'); // aggregatePaginate receives this
    User.aggregatePaginate.mockImplementation((rules, opts, cb) => {
      cb(null, [{ _id: OTHER_ID, fullName: 'Alice' }], 1, 1);
    });

    const req = baseReq({ query: { q: 'Ali', page: 1 } });
    const res = mockRes();
    connectionCtr.search(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      results: expect.objectContaining({ docs: expect.any(Array) }),
    });
  });

  it('includes total, limit, page and pages in the results', () => {
    User.aggregate.mockReturnValue('aggregateObject');
    User.aggregatePaginate.mockImplementation((rules, opts, cb) => {
      cb(null, [], 3, 15);
    });

    const req = baseReq({ query: { q: 'Bob', page: 2 } });
    const res = mockRes();
    connectionCtr.search(req, res);

    const { results } = res.json.mock.calls[0][0];
    expect(results).toHaveProperty('total');
    expect(results).toHaveProperty('limit');
    expect(results).toHaveProperty('pages');
    expect(results).toHaveProperty('page');
  });
});
