'use strict';

const feedValidator = require('../../modules/feed/feedValidationRules');

// ─── feedValidationRules.get() ────────────────────────────────────────────────

describe('feedValidationRules.get()', () => {
  // ── /new-story ──────────────────────────────────────────────────────────────

  describe('/new-story', () => {
    let rules;
    beforeAll(() => { rules = feedValidator.get('/new-story'); });

    it('returns a rules object (not null/undefined)', () => {
      expect(rules).toBeDefined();
    });

    it('includes a feedType validation rule', () => {
      expect(rules).toHaveProperty('feedType');
    });

    it('validates feedType as an enum containing all four feed types', () => {
      const { aEnum } = rules.feedType.options;
      expect(aEnum).toEqual(expect.arrayContaining([
        'StoryImage', 'StoryVideo', 'LiveStream', 'LiveStreamVideo',
      ]));
    });

    it('includes a privacyLevel validation rule', () => {
      expect(rules).toHaveProperty('privacyLevel');
      const { aEnum } = rules.privacyLevel.options;
      expect(aEnum).toEqual(expect.arrayContaining(['Public', 'Private']));
    });

    it('marks caption as optional', () => {
      expect(rules.caption.isOptional).toBe(true);
    });

    it('limits caption to a maximum of 100 characters', () => {
      const captionRule = rules.caption.rules.find((r) => r.type === 'checkLength');
      expect(captionRule).toBeDefined();
      expect(captionRule.options.max).toBe(100);
    });

    it('includes a story file validation rule', () => {
      expect(rules.story).toBeDefined();
      expect(rules.story.isFile).toBe(true);
    });

    it('accepts only supported image and video MIME types for story', () => {
      const mimeRule = rules.story.rules.find((r) => r.type === 'isValidMime');
      expect(mimeRule).toBeDefined();
      expect(mimeRule.options.aEnum).toEqual(
        expect.arrayContaining(['image/jpeg', 'image/png', 'video/mp4'])
      );
    });

    it('includes a sharedWith rule that bypasses when privacyLevel is Public', () => {
      const { byPassWhen } = rules.sharedWith;
      expect(typeof byPassWhen).toBe('function');
      expect(byPassWhen({ privacyLevel: 'Public' })).toBe(true);
      expect(byPassWhen({ privacyLevel: 'Private' })).toBe(false);
    });
  });

  // ── /go-live-req ────────────────────────────────────────────────────────────

  describe('/go-live-req', () => {
    let rules;
    beforeAll(() => { rules = feedValidator.get('/go-live-req'); });

    it('returns a rules object', () => {
      expect(rules).toBeDefined();
    });

    it('requires goLiveUser and validates it as a MongoId', () => {
      const ruleTypes = rules.goLiveUser.map((r) => r.type);
      expect(ruleTypes).toContain('notEmpty');
      expect(ruleTypes).toContain('isValidMongoId');
    });
  });

  // ── /activate-story ─────────────────────────────────────────────────────────

  describe('/activate-story', () => {
    let rules;
    beforeAll(() => { rules = feedValidator.get('/activate-story'); });

    it('requires feedId as a MongoId', () => {
      const ruleTypes = rules.feedId.map((r) => r.type);
      expect(ruleTypes).toContain('notEmpty');
      expect(ruleTypes).toContain('isValidMongoId');
    });
  });

  // ── /add-comment ────────────────────────────────────────────────────────────

  describe('/add-comment', () => {
    let rules;
    beforeAll(() => { rules = feedValidator.get('/add-comment'); });

    it('requires feedId as a MongoId', () => {
      const ruleTypes = rules.feedId.map((r) => r.type);
      expect(ruleTypes).toContain('notEmpty');
      expect(ruleTypes).toContain('isValidMongoId');
    });

    it('requires commentText and limits it to 500 characters', () => {
      const lengthRule = rules.commentText.rules.find((r) => r.type === 'checkLength');
      const notEmptyRule = rules.commentText.rules.find((r) => r.type === 'notEmpty');
      expect(lengthRule).toBeDefined();
      expect(lengthRule.options.max).toBe(500);
      expect(notEmptyRule).toBeDefined();
    });
  });

  // ── Shared feedId-only routes ────────────────────────────────────────────────

  const feedIdRoutes = [
    '/seen',
    '/itzlit-up',
    '/go-live-start-publishing',
    '/go-live-send-notification',
    '/go-live-stop-publishing',
    '/hide-by-users',
  ];

  feedIdRoutes.forEach((route) => {
    describe(route, () => {
      it('requires feedId and validates it as a MongoId', () => {
        const rules = feedValidator.get(route);
        expect(rules).toBeDefined();
        const ruleTypes = rules.feedId.map((r) => r.type);
        expect(ruleTypes).toContain('notEmpty');
        expect(ruleTypes).toContain('isValidMongoId');
      });
    });
  });

  // ── Unknown routes ───────────────────────────────────────────────────────────

  describe('unknown routes', () => {
    it('returns undefined for an unrecognised route', () => {
      expect(feedValidator.get('/unknown-route')).toBeUndefined();
    });

    it('returns undefined for an empty string', () => {
      expect(feedValidator.get('')).toBeUndefined();
    });
  });
});
