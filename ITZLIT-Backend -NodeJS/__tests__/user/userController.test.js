'use strict';

// ── Mocks ─────────────────────────────────────────────────────────────────────

jest.mock('../../helper/logger', () => ({ info: jest.fn(), error: jest.fn(), warn: jest.fn() }));

jest.mock('../../helper/auth', () => ({
  generateOtp: jest.fn().mockReturnValue(123456),
  generateOtpEmail: jest.fn().mockReturnValue('uuid-email-token'),
  fbCheck: jest.fn(),
}));

jest.mock('../../helper/jwt', () => ({
  getAuthToken: jest.fn().mockReturnValue('mock-jwt-token'),
}));

jest.mock('../../helper/aws', () => ({
  getPreSignedURL: jest.fn(),
}));

jest.mock('../../helper/notification', () => ({
  sendSms: jest.fn(),
  sendMail: jest.fn(),
}));

jest.mock('jm-ez-l10n', () => ({ t: (key) => key }));

// Mock awesome-phonenumber: always returns a formatted E.164 number
jest.mock('awesome-phonenumber', () =>
  jest.fn().mockImplementation(() => ({
    getNumber: jest.fn().mockReturnValue('+15555550100'),
  }))
);

jest.mock('../../modules/user/userModel');
jest.mock('../../modules/device/deviceModel');
jest.mock('../../modules/connection/connectionModel');

const User = require('../../modules/user/userModel');
const Device = require('../../modules/device/deviceModel');
const Connection = require('../../modules/connection/connectionModel');
const auth = require('../../helper/auth');
const jwt = require('../../helper/jwt');
const awsUtils = require('../../helper/aws');
const notification = require('../../helper/notification');

const userCtr = require('../../modules/user/userController');

// ── Shared helpers ─────────────────────────────────────────────────────────────

const FAKE_ID = '507f1f77bcf86cd799439011';

const mockRes = () => {
  const res = {};
  res.status = jest.fn(() => res);
  res.json = jest.fn(() => res);
  res.send = jest.fn(() => res);
  res.writeHead = jest.fn();
  res.end = jest.fn();
  return res;
};

const baseReq = (overrides = {}) => ({
  body: {},
  params: {},
  user: { _id: FAKE_ID, fullName: 'Test User', email: 'test@example.com' },
  t: (key) => key,
  ...overrides,
});

// Reusable mock user document with a save() method
const userDoc = (fields = {}) => ({
  _id: FAKE_ID,
  email: 'test@example.com',
  fullName: 'Test User',
  phoneNumber: '+15555550100',
  verification: {
    phone: { status: false, code: null, expires: null },
    email: { status: false, code: null, expires: null },
  },
  resetPassword: {},
  save: jest.fn().mockResolvedValue({}),
  ...fields,
});

beforeEach(() => {
  jest.clearAllMocks();
  User.findOne = jest.fn();
  User.update = jest.fn().mockResolvedValue({});
  Device.update = jest.fn().mockResolvedValue({});
  Device.find = jest.fn().mockResolvedValue([]);
  Connection.mockImplementation(() => ({ save: jest.fn().mockResolvedValue({}) }));
});

// ─── me() ─────────────────────────────────────────────────────────────────────

describe('userCtr.me()', () => {
  it('responds 200 with the current user's profile fields', () => {
    const req = baseReq({
      user: {
        _id: FAKE_ID,
        email: 'alice@example.com',
        fullName: 'Alice',
        phoneNumber: '+15555550100',
        profilePic: 'https://cdn.example.com/pic.jpg',
      },
    });
    const res = mockRes();
    userCtr.me(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      _id: FAKE_ID,
      email: 'alice@example.com',
      fullName: 'Alice',
      phoneNumber: '+15555550100',
      profilePic: 'https://cdn.example.com/pic.jpg',
    });
  });

  it('does not make any database calls', () => {
    userCtr.me(baseReq(), mockRes());
    expect(User.findOne).not.toHaveBeenCalled();
  });
});

// ─── login() ──────────────────────────────────────────────────────────────────

describe('userCtr.login()', () => {
  it('responds 200 with a JWT token when credentials are correct', async () => {
    const doc = userDoc({ verification: { phone: { status: true } } });
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { email: 'test@example.com', password: 'Hello1', deviceId: FAKE_ID } });
    const res = mockRes();
    await userCtr.login(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      token: 'mock-jwt-token',
      isVerified: true,
    });
  });

  it('includes the phone verification status in the response', async () => {
    const doc = userDoc({ verification: { phone: { status: false } } });
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { email: 'test@example.com', password: 'Hello1', deviceId: FAKE_ID } });
    const res = mockRes();
    await userCtr.login(req, res);

    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ isVerified: false }));
  });

  it('responds 400 WRONG_CREDENTIALS when no user is found', async () => {
    User.findOne.mockResolvedValue(null);

    const req = baseReq({ body: { email: 'nobody@example.com', password: 'wrong', deviceId: FAKE_ID } });
    const res = mockRes();
    await userCtr.login(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'WRONG_CREDENTIALS' });
  });

  it('updates the device record with the user after successful login', async () => {
    const doc = userDoc();
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { email: 'test@example.com', password: 'Hello1', deviceId: FAKE_ID } });
    await userCtr.login(req, mockRes());

    expect(Device.update).toHaveBeenCalledWith({ _id: FAKE_ID }, { user: doc });
  });

  it('generates a JWT using the user _id', async () => {
    const doc = userDoc();
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { email: 'test@example.com', password: 'Hello1', deviceId: FAKE_ID } });
    await userCtr.login(req, mockRes());

    expect(jwt.getAuthToken).toHaveBeenCalledWith({ id: FAKE_ID });
  });
});

// ─── fbLogin() ────────────────────────────────────────────────────────────────

describe('userCtr.fbLogin()', () => {
  const fbReq = () => baseReq({
    body: {
      fbProvider: { id: 'fb-123', accessToken: 'fb-token' },
      deviceId: FAKE_ID,
    },
  });

  it('responds 200 with a token when the FB user exists and fbCheck passes', async () => {
    const doc = userDoc({ verification: { phone: { status: true } } });
    User.findOne.mockResolvedValue(doc);
    auth.fbCheck.mockResolvedValue();

    const res = mockRes();
    await userCtr.fbLogin(fbReq(), res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({
      token: 'mock-jwt-token',
      isVerified: true,
    });
  });

  it('responds 400 when fbCheck rejects even though the user exists', async () => {
    User.findOne.mockResolvedValue(userDoc());
    auth.fbCheck.mockRejectedValue('FB_ACCESS_TOKEN_EXP');

    const res = mockRes();
    await userCtr.fbLogin(fbReq(), res);

    await Promise.resolve(); // flush fbCheck promise
    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('responds 499 when no user with the given FB id is found', async () => {
    User.findOne.mockResolvedValue(null);

    const res = mockRes();
    await userCtr.fbLogin(fbReq(), res);

    expect(res.status).toHaveBeenCalledWith(499);
    expect(res.json).toHaveBeenCalledWith({ error: 'FB_LOGIN_FAILED' });
  });
});

// ─── forgetPassword() ─────────────────────────────────────────────────────────

describe('userCtr.forgetPassword()', () => {
  it('responds 200 and sends a reset email when the email is registered', async () => {
    const doc = userDoc();
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { email: 'test@example.com' } });
    const res = mockRes();
    await userCtr.forgetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'RESET_PASSWORD_INSTRUCTION' });
    expect(notification.sendMail).toHaveBeenCalledWith(
      doc.email,
      'forget-password',
      expect.objectContaining({ name: doc.fullName })
    );
  });

  it('sends a reset link that includes the userId and confirmation token', async () => {
    const doc = userDoc();
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { email: 'test@example.com' } });
    await userCtr.forgetPassword(req, mockRes());

    expect(notification.sendMail).toHaveBeenCalledWith(
      expect.any(String),
      'forget-password',
      expect.objectContaining({ link: expect.stringContaining(FAKE_ID) })
    );
  });

  it('responds 400 EMAIL_NOT_FOUND when the email is not registered', async () => {
    User.findOne.mockResolvedValue(null);

    const req = baseReq({ body: { email: 'nobody@example.com' } });
    const res = mockRes();
    await userCtr.forgetPassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'EMAIL_NOT_FOUND' });
    expect(notification.sendMail).not.toHaveBeenCalled();
  });
});

// ─── resetPassword() ──────────────────────────────────────────────────────────

describe('userCtr.resetPassword()', () => {
  it('resets the password and renders success HTML when token is valid', async () => {
    const doc = userDoc({
      resetPassword: { newPassword: 'md5hash', confirmationToken: 'tok-1', expires: new Date(Date.now() + 9999) },
    });
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ params: { userId: FAKE_ID, cToken: 'tok-1' } });
    const res = mockRes();
    await userCtr.resetPassword(req, res);

    expect(res.writeHead).toHaveBeenCalledWith(200, { 'content-type': 'text/html' });
    expect(res.end).toHaveBeenCalledWith(expect.stringContaining('MSG_PASSWORD_CHANGED'));
    expect(doc.save).toHaveBeenCalled();
  });

  it('renders an expired-link HTML page when no matching token is found', async () => {
    User.findOne.mockResolvedValue(null);

    const req = baseReq({ params: { userId: FAKE_ID, cToken: 'bad-token' } });
    const res = mockRes();
    await userCtr.resetPassword(req, res);

    expect(res.writeHead).toHaveBeenCalledWith(200, { 'content-type': 'text/html' });
    expect(res.end).toHaveBeenCalledWith(expect.stringContaining('ERR_PASSWORD_RESET_LINK_EXP'));
  });
});

// ─── verifyEmail() ────────────────────────────────────────────────────────────

describe('userCtr.verifyEmail()', () => {
  it('marks email as verified and renders success HTML when token is valid', async () => {
    const doc = userDoc();
    doc.verification.email = { status: false, code: 'valid-token', expires: new Date(Date.now() + 9999) };
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ params: { userId: FAKE_ID, vToken: 'valid-token' } });
    const res = mockRes();
    await userCtr.verifyEmail(req, res);

    expect(doc.verification.email.status).toBe(true);
    expect(doc.save).toHaveBeenCalled();
    expect(res.end).toHaveBeenCalledWith(expect.stringContaining('MSG_EMAIL_VERIFIED'));
  });

  it('renders an expired-link page when the token does not match', async () => {
    User.findOne.mockResolvedValue(null);

    const req = baseReq({ params: { userId: FAKE_ID, vToken: 'wrong-token' } });
    const res = mockRes();
    await userCtr.verifyEmail(req, res);

    expect(res.end).toHaveBeenCalledWith(expect.stringContaining('ERR_EMAIL_LINK_EXP'));
  });
});

// ─── verifyNumber() ───────────────────────────────────────────────────────────

describe('userCtr.verifyNumber()', () => {
  it('responds 200 MSG_PHONE_VERIFIED and clears the code when the OTP is correct', async () => {
    const doc = userDoc();
    doc.verification.phone = { status: false, code: '123456', expires: new Date(Date.now() + 9999) };
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ params: { vCode: '123456' } });
    const res = mockRes();
    await userCtr.verifyNumber(req, res);

    expect(doc.verification.phone.status).toBe(true);
    expect(doc.verification.phone.code).toBeNull();
    expect(doc.save).toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_PHONE_VERIFIED' });
  });

  it('responds 400 ERR_PHONE_LINK_EXP when the OTP is wrong or expired', async () => {
    User.findOne.mockResolvedValue(null);

    const req = baseReq({ params: { vCode: 'wrong' } });
    const res = mockRes();
    await userCtr.verifyNumber(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'ERR_PHONE_LINK_EXP' });
  });
});

// ─── resendOtp() ──────────────────────────────────────────────────────────────

describe('userCtr.resendOtp()', () => {
  it('responds 200 and triggers OTP resend when phone is not yet verified', async () => {
    const doc = userDoc({ verification: { phone: { status: false } } });
    // sendVerificationOtp calls User.findOne internally a second time
    User.findOne
      .mockResolvedValueOnce(doc)  // first: resendOtp lookup
      .mockResolvedValueOnce(doc); // second: sendVerificationOtp lookup

    const res = mockRes();
    await userCtr.resendOtp(baseReq(), res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_PHONE_OTP_SEND' });
  });

  it('responds 400 when phone is already verified', async () => {
    const doc = userDoc({ verification: { phone: { status: true } } });
    User.findOne.mockResolvedValue(doc);

    const res = mockRes();
    await userCtr.resendOtp(baseReq(), res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'ERR_PHONE_OTP_ALREADY_VERIFIED' });
  });

  it('responds 500 when no user document is found', async () => {
    User.findOne.mockResolvedValue(null);

    const res = mockRes();
    await userCtr.resendOtp(baseReq(), res);

    expect(res.status).toHaveBeenCalledWith(500);
  });
});

// ─── changePassword() ─────────────────────────────────────────────────────────

describe('userCtr.changePassword()', () => {
  it('responds 200 MSG_PASSWORD_CHANGED when the old password is correct', async () => {
    const doc = userDoc();
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { password: 'OldPass1', newPassword: 'NewPass1' } });
    const res = mockRes();
    await userCtr.changePassword(req, res);

    expect(doc.save).toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_PASSWORD_CHANGED' });
  });

  it('responds 400 ERR_OLD_PASSWORD_INCORRECT when findOne returns null', async () => {
    User.findOne.mockResolvedValue(null);

    const req = baseReq({ body: { password: 'wrong', newPassword: 'NewPass1' } });
    const res = mockRes();
    await userCtr.changePassword(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'ERR_OLD_PASSWORD_INCORRECT' });
  });

  it('updates the password field on the user document', async () => {
    const doc = userDoc();
    User.findOne.mockResolvedValue(doc);

    const req = baseReq({ body: { password: 'OldPass1', newPassword: 'NewPass1' } });
    await userCtr.changePassword(req, mockRes());

    // The new password should be set (as md5 hash) and saved
    expect(doc.password).toBeDefined();
    expect(doc.save).toHaveBeenCalled();
  });
});

// ─── logout() ─────────────────────────────────────────────────────────────────

describe('userCtr.logout()', () => {
  it('responds 200 MSG_LOGOUT and clears the device token', async () => {
    Device.update.mockResolvedValue({});

    const req = baseReq({ body: { deviceId: FAKE_ID } });
    const res = mockRes();
    await userCtr.logout(req, res);

    expect(Device.update).toHaveBeenCalledWith({ _id: FAKE_ID }, { deviceToken: '' });
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_LOGOUT' });
  });

  it('responds 400 when Device.update rejects', async () => {
    Device.update.mockRejectedValue(new Error('DB error'));

    const req = baseReq({ body: { deviceId: FAKE_ID } });
    const res = mockRes();
    await userCtr.logout(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

// ─── sendInvitation() ─────────────────────────────────────────────────────────

describe('userCtr.sendInvitation()', () => {
  it('responds 200 MSG_INVITATION_SENT when a phone number is provided', () => {
    const req = baseReq({ body: { phoneNumber: '+15555550199' } });
    const res = mockRes();
    userCtr.sendInvitation(req, res);

    expect(notification.sendSms).toHaveBeenCalledWith('+15555550199', 'send-invitation');
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ message: 'MSG_INVITATION_SENT' });
  });

  it('responds 200 without sending SMS when phoneNumber is empty', () => {
    const req = baseReq({ body: { phoneNumber: '' } });
    const res = mockRes();
    userCtr.sendInvitation(req, res);

    expect(notification.sendSms).not.toHaveBeenCalled();
    expect(res.status).toHaveBeenCalledWith(200);
  });
});

// ─── profilePicAWSPreSignedURL() ──────────────────────────────────────────────

describe('userCtr.profilePicAWSPreSignedURL()', () => {
  it('responds 200 with the presigned URL data on success', async () => {
    const fakeData = { preSignedUrl: 'https://s3.example.com/signed', key: 'profile-pic/abc', url: 'https://cdn/abc' };
    awsUtils.getPreSignedURL.mockResolvedValue(fakeData);

    const res = mockRes();
    await userCtr.profilePicAWSPreSignedURL(baseReq(), res);

    expect(awsUtils.getPreSignedURL).toHaveBeenCalledWith('profile-pic');
    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith(fakeData);
  });
});

// ─── updateProfile() ──────────────────────────────────────────────────────────

describe('userCtr.updateProfile()', () => {
  it('responds 200 when fullName is updated', async () => {
    User.findOne.mockResolvedValue(null); // isEmailExist: no conflict
    User.update.mockResolvedValue({});

    const req = baseReq({ body: { fullName: 'New Name' } });
    const res = mockRes();
    await userCtr.updateProfile(req, res);

    await Promise.resolve(); // flush async validations
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ msg: 'MSG_USER_PROFILE_UPDATED' });
  });

  it('includes the new fullName in the User.update call', async () => {
    User.update.mockResolvedValue({});

    const req = baseReq({ body: { fullName: 'Alice Smith' } });
    await userCtr.updateProfile(req, mockRes());

    await Promise.resolve();
    await Promise.resolve();

    expect(User.update).toHaveBeenCalledWith(
      { _id: FAKE_ID },
      expect.objectContaining({ fullName: 'Alice Smith' })
    );
  });

  it('responds 200 when email is changed and does not already exist', async () => {
    User.findOne.mockResolvedValue(null); // no conflict
    User.update.mockResolvedValue({});

    const req = baseReq({ body: { email: 'new@example.com' } });
    const res = mockRes();
    await userCtr.updateProfile(req, res);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
  });

  it('responds 400 when the new email is already taken by another user', async () => {
    // isEmailExist finds an existing user with the same email
    User.findOne.mockResolvedValue({ email: 'taken@example.com' });

    const req = baseReq({ body: { email: 'taken@example.com' } });
    const res = mockRes();
    await userCtr.updateProfile(req, res);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(400);
  });
});

// ─── create() ─────────────────────────────────────────────────────────────────

describe('userCtr.create()', () => {
  const createReq = (overrides = {}) => baseReq({
    body: {
      fullName: 'Alice',
      email: 'alice@example.com',
      phoneNumber: '+15555550100',
      password: 'Hello1',
      deviceId: FAKE_ID,
      regionCode: 'US',
      ...overrides.body,
    },
    ...overrides,
  });

  beforeEach(() => {
    User.mockImplementation(() => ({
      _id: FAKE_ID,
      save: jest.fn().mockResolvedValue({ _id: FAKE_ID }),
    }));
    // sendVerificationOtp calls User.findOne internally – return a doc that can save
    User.findOne.mockResolvedValue(userDoc());
  });

  it('responds 200 with a token when registration succeeds', async () => {
    User.findOne
      .mockResolvedValueOnce(null)   // no existing user
      .mockResolvedValue(userDoc()); // sendVerificationOtp lookup

    const res = mockRes();
    userCtr.create(createReq(), res);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith({ token: 'mock-jwt-token', isVerified: false });
  });

  it('responds 400 ERR_EMAIL_ALREADY_EXIST when email is taken', async () => {
    User.findOne.mockResolvedValue({ email: 'alice@example.com', phoneNumber: '+19999999999' });

    const res = mockRes();
    await userCtr.create(createReq(), res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'ERR_EMAIL_ALREADY_EXIST' });
  });

  it('responds 400 ERR_PHONE_ALREADY_EXIST when phone is taken', async () => {
    User.findOne.mockResolvedValue({ email: 'other@example.com', phoneNumber: '+15555550100' });

    const res = mockRes();
    await userCtr.create(createReq(), res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'ERR_PHONE_ALREADY_EXIST' });
  });

  it('responds 400 FB_ALREADY_EXIST when fbProvider.id is taken', async () => {
    User.findOne.mockResolvedValue({ email: 'other@example.com', phoneNumber: '+19999999999' });

    const req = createReq({ body: { fbProvider: { id: 'fb-123', accessToken: 'tok' } } });
    const res = mockRes();
    await userCtr.create(req, res);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ error: 'FB_ALREADY_EXIST' });
  });

  it('calls auth.fbCheck when fbProvider is present', async () => {
    User.findOne
      .mockResolvedValueOnce(null)
      .mockResolvedValue(userDoc());
    auth.fbCheck.mockResolvedValue();

    const req = createReq({ body: { fbProvider: { id: 'fb-999', accessToken: 'tok' } } });
    userCtr.create(req, mockRes());

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(auth.fbCheck).toHaveBeenCalledWith({ id: 'fb-999', accessToken: 'tok' });
  });

  it('does NOT hash the password when registering via Facebook', async () => {
    User.findOne
      .mockResolvedValueOnce(null)
      .mockResolvedValue(userDoc());
    auth.fbCheck.mockResolvedValue();

    let capturedUserData;
    User.mockImplementation((data) => {
      capturedUserData = data;
      return { _id: FAKE_ID, save: jest.fn().mockResolvedValue({ _id: FAKE_ID }) };
    });

    const req = createReq({ body: { fbProvider: { id: 'fb-999', accessToken: 'tok' } } });
    userCtr.create(req, mockRes());

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(capturedUserData).not.toHaveProperty('password');
  });
});
