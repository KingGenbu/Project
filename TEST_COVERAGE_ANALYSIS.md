# Test Coverage Analysis — HydroX Project

**Date:** 2026-03-09
**Scope:** Backend (Node.js/Express) + Frontend (iOS/Swift)
**Current Coverage:** < 1% (effectively zero automated test coverage)

---

## Executive Summary

The HydroX codebase (~20,000 lines across 100+ files) has no meaningful automated tests. The Node.js backend has `"test": "echo \"Error: no test specified\" && exit 1"` in `package.json` — no test framework is even installed. The iOS targets contain two XCTest stub files with no real assertions. Every module, helper, and view controller is untested.

This document prioritises the areas most worth addressing first, ordered by risk impact.

---

## Current State

| Layer | Source Files | Lines | Test Files | Coverage |
|---|---|---|---|---|
| Backend Controllers | 6 | ~2,550 | 0 | 0% |
| Backend Helpers | 8 | ~800 | 0 | 0% |
| Backend Models | 7 | ~400 | 0 | 0% |
| Backend Utilities | 7 | ~600 | 0 | 0% |
| Backend Cron/Jobs | 2 | ~1,330 | 0 | 0% |
| iOS View Controllers | 26 | ~10,000 | 0 | 0% |
| iOS Managers | 4 | ~1,000 | 0 | 0% |
| iOS Helpers/Models | 20+ | ~4,000 | 0 | 0% |
| **Total** | **100+** | **~20,000** | **2 stubs** | **< 1%** |

---

## Priority Areas for Improvement

### Priority 1 — Authentication & Security (Highest Risk)

**Files:** `helper/auth.js` (39 lines), `helper/jwt.js` (22 lines), `middleware.js` (60 lines)

These files guard every protected API endpoint. A bug here means either locked-out users or unauthorised access to the entire system.

**What to test:**
- `auth.js`: OTP generation produces values of the correct length and character set; Facebook token verification rejects tampered tokens.
- `jwt.js`: Tokens encode the expected payload; decoding a valid token returns the original claims; an expired or tampered token throws rather than silently returning data.
- `middleware.js`: Requests without a token are rejected with 401; requests with a valid token attach the user object to `req`; requests with an expired token are rejected even if the signature is otherwise valid.

**Why first:** A single gap in auth/JWT handling can expose all user data. These are also small, pure-ish functions that are cheap to unit-test.

---

### Priority 2 — Input Validation (High Risk, High Complexity)

**File:** `helper/validate.js` (244 lines)

This is the most complex helper in the codebase. It performs recursive field validation with custom rules across many different request shapes. It is called by every controller before any business logic runs.

**What to test:**
- Required fields: missing a required field returns the correct error key.
- Type coercion / format checks: email format, phone number format, numeric ranges.
- Nested/recursive validation: objects and arrays with nested rules are validated at every level.
- Edge cases: empty strings, `null`, `undefined`, extra unexpected fields.
- Error messages: the returned error messages match the expected i18n keys from `language/`.

**Why second:** Validation bugs silently corrupt data or reject valid user input. The recursive logic makes it easy to introduce regressions. Unit tests here catch breakage faster than any integration test.

---

### Priority 3 — Feed Module (Core Product Feature)

**Files:** `modules/feed/feedController.js` (1,430 lines), `modules/feed/feedUtils.js` (~358 lines)

The feed is the largest single module and the heart of the product. It covers story creation, S3 uploads, pagination, privacy levels, likes, comments, and notification fan-out.

**What to test:**

*Unit tests (mock AWS/DB):*
- `createStory`: valid payload inserts a document and calls S3 upload; missing required fields returns a validation error; an S3 failure is handled gracefully.
- Feed pagination: correct cursor/offset logic; empty feed returns an empty list, not an error.
- Privacy filtering: private content is excluded from feeds of non-followers.
- Like/unlike: toggling a like correctly increments/decrements the count; liking twice is idempotent.

*Integration tests (test database):*
- Full create → retrieve → delete lifecycle for a story.
- Notification is dispatched to followers when a story is created.

**Why third:** This is where the most user-facing bugs will live and where regressions are hardest to spot manually.

---

### Priority 4 — User Module & Registration Flow

**Files:** `modules/user/userController.js` (471 lines), `helper/auth.js` OTP path

Registration and login are the entry point for every user. Bugs here block all new user acquisition.

**What to test:**
- Registration: duplicate email/phone returns a conflict error; weak password is rejected by validation; a well-formed request creates a user and triggers a verification OTP.
- Login: correct credentials return a JWT; wrong password returns 401 (and does not leak whether the email exists); account not yet verified is blocked.
- Profile update: fields are updated correctly; fields the user is not allowed to change (e.g., `_id`) are ignored.
- Password reset: OTP is verified before allowing a reset; an expired OTP is rejected.

---

### Priority 5 — AWS Integration Helper (External Dependency)

**File:** `helper/aws.js` (194 lines)

All media uploads go through this file. It talks to S3 (pre-signed URLs, direct uploads) and SNS (SMS). Bugs here break every file upload in the app.

**What to test (with mocked AWS SDK):**
- Pre-signed URL generation: correct bucket, key, expiry, and content-type are used.
- Upload success path: the returned URL is in the expected CloudFront format.
- Upload failure path: SDK errors are caught and surfaced as application errors, not unhandled rejections.
- SNS SMS: the correct phone number format is passed to the SDK.

**Why mock, not hit real AWS:** Tests must be deterministic and free; mocking the AWS SDK achieves this while still validating the logic around the SDK calls.

---

### Priority 6 — Connection / Follow System

**File:** `modules/connection/connectionController.js` (367 lines)

Follow/unfollow, follower counts, and blocking control what content each user can see. Bugs here silently break feed privacy.

**What to test:**
- Follow: creates a connection document; following twice is idempotent.
- Unfollow: removes the connection; unfollowing a non-followed user returns a sensible error.
- Block: blocked user cannot view the blocker's content; blocked user does not appear in follower lists.
- Follower/following counts: counts reflect actual database state after operations.

---

### Priority 7 — Notification Dispatch

**Files:** `modules/notification/notificationController.js` (153 lines), `modules/notification/notificationUtils.js` (147 lines), `helper/notification.js` (92 lines)

Three layers handle notifications: push (APN), email (SMTP), and SMS (SNS). Each channel has its own failure mode.

**What to test (mock external providers):**
- Push notification: correct device token and payload are passed to APN.
- Email: correct recipient, subject, and template variables are used.
- SMS: correct phone number format is sent to SNS.
- Partial failure: if one channel fails, the others still fire.
- Notification is stored in the database even when a channel delivery fails.

---

### Priority 8 — Cron / Background Jobs

**File:** `modules/cron.js` (672 lines)

Background jobs delete expired content, send reminders, and maintain counters. They run invisibly; failures accumulate until data inconsistency is noticed in production.

**What to test:**
- Expired story cleanup: stories past their TTL are removed; unexpired stories are untouched.
- Counter reconciliation: aggregate counts in denormalised fields match the underlying collection counts after a job run.
- Idempotency: running a job twice has the same result as running it once.

---

### Priority 9 — iOS API Manager

**File:** `ApiManager.swift` (321 lines)

Every network call in the iOS app goes through this class. Untested network layer means any change here can silently break all API interactions.

**What to test (with URLSession mock/stub):**
- Successful response: data is decoded into the correct model type.
- HTTP error codes (401, 404, 500): the correct error enum case is returned.
- Token injection: the Authorization header is present and correctly formatted on authenticated requests.
- Token refresh: a 401 triggers a token refresh before retrying the original request.
- Timeout: network timeout surfaces as a `.networkError`, not a crash.

---

### Priority 10 — iOS Input Validation & Registration

**File:** `RegistrationTableViewController.swift` (597 lines), password/email helpers

The existing `RegistrationVC.swift` test file has the right idea but the assertion logic is commented out. This is the easiest win.

**What to test:**
- Password rules: uppercase required, minimum length, special character requirement — all enforced consistently.
- Email format: invalid formats are rejected before a network call is made.
- Phone number format: country code handling, numeric-only enforcement.
- Form submission disabled until all fields are valid.

---

## Recommended Test Infrastructure Setup

### Backend (Node.js)

```bash
npm install --save-dev jest supertest @jest-mock/express mongodb-memory-server
```

Suggested `package.json` scripts:
```json
{
  "test": "jest",
  "test:watch": "jest --watch",
  "test:coverage": "jest --coverage"
}
```

File layout:
```
__tests__/
  unit/
    helpers/
      validate.test.js
      jwt.test.js
      auth.test.js
      aws.test.js
    modules/
      feed.test.js
      user.test.js
      connection.test.js
      notification.test.js
  integration/
    api/
      feed.api.test.js
      user.api.test.js
```

Use `mongodb-memory-server` for integration tests so they never touch a real database.

### iOS (XCTest / Swift)

- Write genuine unit tests in the existing `HydroXTests` target.
- Add a separate `HydroXUITests` target for UI-level flows.
- Use protocol-based dependency injection on `ApiManager` so network calls can be swapped for stubs in tests.

---

## Suggested Coverage Targets (rolling 90 days)

| Module | Month 1 | Month 2 | Month 3 |
|---|---|---|---|
| Auth / JWT / Middleware | 80% | 90% | 90% |
| Validation helper | 70% | 85% | 90% |
| Feed controller | 40% | 65% | 80% |
| User controller | 40% | 65% | 80% |
| Connection controller | 30% | 60% | 75% |
| Notification | 30% | 60% | 75% |
| AWS helper | 60% | 80% | 85% |
| Cron jobs | 20% | 50% | 70% |
| iOS ApiManager | 50% | 70% | 80% |
| iOS Registration | 60% | 80% | 90% |

---

## Quick Wins (can be done in < 1 day each)

1. **Install Jest** and write 5–10 unit tests for `helper/jwt.js` — small file, pure functions, immediate value.
2. **Uncomment and fix** the password validation assertions in `RegistrationVC.swift` — the test skeleton already exists.
3. **Write validation unit tests** for `helper/validate.js` — no mocking needed, just call the function with different inputs.
4. **Add a Jest coverage threshold** (`"coverageThreshold": { "global": { "lines": 20 } }`) to the CI pipeline so coverage cannot regress once established.
5. **Spin up a `mongodb-memory-server`** in a `jest.globalSetup.js` so integration tests can run anywhere without a real MongoDB instance.
