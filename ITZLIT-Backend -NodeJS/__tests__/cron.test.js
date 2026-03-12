'use strict';

// ── All mocks must be set up BEFORE requiring cron.js which runs side-effects ─

let cronScheduleCallback;

jest.mock('node-cron', () => ({
  schedule: jest.fn().mockImplementation((pattern, cb) => {
    cronScheduleCallback = cb;
  }),
}));

jest.mock('../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
}));

const mockFlushLiveReq = jest.fn();
jest.mock('../modules/feed/feedController', () => ({
  flushLiveReq: mockFlushLiveReq,
}));

const mockUpdateFeedListForUser = jest.fn();
jest.mock('../modules/feed/feedUtils', () => ({
  updateFeedListForUser: mockUpdateFeedListForUser,
}));

const mockUsers = [
  { _id: '000000000000000000000001' },
  { _id: '000000000000000000000002' },
];

jest.mock('../modules/user/userModel', () => ({
  find: jest.fn().mockResolvedValue(mockUsers),
}));

// ─── Require the module AFTER mocks are in place ──────────────────────────────
// cron.js immediately calls updateFeedList() and registers a cron job
require('../modules/cron');

const cron = require('node-cron');
const User = require('../modules/user/userModel');
const feedUtils = require('../modules/feed/feedUtils');
const feedCtr = require('../modules/feed/feedController');

// ─────────────────────────────────────────────────────────────────────────────

describe('modules/cron — scheduled job', () => {
  it('registers a cron schedule with the 5am EST pattern (0 10 * * *)', () => {
    expect(cron.schedule).toHaveBeenCalledWith('0 10 * * *', expect.any(Function));
  });

  it('calls feedCtr.flushLiveReq when the cron fires', () => {
    cronScheduleCallback();
    expect(mockFlushLiveReq).toHaveBeenCalledTimes(1);
  });
});

describe('modules/cron — updateFeedList (runs on require)', () => {
  it('calls User.find to get all users', async () => {
    // Give the micro-task queue a chance to resolve
    await Promise.resolve();
    await Promise.resolve();

    expect(User.find).toHaveBeenCalledTimes(1);
  });

  it('calls feedUtils.updateFeedListForUser for every user', async () => {
    await Promise.resolve();
    await Promise.resolve();

    expect(mockUpdateFeedListForUser).toHaveBeenCalledTimes(mockUsers.length);
    expect(mockUpdateFeedListForUser).toHaveBeenCalledWith(mockUsers[0]._id);
    expect(mockUpdateFeedListForUser).toHaveBeenCalledWith(mockUsers[1]._id);
  });
});
