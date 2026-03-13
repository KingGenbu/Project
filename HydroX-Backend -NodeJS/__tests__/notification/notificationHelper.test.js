'use strict';

// ── Mock heavy deps before requiring the module under test ────────────────────

let mockTemplateRender;
jest.mock('email-templates-v2', () => {
  mockTemplateRender = jest.fn();
  const EmailTemplate = jest.fn().mockImplementation(() => ({
    render: mockTemplateRender,
  }));
  return { EmailTemplate };
});

const mockSendMail = jest.fn();
jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({ sendMail: mockSendMail })),
}));

const mockPublishSnsSMS = jest.fn();
jest.mock('../../helper/aws', () => ({
  publishSnsSMS: mockPublishSnsSMS,
}));

const mockApnSend = jest.fn();
const mockApnProvider = { send: mockApnSend };
jest.mock('apn', () => ({
  Provider: jest.fn(() => mockApnProvider),
  Notification: jest.fn().mockImplementation(() => ({
    alert: null,
    sound: null,
    topic: null,
    payload: null,
  })),
}));

jest.mock('../../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
}));

const { sendMail, sendSms, sendPush } = require('../../helper/notification');

// ─────────────────────────────────────────────────────────────────────────────

describe('helper/notification — sendMail', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders the template and calls transporter.sendMail on success', () => {
    mockTemplateRender.mockImplementation((data, cb) => {
      cb(null, { html: '<p>hi</p>', subject: 'Hello', text: 'hi' });
    });
    mockSendMail.mockImplementation((opts, cb) => cb(null, { response: 'OK' }));

    sendMail('to@example.com', 'some-template', { foo: 'bar' }, 'reply@example.com');

    expect(mockTemplateRender).toHaveBeenCalledTimes(1);
    expect(mockSendMail).toHaveBeenCalledTimes(1);

    const mailOpts = mockSendMail.mock.calls[0][0];
    expect(mailOpts.to).toBe('to@example.com');
    expect(mailOpts.replyTo).toBe('reply@example.com');
    expect(mailOpts.html).toBe('<p>hi</p>');
  });

  it('falls back to process.env.DefaultReplyTo when replyTo is omitted', () => {
    process.env.DefaultReplyTo = 'default-reply@example.com';
    mockTemplateRender.mockImplementation((data, cb) => {
      cb(null, { html: '', subject: 'S', text: 'T' });
    });
    mockSendMail.mockImplementation((opts, cb) => cb(null, { response: 'OK' }));

    sendMail('to@example.com', 'tpl', {});

    const mailOpts = mockSendMail.mock.calls[0][0];
    expect(mailOpts.replyTo).toBe('default-reply@example.com');
  });

  it('logs error when transporter.sendMail fails', () => {
    const logger = require('../../helper/logger');
    mockTemplateRender.mockImplementation((data, cb) => {
      cb(null, { html: '', subject: 'S', text: 'T' });
    });
    mockSendMail.mockImplementation((opts, cb) => cb(new Error('SMTP error'), null));

    sendMail('to@example.com', 'tpl', {}, 'r@r.com');

    expect(logger.error).toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────

describe('helper/notification — sendSms', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders template and calls aws.publishSnsSMS on success', async () => {
    mockTemplateRender.mockImplementation((data, cb) => {
      cb(null, { text: 'Your OTP is 123456', html: '', subject: '' });
    });
    mockPublishSnsSMS.mockResolvedValue('MessageId-abc');

    sendSms('+15555550100', 'otp-template', { code: '123456' });

    // drain microtask queue
    await Promise.resolve();
    await Promise.resolve();

    expect(mockPublishSnsSMS).toHaveBeenCalledWith('+15555550100', 'Your OTP is 123456');
  });

  it('logs error when template render fails', () => {
    const logger = require('../../helper/logger');
    mockTemplateRender.mockImplementation((data, cb) => {
      cb(new Error('render error'), null);
    });

    sendSms('+15555550100', 'tpl', {});

    expect(mockPublishSnsSMS).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalled();
  });

  it('logs error when publishSnsSMS rejects', async () => {
    const logger = require('../../helper/logger');
    mockTemplateRender.mockImplementation((data, cb) => {
      cb(null, { text: 'msg', html: '', subject: '' });
    });
    mockPublishSnsSMS.mockRejectedValue(new Error('SNS down'));

    sendSms('+15555550100', 'tpl', {});

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(logger.error).toHaveBeenCalled();
  });
});

// ─────────────────────────────────────────────────────────────────────────────

describe('helper/notification — sendPush', () => {
  const apn = require('apn');

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('does nothing when devices list is empty', () => {
    sendPush([], 'hello', { type: 'Follow' });
    expect(mockApnSend).not.toHaveBeenCalled();
  });

  it('does nothing when devices is null', () => {
    sendPush(null, 'hello', { type: 'Follow' });
    expect(mockApnSend).not.toHaveBeenCalled();
  });

  it('creates an APN notification and calls provider.send with device tokens', async () => {
    const fakeResponse = { sent: ['device-1'], failed: [] };
    mockApnSend.mockResolvedValue(fakeResponse);

    const logger = require('../../helper/logger');
    sendPush(['device-1', 'device-2'], 'You have a new follower!', { type: 'Follow' });

    expect(apn.Notification).toHaveBeenCalledTimes(1);
    expect(mockApnSend).toHaveBeenCalledWith(
      expect.anything(),
      ['device-1', 'device-2'],
    );

    await Promise.resolve();
    expect(logger.info).toHaveBeenCalledWith(fakeResponse.sent);
  });

  it('sets alert, sound, topic, and payload on the APN notification object', () => {
    const mockNote = { alert: null, sound: null, topic: null, payload: null };
    apn.Notification.mockImplementationOnce(() => mockNote);
    mockApnSend.mockResolvedValue({ sent: [], failed: [] });

    process.env.ApnBundleId = 'com.example.app';
    sendPush(['d1'], 'Test message', { type: 'IsLive' });

    expect(mockNote.alert).toBe('Test message');
    expect(mockNote.sound).toBe('Default');
    expect(mockNote.topic).toBe('com.example.app');
    expect(mockNote.payload).toEqual({ type: 'IsLive' });
  });
});
