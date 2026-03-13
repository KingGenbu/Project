'use strict';

// Mock the `request` library before loading auth.js
jest.mock('request');
// Suppress l10n key lookups – just return the key as-is
jest.mock('jm-ez-l10n', () => ({ t: (key) => key }));

const request = require('request');
const auth = require('../../helper/auth');

// ─── generateOtp ────────────────────────────────────────────────────────────

describe('auth.generateOtp()', () => {
  it('returns a number', () => {
    expect(typeof auth.generateOtp()).toBe('number');
  });

  it('is a 6-digit integer (100000–999999)', () => {
    for (let i = 0; i < 20; i++) {
      const otp = auth.generateOtp();
      expect(otp).toBeGreaterThanOrEqual(100000);
      expect(otp).toBeLessThanOrEqual(999999);
      expect(Number.isInteger(otp)).toBe(true);
    }
  });

  it('produces different values across calls (randomness check)', () => {
    const values = new Set(Array.from({ length: 20 }, () => auth.generateOtp()));
    expect(values.size).toBeGreaterThan(1);
  });
});

// ─── generateOtpEmail ───────────────────────────────────────────────────────

describe('auth.generateOtpEmail()', () => {
  it('returns a non-empty string', () => {
    const token = auth.generateOtpEmail();
    expect(typeof token).toBe('string');
    expect(token.length).toBeGreaterThan(0);
  });

  it('returns a UUID v1 format (8-4-4-4-12 hex groups)', () => {
    const uuid = auth.generateOtpEmail();
    expect(uuid).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
  });

  it('returns different values on repeated calls', () => {
    const a = auth.generateOtpEmail();
    const b = auth.generateOtpEmail();
    expect(a).not.toBe(b);
  });
});

// ─── fbCheck ────────────────────────────────────────────────────────────────

describe('auth.fbCheck()', () => {
  afterEach(() => {
    request.mockReset();
  });

  it('resolves when Facebook returns status 200 and a matching id', async () => {
    request.mockImplementation((url, cb) => {
      cb(null, { statusCode: 200 }, JSON.stringify({ id: 'fb-user-123' }));
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'valid-token' })
    ).resolves.toBeUndefined();
  });

  it('rejects when the returned Facebook id does not match', async () => {
    request.mockImplementation((url, cb) => {
      cb(null, { statusCode: 200 }, JSON.stringify({ id: 'different-id' }));
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'valid-token' })
    ).rejects.toBeTruthy();
  });

  it('rejects when Facebook returns a non-200 status code', async () => {
    request.mockImplementation((url, cb) => {
      cb(null, { statusCode: 401 }, JSON.stringify({ error: 'Invalid OAuth access token' }));
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'expired-token' })
    ).rejects.toBeTruthy();
  });

  it('rejects on network/transport error', async () => {
    request.mockImplementation((url, cb) => {
      cb(new Error('ECONNREFUSED'), null, null);
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'any-token' })
    ).rejects.toBeTruthy();
  });

  it('passes the accessToken in the request URL', async () => {
    request.mockImplementation((url, cb) => {
      cb(null, { statusCode: 200 }, JSON.stringify({ id: 'fb-user-123' }));
    });

    await auth.fbCheck({ id: 'fb-user-123', accessToken: 'my-secret-token' });
    expect(request).toHaveBeenCalledWith(
      expect.stringContaining('my-secret-token'),
      expect.any(Function)
    );
  });
});
