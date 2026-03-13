'use strict';

// Must be set before the module is loaded so jwt-simple can sign/verify
process.env.JwtSecret = 'test-secret-key';

// Suppress logger output during tests
jest.mock('../../helper/logger', () => ({
  info: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
}));

const jwtUtil = require('../../helper/jwt');

describe('jwtUtil', () => {
  describe('getAuthToken()', () => {
    it('returns a non-empty string', () => {
      const token = jwtUtil.getAuthToken({ id: 'user-1' });
      expect(typeof token).toBe('string');
      expect(token.length).toBeGreaterThan(0);
    });

    it('produces a JWT-shaped string (three dot-separated segments)', () => {
      const token = jwtUtil.getAuthToken({ id: 'user-1' });
      expect(token.split('.')).toHaveLength(3);
    });

    it('encodes the full payload so it can be retrieved', () => {
      const payload = { id: 'user-42', role: 'admin', name: 'Alice' };
      const token = jwtUtil.getAuthToken(payload);
      const decoded = jwtUtil.decodeAuthToken(token);
      expect(decoded.id).toBe('user-42');
      expect(decoded.role).toBe('admin');
      expect(decoded.name).toBe('Alice');
    });

    it('two tokens for the same payload are identical (no timestamp)', () => {
      const payload = { id: 'user-1' };
      expect(jwtUtil.getAuthToken(payload)).toBe(jwtUtil.getAuthToken(payload));
    });
  });

  describe('decodeAuthToken()', () => {
    it('returns false for null', () => {
      expect(jwtUtil.decodeAuthToken(null)).toBe(false);
    });

    it('returns false for undefined', () => {
      expect(jwtUtil.decodeAuthToken(undefined)).toBe(false);
    });

    it('returns false for an empty string', () => {
      expect(jwtUtil.decodeAuthToken('')).toBe(false);
    });

    it('returns false for a random non-JWT string', () => {
      expect(jwtUtil.decodeAuthToken('not.a.valid.token')).toBe(false);
    });

    it('returns false for a token tampered in the signature segment', () => {
      const token = jwtUtil.getAuthToken({ id: 'user-1' });
      const parts = token.split('.');
      parts[2] = parts[2].split('').reverse().join(''); // corrupt signature
      expect(jwtUtil.decodeAuthToken(parts.join('.'))).toBe(false);
    });

    it('returns false for a token tampered in the payload segment', () => {
      const token = jwtUtil.getAuthToken({ id: 'user-1' });
      const parts = token.split('.');
      parts[1] = Buffer.from(JSON.stringify({ id: 'hacker' })).toString('base64');
      expect(jwtUtil.decodeAuthToken(parts.join('.'))).toBe(false);
    });

    it('correctly round-trips a payload', () => {
      const payload = { id: 'user-99', email: 'test@example.com' };
      const token = jwtUtil.getAuthToken(payload);
      const decoded = jwtUtil.decodeAuthToken(token);
      expect(decoded.id).toBe(payload.id);
      expect(decoded.email).toBe(payload.email);
    });
  });
});
