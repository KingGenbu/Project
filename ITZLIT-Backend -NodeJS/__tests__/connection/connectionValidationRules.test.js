'use strict';

const connectionValidator = require('../../modules/connection/connectionValidationRules');

// ─── /follow ─────────────────────────────────────────────────────────────────

describe('/follow', () => {
  let rules;
  beforeAll(() => { rules = connectionValidator.get('/follow'); });

  it('returns a rules object', () => {
    expect(rules).toBeDefined();
  });

  it('requires followee and validates it as a MongoId', () => {
    const ruleTypes = rules.followee.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidMongoId');
  });
});

// ─── /unfollow ───────────────────────────────────────────────────────────────

describe('/unfollow', () => {
  let rules;
  beforeAll(() => { rules = connectionValidator.get('/unfollow'); });

  it('returns a rules object', () => {
    expect(rules).toBeDefined();
  });

  it('requires connectionId and validates it as a MongoId', () => {
    const ruleTypes = rules.connectionId.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidMongoId');
  });
});

// ─── Unknown routes ───────────────────────────────────────────────────────────

describe('unknown routes', () => {
  it('returns undefined for an unrecognised route', () => {
    expect(connectionValidator.get('/block')).toBeUndefined();
  });

  it('returns undefined for an empty string', () => {
    expect(connectionValidator.get('')).toBeUndefined();
  });
});
