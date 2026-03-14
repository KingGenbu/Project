'use strict';

// Suppress l10n key lookups – just return the key as-is
jest.mock('jm-ez-l10n', () => ({ t: (key) => key }));

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

  it('returns a UUID format (8-4-4-4-12 hex groups)', () => {
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
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('resolves when Facebook returns status 200 and a matching id', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ id: 'fb-user-123' }),
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'valid-token' })
    ).resolves.toBeUndefined();
  });

  it('rejects when the returned Facebook id does not match', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ id: 'different-id' }),
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'valid-token' })
    ).rejects.toBeTruthy();
  });

  it('rejects when Facebook returns a non-200 status code', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 401,
    });

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'expired-token' })
    ).rejects.toBeTruthy();
  });

  it('rejects on network/transport error', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNREFUSED'));

    await expect(
      auth.fbCheck({ id: 'fb-user-123', accessToken: 'any-token' })
    ).rejects.toBeTruthy();
  });

  it('passes the accessToken in the fetch URL', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ id: 'fb-user-123' }),
    });

    await auth.fbCheck({ id: 'fb-user-123', accessToken: 'my-secret-token' });
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('my-secret-token')
    );
  });
});
