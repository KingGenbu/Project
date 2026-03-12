'use strict';

// Suppress l10n key lookups
jest.mock('jm-ez-l10n', () => ({ t: (key) => key }));

const { validate } = require('../../helper/validate');

/** Build a minimal express-like req object */
const req = (body = {}, files = {}) => ({ body, files });

// ─── notEmpty ───────────────────────────────────────────────────────────────

describe('notEmpty rule', () => {
  const rules = { name: [{ type: 'notEmpty' }] };

  it('passes when the field is present and non-empty', () => {
    expect(validate(req({ name: 'Alice' }), rules)).toEqual({});
  });

  it('fails when the field is an empty string', () => {
    const result = validate(req({ name: '' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('name');
    expect(result.type).toBe('notEmpty');
  });

  it('fails when the field is absent', () => {
    const result = validate(req({}), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('name');
  });

  it('includes the field name in the generated error message', () => {
    const result = validate(req({}), rules);
    expect(result.generatedError).toContain('name');
  });
});

// ─── isEmail ────────────────────────────────────────────────────────────────

describe('isEmail rule', () => {
  const rules = { email: [{ type: 'isEmail' }] };

  it('passes for a well-formed email address', () => {
    expect(validate(req({ email: 'user@example.com' }), rules)).toEqual({});
  });

  it('fails when @ is missing', () => {
    const result = validate(req({ email: 'notanemail' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('email');
  });

  it('fails for an empty string', () => {
    expect(validate(req({ email: '' }), rules).statusCode).toBe(400);
  });

  it('fails when the field is absent', () => {
    expect(validate(req({}), rules).statusCode).toBe(400);
  });
});

// ─── isInt ──────────────────────────────────────────────────────────────────

describe('isInt rule', () => {
  const rules = { count: [{ type: 'isInt' }] };

  it('passes for a JavaScript number', () => {
    expect(validate(req({ count: 42 }), rules)).toEqual({});
  });

  it('passes for 0', () => {
    expect(validate(req({ count: 0 }), rules)).toEqual({});
  });

  it('fails for a numeric string', () => {
    const result = validate(req({ count: '42' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('count');
  });

  it('fails when the field is absent', () => {
    expect(validate(req({}), rules).statusCode).toBe(400);
  });
});

// ─── isAlphanumeric ─────────────────────────────────────────────────────────

describe('isAlphanumeric rule', () => {
  const rules = { username: [{ type: 'isAlphanumeric' }] };

  it('passes for letters and digits', () => {
    expect(validate(req({ username: 'Alice123' }), rules)).toEqual({});
  });

  it('fails when the value contains special characters', () => {
    const result = validate(req({ username: 'Alice@123' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('username');
  });
});

// ─── validPassword ──────────────────────────────────────────────────────────

describe('validPassword rule', () => {
  const rules = { password: [{ type: 'validPassword' }] };

  it('passes for a password that meets all requirements (6+ chars, upper + lower)', () => {
    expect(validate(req({ password: 'Hello1' }), rules)).toEqual({});
  });

  it('fails for a password shorter than 6 characters', () => {
    const result = validate(req({ password: 'Hi1' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('password');
  });

  it('fails for a password with no uppercase letter', () => {
    expect(validate(req({ password: 'helloworld' }), rules).statusCode).toBe(400);
  });

  it('fails for a password with no lowercase letter', () => {
    expect(validate(req({ password: 'HELLOWORLD' }), rules).statusCode).toBe(400);
  });

  it('fails for an empty password', () => {
    expect(validate(req({ password: '' }), rules).statusCode).toBe(400);
  });
});

// ─── isValidMongoId ─────────────────────────────────────────────────────────

describe('isValidMongoId rule', () => {
  const rules = { id: [{ type: 'isValidMongoId' }] };

  it('passes for a 24-character hex string', () => {
    expect(validate(req({ id: '507f1f77bcf86cd799439011' }), rules)).toEqual({});
  });

  it('fails for a string that is too short', () => {
    expect(validate(req({ id: 'abc123' }), rules).statusCode).toBe(400);
  });

  it('fails for a string containing non-hex characters', () => {
    expect(validate(req({ id: 'zzzzzzzzzzzzzzzzzzzzzzzz' }), rules).statusCode).toBe(400);
  });
});

// ─── isValidUSZip ────────────────────────────────────────────────────────────

describe('isValidUSZip rule', () => {
  const rules = { zip: [{ type: 'isValidUSZip' }] };

  it('passes for a 5-digit US zip code', () => {
    expect(validate(req({ zip: '90210' }), rules)).toEqual({});
  });

  it('fails for a non-numeric string', () => {
    expect(validate(req({ zip: 'ABCDE' }), rules).statusCode).toBe(400);
  });
});

// ─── checkLength ─────────────────────────────────────────────────────────────

describe('checkLength rule', () => {
  it('passes when the string length is within [min, max]', () => {
    const rules = { bio: [{ type: 'checkLength', options: { min: 3, max: 20 } }] };
    expect(validate(req({ bio: 'Hello' }), rules)).toEqual({});
  });

  it('fails when the string is below the minimum', () => {
    const rules = { bio: [{ type: 'checkLength', options: { min: 10, max: 100 } }] };
    const result = validate(req({ bio: 'Hi' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.generatedError).toContain('bio');
  });

  it('fails when the string exceeds the maximum', () => {
    const rules = { bio: [{ type: 'checkLength', options: { min: 1, max: 5 } }] };
    expect(validate(req({ bio: 'This is way too long' }), rules).statusCode).toBe(400);
  });

  it('generated error for min+max mentions both values', () => {
    const rules = { bio: [{ type: 'checkLength', options: { min: 5, max: 20 } }] };
    const result = validate(req({ bio: 'Hi' }), rules);
    expect(result.generatedError).toContain('5');
    expect(result.generatedError).toContain('20');
  });

  it('generated error for min-only mentions the minimum', () => {
    const rules = { bio: [{ type: 'checkLength', options: { min: 8 } }] };
    const result = validate(req({ bio: 'Hi' }), rules);
    expect(result.generatedError).toContain('8');
  });

  it('generated error for max-only mentions the maximum', () => {
    const rules = { bio: [{ type: 'checkLength', options: { max: 3 } }] };
    const result = validate(req({ bio: 'Way too long' }), rules);
    expect(result.generatedError).toContain('3');
  });
});

// ─── isOptional ──────────────────────────────────────────────────────────────

describe('isOptional flag', () => {
  const rules = { bio: { isOptional: true, rules: [{ type: 'isEmail' }] } };

  it('skips validation entirely when the optional field is absent', () => {
    expect(validate(req({}), rules)).toEqual({});
  });

  it('skips validation when the optional field is an empty string', () => {
    expect(validate(req({ bio: '' }), rules)).toEqual({});
  });

  it('applies the rules when the optional field is present', () => {
    const result = validate(req({ bio: 'not-an-email' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('bio');
  });
});

// ─── Multiple rules on one field ─────────────────────────────────────────────

describe('multiple rules on a single field', () => {
  const rules = {
    username: [
      { type: 'notEmpty' },
      { type: 'checkLength', options: { min: 3, max: 20 } },
      { type: 'isAlphanumeric' },
    ],
  };

  it('passes when all rules are satisfied', () => {
    expect(validate(req({ username: 'Alice123' }), rules)).toEqual({});
  });

  it('fails on the first violated rule (empty → notEmpty)', () => {
    const result = validate(req({ username: '' }), rules);
    expect(result.field).toBe('username');
    expect(result.type).toBe('notEmpty');
  });

  it('fails on the second rule when the first passes (too short → checkLength)', () => {
    const result = validate(req({ username: 'a' }), rules);
    expect(result.field).toBe('username');
    expect(result.type).toBe('checkLength');
  });
});

// ─── Multiple fields ──────────────────────────────────────────────────────────

describe('multiple fields', () => {
  const rules = {
    email: [{ type: 'isEmail' }],
    password: [{ type: 'validPassword' }],
  };

  it('passes when all fields satisfy their rules', () => {
    expect(validate(req({ email: 'a@b.com', password: 'Hello1' }), rules)).toEqual({});
  });

  it('stops at the first failing field and returns its error', () => {
    const result = validate(req({ email: 'bad', password: 'Hello1' }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('email');
  });
});

// ─── Nested / hasChilds ───────────────────────────────────────────────────────

describe('hasChilds (nested validation)', () => {
  const rules = {
    address: {
      hasChilds: true,
      childs: {
        city: [{ type: 'notEmpty' }],
        zip: [{ type: 'isValidUSZip' }],
      },
    },
  };

  it('passes when the parent and all nested fields are valid', () => {
    expect(validate(req({ address: { city: 'Beverly Hills', zip: '90210' } }), rules)).toEqual({});
  });

  it('fails with the parent field name when the parent itself is absent', () => {
    const result = validate(req({}), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('address');
  });

  it('fails with the nested field name when a child is invalid', () => {
    const result = validate(req({ address: { city: '', zip: '90210' } }), rules);
    expect(result.statusCode).toBe(400);
    expect(result.field).toBe('city');
  });
});

// ─── Empty rules ──────────────────────────────────────────────────────────────

describe('empty validation rules', () => {
  it('returns an empty object when no rules are provided', () => {
    expect(validate(req({ name: 'test' }), {})).toEqual({});
  });
});

// ─── Custom statusCode on a rule ──────────────────────────────────────────────

describe('custom statusCode on a rule', () => {
  it('uses the rule-level statusCode in the error response', () => {
    const rules = { email: [{ type: 'isEmail', statusCode: 422 }] };
    const result = validate(req({ email: 'bad' }), rules);
    expect(result.statusCode).toBe(422);
  });
});
