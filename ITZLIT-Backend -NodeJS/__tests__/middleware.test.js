'use strict';

// ── Mocks must be declared before any require() ──────────────────────────────
jest.mock('../helper/validate', () => ({ validate: jest.fn() }));
jest.mock('../helper/jwt', () => ({ decodeAuthToken: jest.fn() }));
jest.mock('../modules/user/userModel', () => ({ findOne: jest.fn() }));
jest.mock('../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
}));

const _v = require('../helper/validate');
const jwt = require('../helper/jwt');
const User = require('../modules/user/userModel');
const middleware = require('../middleware');

// ─── Helpers ──────────────────────────────────────────────────────────────────

const mockReq = (overrides = {}) => ({
  headers: {},
  byPassRoutes: null,
  path: '/api/test',
  validations: {},
  // minimal i18n stub – returns the key itself
  t: (key) => key,
  ...overrides,
});

const mockRes = () => {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  return res;
};

// ─── reqValidator ─────────────────────────────────────────────────────────────

describe('middleware.reqValidator()', () => {
  let next;

  beforeEach(() => {
    next = jest.fn();
    _v.validate.mockReset();
  });

  it('calls next() when validation returns no errors', () => {
    _v.validate.mockReturnValue({}); // empty object = no error
    const req = mockReq();
    const res = mockRes();

    middleware.reqValidator(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
  });

  it('responds with the error status and body when validation fails', () => {
    const validationError = { statusCode: 400, field: 'email', error: 'Email is invalid' };
    _v.validate.mockReturnValue(validationError);
    const req = mockReq();
    const res = mockRes();

    middleware.reqValidator(req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(validationError);
    expect(next).not.toHaveBeenCalled();
  });

  it('does NOT call next() when validation fails', () => {
    _v.validate.mockReturnValue({ statusCode: 422, field: 'name', error: 'Required' });
    middleware.reqValidator(mockReq(), mockRes(), next);
    expect(next).not.toHaveBeenCalled();
  });
});

// ─── loadUser ─────────────────────────────────────────────────────────────────

describe('middleware.loadUser()', () => {
  let next;

  beforeEach(() => {
    next = jest.fn();
    jwt.decodeAuthToken.mockReset();
    User.findOne.mockReset();
  });

  it('responds 401 when the x-auth-token header is absent', () => {
    const req = mockReq({ headers: {} });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responds 401 when the x-auth-token header is an empty string', () => {
    const req = mockReq({ headers: { 'x-auth-token': '' } });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responds 401 when the token cannot be decoded (invalid/expired)', () => {
    jwt.decodeAuthToken.mockReturnValue(false);
    const req = mockReq({ headers: { 'x-auth-token': 'bad-token' } });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('calls next() and attaches the user to req when the token is valid and the user exists', async () => {
    const fakeUser = { _id: 'user-1', isBlocked: false, name: 'Alice' };
    jwt.decodeAuthToken.mockReturnValue({ id: 'user-1' });
    User.findOne.mockResolvedValue(fakeUser);

    const req = mockReq({ headers: { 'x-auth-token': 'valid-token' } });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    // The User.findOne promise resolves asynchronously
    await Promise.resolve();
    await Promise.resolve(); // flush promise chain

    expect(next).toHaveBeenCalledTimes(1);
    expect(req.user).toBe(fakeUser);
  });

  it('responds 401 when the user is blocked', async () => {
    const blockedUser = { _id: 'user-2', isBlocked: true };
    jwt.decodeAuthToken.mockReturnValue({ id: 'user-2' });
    User.findOne.mockResolvedValue(blockedUser);

    const req = mockReq({ headers: { 'x-auth-token': 'valid-token' } });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responds 401 when the decoded id does not match any user in the database', async () => {
    jwt.decodeAuthToken.mockReturnValue({ id: 'deleted-user' });
    User.findOne.mockResolvedValue(null); // user not found

    const req = mockReq({ headers: { 'x-auth-token': 'valid-token' } });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responds 401 when User.findOne rejects (DB error)', async () => {
    jwt.decodeAuthToken.mockReturnValue({ id: 'user-1' });
    User.findOne.mockRejectedValue(new Error('DB connection lost'));

    const req = mockReq({ headers: { 'x-auth-token': 'valid-token' } });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('bypasses auth for paths listed in byPassRoutes', () => {
    const req = mockReq({
      headers: {}, // no token
      byPassRoutes: ['/api/health', '/api/login'],
      path: '/api/health',
    });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
  });

  it('does NOT bypass auth for a path that is not in byPassRoutes', () => {
    const req = mockReq({
      headers: {}, // no token
      byPassRoutes: ['/api/health'],
      path: '/api/feed',
    });
    const res = mockRes();

    middleware.loadUser(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });
});
