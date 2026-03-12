'use strict';

// ── Mocks ─────────────────────────────────────────────────────────────────────

jest.mock('../../modules/notification/notificationModel');
jest.mock('../../helper/notification', () => ({
  sendMail: jest.fn(),
}));
jest.mock('../../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
}));
jest.mock('../../config/constants', () => ({
  pager: { limit: 10 },
}));

const Notification = require('../../modules/notification/notificationModel');
const helperNotification = require('../../helper/notification');
const notificationCtr = require('../../modules/notification/notificationController');

const FAKE_USER_ID = '000000000000000000000001';

// ─── Shared helpers ───────────────────────────────────────────────────────────

const makeReq = (overrides = {}) => ({
  user: { _id: FAKE_USER_ID },
  query: {},
  body: {},
  ...overrides,
});

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
};

// ─── notificationCtr.list ────────────────────────────────────────────────────

describe('notificationCtr.list', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    Notification.aggregate = jest.fn().mockReturnValue({});
    Notification.aggregatePaginate = jest.fn();
  });

  it('responds 200 with notificationsList on success', async () => {
    const fakeDocs = [{ _id: '1', message: 'Hi' }];
    Notification.aggregatePaginate.mockImplementation((rules, opts, cb) =>
      cb(null, fakeDocs, 3, 25),
    );

    const req = makeReq({ query: { page: '2' } });
    const res = makeRes();

    notificationCtr.list(req, res);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      notificationsList: expect.objectContaining({
        docs: fakeDocs,
        total: 25,
        pages: 3,
        page: '2',
        limit: 10,
      }),
    });
  });

  it('defaults page to 1 when not supplied', () => {
    Notification.aggregatePaginate.mockImplementation((rules, opts, cb) =>
      cb(null, [], 1, 0),
    );

    const req = makeReq({ query: {} });
    const res = makeRes();
    notificationCtr.list(req, res);

    const opts = Notification.aggregatePaginate.mock.calls[0][1];
    expect(opts.page).toBe(1);
  });

  it('logs error and does not crash when aggregatePaginate fails', async () => {
    const logger = require('../../helper/logger');
    Notification.aggregatePaginate.mockImplementation((rules, opts, cb) =>
      cb(new Error('aggregate failed'), null, null, null),
    );

    const req = makeReq();
    const res = makeRes();
    notificationCtr.list(req, res);

    await Promise.resolve();
    await Promise.resolve();

    expect(logger.error).toHaveBeenCalled();
    expect(res.status).not.toHaveBeenCalled();
  });
});

// ─── notificationCtr.contactUs ───────────────────────────────────────────────

describe('notificationCtr.contactUs', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.ContactUSAdminEmail = 'admin@example.com';
  });

  it('calls sendMail with the contact-us template and body fields', () => {
    const req = makeReq({
      body: { name: 'Alice', email: 'alice@example.com', message: 'Hello!' },
    });
    const res = makeRes();

    notificationCtr.contactUs(req, res);

    expect(helperNotification.sendMail).toHaveBeenCalledWith(
      'admin@example.com',
      'contact-us',
      { message: 'Hello!', name: 'Alice', email: 'alice@example.com' },
      'alice@example.com',
    );
  });

  it('responds with thank-you message', () => {
    const req = makeReq({
      body: { name: 'Bob', email: 'bob@example.com', message: 'Feedback' },
    });
    const res = makeRes();

    notificationCtr.contactUs(req, res);

    expect(res.send).toHaveBeenCalledWith('Thank you! Your message has been sent!');
  });
});
