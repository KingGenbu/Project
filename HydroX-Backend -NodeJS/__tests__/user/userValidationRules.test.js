'use strict';

const userValidator = require('../../modules/user/userValidationRules');

// ─── /create ─────────────────────────────────────────────────────────────────

describe('/create', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/create'); });

  it('returns a rules object', () => {
    expect(rules).toBeDefined();
  });

  it('requires fullName', () => {
    expect(rules.fullName).toBeDefined();
    expect(rules.fullName.type).toBe('notEmpty');
  });

  it('requires email and validates it as an email address', () => {
    const ruleTypes = rules.email.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isEmail');
  });

  it('requires phoneNumber and validates it as a phone number', () => {
    const ruleTypes = rules.phoneNumber.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidPhoneNumber');
  });

  it('requires deviceId and validates it as a MongoId', () => {
    const ruleTypes = rules.deviceId.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidMongoId');
  });

  it('bypasses password validation when fbProvider.id is present', () => {
    expect(rules.password.byPassWhen).toBe('fbProvider.id');
  });

  it('validates password with validPassword rule', () => {
    const ruleTypes = rules.password.rules.map((r) => r.type);
    expect(ruleTypes).toContain('validPassword');
  });

  it('marks fbProvider as optional', () => {
    expect(rules.fbProvider.isOptional).toBe(true);
  });

  it('validates fbProvider.id and fbProvider.accessToken as required children', () => {
    expect(rules.fbProvider.hasChilds).toBe(true);
    expect(rules.fbProvider.childs.id.type).toBe('notEmpty');
    expect(rules.fbProvider.childs.accessToken.type).toBe('notEmpty');
  });
});

// ─── /login ──────────────────────────────────────────────────────────────────

describe('/login', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/login'); });

  it('requires email as a valid email address', () => {
    const ruleTypes = rules.email.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isEmail');
  });

  it('requires password (notEmpty only — no strength check at login)', () => {
    const ruleTypes = rules.password.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).not.toContain('validPassword');
  });

  it('requires deviceId as a MongoId', () => {
    const ruleTypes = rules.deviceId.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidMongoId');
  });
});

// ─── /fb-login ───────────────────────────────────────────────────────────────

describe('/fb-login', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/fb-login'); });

  it('requires deviceId as a MongoId', () => {
    const ruleTypes = rules.deviceId.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidMongoId');
  });

  it('requires fbProvider with nested id and accessToken', () => {
    expect(rules.fbProvider.hasChilds).toBe(true);
    expect(rules.fbProvider.childs.id.type).toBe('notEmpty');
    expect(rules.fbProvider.childs.accessToken.type).toBe('notEmpty');
  });

  it('does NOT mark fbProvider as optional (required at fb-login)', () => {
    expect(rules.fbProvider.isOptional).toBeFalsy();
  });
});

// ─── /forget-password ────────────────────────────────────────────────────────

describe('/forget-password', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/forget-password'); });

  it('requires email as a valid email address', () => {
    const ruleTypes = rules.email.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isEmail');
  });
});

// ─── /change-password ────────────────────────────────────────────────────────

describe('/change-password', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/change-password'); });

  it('requires the current password (notEmpty only)', () => {
    const ruleTypes = rules.password.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).not.toContain('validPassword');
  });

  it('requires newPassword and enforces strength rules', () => {
    const ruleTypes = rules.newPassword.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('validPassword');
  });
});

// ─── /logout ─────────────────────────────────────────────────────────────────

describe('/logout', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/logout'); });

  it('requires deviceId as a MongoId', () => {
    const ruleTypes = rules.deviceId.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidMongoId');
  });
});

// ─── /update-profile ─────────────────────────────────────────────────────────

describe('/update-profile', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/update-profile'); });

  it('makes email optional', () => {
    expect(rules.email.isOptional).toBe(true);
  });

  it('validates email format when email is supplied', () => {
    const ruleTypes = rules.email.rules.map((r) => r.type);
    expect(ruleTypes).toContain('isEmail');
  });
});

// ─── /send-invitation ────────────────────────────────────────────────────────

describe('/send-invitation', () => {
  let rules;
  beforeAll(() => { rules = userValidator.get('/send-invitation'); });

  it('requires phoneNumber and validates it as a phone number', () => {
    const ruleTypes = rules.phoneNumber.map((r) => r.type);
    expect(ruleTypes).toContain('notEmpty');
    expect(ruleTypes).toContain('isValidPhoneNumber');
  });
});

// ─── Unknown routes ───────────────────────────────────────────────────────────

describe('unknown routes', () => {
  it('returns undefined for an unrecognised route', () => {
    expect(userValidator.get('/not-a-route')).toBeUndefined();
  });

  it('returns undefined for an empty string', () => {
    expect(userValidator.get('')).toBeUndefined();
  });
});
