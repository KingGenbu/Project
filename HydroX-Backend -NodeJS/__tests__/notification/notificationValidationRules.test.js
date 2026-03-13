'use strict';

const validator = require('../../modules/notification/notificationValidationRules');

describe('notificationValidationRules', () => {
  it('returns a rules object for /list', () => {
    expect(validator.get('/list')).toBeDefined();
  });

  it('/list rules object exists (no required fields — listing is always allowed)', () => {
    const rules = validator.get('/list');
    expect(typeof rules).toBe('object');
  });

  it('returns undefined for unknown routes', () => {
    expect(validator.get('/unknown')).toBeUndefined();
  });

  it('returns undefined for empty string', () => {
    expect(validator.get('')).toBeUndefined();
  });
});
