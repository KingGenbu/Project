# HydroX App — Full Modernization & Architecture Analysis

> **Date:** March 14, 2026
> **Application:** HydroX — Social Media App with Live Streaming
> **Components:** Node.js/Express Backend + iOS (Swift/UIKit) Frontend
> **Analysis Scope:** Architecture, code quality, security, deprecated APIs, modernization opportunities

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Overview](#project-overview)
3. [Backend (Node.js) Analysis](#backend-nodejs-analysis)
   - [Architecture & Module Structure](#1-architecture--module-structure)
   - [Deprecated Dependencies](#2-deprecated-dependencies)
   - [Deprecated Node.js/JavaScript Patterns](#3-deprecated-nodejsjavascript-patterns)
   - [Outdated Code Patterns](#4-outdated-code-patterns)
   - [Security Analysis](#5-security-analysis)
   - [Database & Query Concerns](#6-database--query-concerns)
   - [Real-time / WebSocket Implementation](#7-real-time--websocket-implementation)
   - [Error Handling & Logging](#8-error-handling--logging)
   - [Build, Config & Testing](#9-build-config--testing)
   - [Environment Variables Reference](#10-environment-variables-reference)
   - [External Service Integrations](#11-external-service-integrations)
4. [Frontend (iOS) Analysis](#frontend-ios-analysis)
   - [Architecture & Code Organization](#12-architecture--code-organization)
   - [Outdated CocoaPods](#13-outdated-cocoapods)
   - [Deprecated Swift/iOS APIs](#14-deprecated-swiftios-apis)
   - [Unsafe Code Patterns](#15-unsafe-code-patterns)
   - [Memory Management Issues](#16-memory-management-issues)
   - [Missing Modern iOS Features](#17-missing-modern-ios-features)
   - [Networking Layer](#18-networking-layer)
   - [Data Persistence](#19-data-persistence)
   - [Authentication Flows](#20-authentication-flows)
   - [UI Patterns & Storyboards](#21-ui-patterns--storyboards)
   - [Accessibility & Localization](#22-accessibility--localization)
   - [Testing](#23-testing)
   - [Debug & Hardcoded Values](#24-debug--hardcoded-values)
5. [Existing TODOs in Codebase](#25-existing-todos-in-codebase)
6. [Quantitative Summary](#quantitative-summary)
7. [Prioritized Modernization Roadmap](#prioritized-modernization-roadmap)

---

## Executive Summary

The HydroX application has significant technical debt across both its Node.js backend and iOS frontend. This analysis is based on a file-by-file review of every source file in both codebases.

### Key Findings

| Area | Finding |
|------|---------|
| **Backend LOC** | ~9,086 lines across 22 source files + 18 test files (~4,500 test lines) |
| **iOS LOC** | ~15,273 lines across 75 Swift files (×2 for Staging + Production copies) |
| **Force casts (`as!`)** | **474 occurrences** across iOS codebase — major crash risk |
| **Debug `print()` statements** | **404 occurrences** left in iOS production code |
| **`DispatchQueue.main.async`** | **126 occurrences** — should use `@MainActor` |
| **`@objc` annotations** | **158 occurrences** — Obj-C bridging overhead |
| **Backend deprecated deps** | 12 npm packages deprecated or critically outdated |
| **iOS deprecated APIs** | 10+ deprecated API patterns across both build targets |
| **Security gaps** | No rate limiting, no CSRF, synchronous bcrypt, public-read S3 ACL |
| **Test coverage** | Backend: ~40-50% estimated (4,500 test lines) · iOS: minimal (3 test files, 429 lines) |
| **CI/CD** | None configured for either platform |
| **Modern Swift adoption** | Zero usage of async/await, Combine, SwiftUI, @MainActor, or Codable |

---

## Project Overview

### Repository Structure
```
Project/
├── HydroX-Backend -NodeJS/          # Express.js API server
│   ├── server.js                     # Entry point (119 lines)
│   ├── route.js                      # API v1 routing (16 lines)
│   ├── middleware.js                  # Auth & validation (58 lines)
│   ├── config/                       # DB config, constants
│   ├── helper/                       # Auth, AWS, JWT, email, Wowza, validation
│   ├── modules/                      # Feature modules (user, feed, connection, etc.)
│   └── __tests__/                    # Jest test suites (18 files)
│
└── HydroX - Front End - iOS/
    ├── Staging - Version 0.1 & Build 27/   # Active development target
    └── Production - Version 1.0.1 & Build 1/ # Production release
        └── HydroX/
            ├── HydroX.xcworkspace     # CocoaPods workspace
            ├── Podfile                # Dependency management
            └── HydroX/
                ├── Constants/         # 4 files — IDs, messages, fonts, keys
                ├── Custom Views/      # @IBDesignable components + XIBs
                ├── Extensions/        # 6 files — Date, UIColor, UIView, etc.
                ├── Helpers/           # 7 files — Config, DB, Keychain, UserDefaults
                ├── Managers/          # 3 files — API, Socket.IO, Contacts
                ├── Model/             # 10 files — Feed, Profile, Notifications, etc.
                ├── Resources/         # Camera library, Wowza SDK, assets
                ├── Storyboards/       # 6 storyboards + 3 XIBs
                ├── Supporting Files/  # AppDelegate, SceneDelegate, configs
                ├── View Controllers/  # 25+ controllers in feature folders
                └── Views/             # Cell definitions (Feed, Comment, Notification)
```

### Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Backend Runtime** | Node.js | Not specified in package.json |
| **Backend Framework** | Express.js | 4.21.2 |
| **Database** | MongoDB (Mongoose) | 5.13.22 |
| **Real-time** | Socket.IO | 4.8.1 |
| **iOS Language** | Swift | 5.x |
| **iOS UI Framework** | UIKit (100%) | — |
| **iOS Deployment Target** | iOS 16.0 | — |
| **iOS Networking** | Alamofire | 4.9 |
| **Live Streaming** | Wowza GoCoder SDK | — |
| **Push Notifications** | APN (backend) + Firebase (iOS) | — |

---

## Backend (Node.js) Analysis

**Base Path:** `HydroX-Backend -NodeJS/`
**Total Source Lines:** ~9,086
**Total Test Lines:** ~4,500

### 1. Architecture & Module Structure

The backend follows a modular **MVC pattern** with 7 feature modules:

| Module | Model | Controller | Route | Validation | Utils | Total Lines |
|--------|-------|-----------|-------|-----------|-------|-------------|
| **feed** | 116 | 1,425 | 94 | 99 | 357 | 1,739 |
| **user** | 72 | 463 | 37 | 101 | — | 572 |
| **connection** | 27 | 368 | 35 | 21 | 56 | 424 |
| **notification** | 32 | 153 | 26 | 12 | 147 | 332 |
| **device** | 52 | 133 | 28 | 36 | — | 193 |
| **media** | 32 | — | — | — | — | 32 |
| **static** | — | 25 | 11 | — | 23 | 59 |

**Helpers** (~900 lines): `auth.js` (32), `aws.js` (184), `branch.js` (18), `jwt.js` (22), `logger.js` (25), `notification.js` (92), `validate.js` (244), `wowza.js` (132)

**API Endpoints:** ~45 total (6 public, 39 authenticated)

```
/api/v1/user          → 14 endpoints (registration, login, profile, OTP)
/api/v1/device        → 4 endpoints  (device registration, push prefs)
/api/v1/connection    → 6+ endpoints (follow, unfollow, search, followers)
/api/v1/feed          → 22 endpoints (stories, live streams, comments, reactions)
/api/v1/notification  → 2 endpoints  (list, contact-us)
/api/v1/static        → 2 endpoints  (privacy, terms)
```

---

### 2. Deprecated Dependencies

#### CRITICAL: Must Replace

| Package | Current | Status | Replacement | Files Affected |
|---------|---------|--------|-------------|----------------|
| `aws-sdk` | v2.1692.0 | Deprecated (maintenance mode) | `@aws-sdk/*` v3 (modular) | `helper/aws.js` |
| `moment` | v2.30.1 | Maintenance-only | `date-fns` or `Day.js` | `helper/logger.js`, `modules/feed/feedController.js` |
| `jwt-simple` | v0.5.6 | Outdated, no algorithm enforcement | `jsonwebtoken` or `jose` | `helper/jwt.js` |
| `mongoose` | v5.13.22 | EOL — 2 major versions behind | Mongoose v7+ or v8 | `config/database.js`, all modules |
| `connect-multiparty` | v2.2.0 | Legacy, limited security | `multer` | `modules/feed/feedRoute.js` |

#### HIGH: Should Replace

| Package | Current | Status | Replacement | Files Affected |
|---------|---------|--------|-------------|----------------|
| `email-templates-v2` | v2.0.3 | Outdated fork | `mjml` or `nodemailer-express-handlebars` | `helper/notification.js` |
| `nodemailer-smtp-transport` | v2.7.4 | Deprecated | Built-in nodemailer SMTP transport | `helper/notification.js` |
| `apn` | v2.2.0 | Deprecated | `@parse/node-apn` or Firebase Admin SDK | `helper/notification.js` |
| `node-branch-io` | v2.0.0 | Minimal maintenance | Branch REST API directly | `helper/branch.js` |
| `password-generator` | v2.3.2 | Minimal maintenance | `crypto.randomBytes()` | `modules/user/userController.js` |

#### Detailed Locations

**aws-sdk v2:**
```
helper/aws.js:2 → const aws = require('aws-sdk');
helper/aws.js:7-17 → S3 and SNS client initialization
helper/aws.js:28-45 → getPreSignedURL() with callback pattern
helper/aws.js:70-86 → publishSnsSMS() with callback
helper/aws.js:117-132 → putObject() with callback
helper/aws.js:178-189 → downloadObject() with callback
```

**moment.js:**
```
helper/logger.js:3,15 → moment().format('YYYY-MM-DD hh:mm:ss')
modules/feed/feedController.js:3 → require('moment')
modules/feed/feedController.js:76 → moment().add(constants.story.expirationDays, 'days')
modules/feed/feedController.js:515 → moment() usage
modules/feed/feedController.js:738 → moment() usage
```

**Mongoose v5 deprecated connection options:**
```
config/database.js:5 → useNewUrlParser: true     (no-op in v6+)
config/database.js:6 → useUnifiedTopology: true   (no-op in v6+)
config/database.js:7 → useCreateIndex: true        (no-op in v6+)
config/database.js:8 → useFindAndModify: false     (no-op in v6+)
```

---

### 3. Deprecated Node.js/JavaScript Patterns

#### 3.1 Synchronous Bcrypt — Event Loop Blocking

```
modules/user/userController.js:119 → bcrypt.hashSync(password, BCRYPT_ROUNDS)
modules/user/userController.js:181 → bcrypt.compareSync(password, user.password)
modules/user/userController.js:242 → bcrypt.hashSync(randomPassword, BCRYPT_ROUNDS)
modules/user/userController.js:356 → bcrypt.compareSync(password, user.password)
```
**Impact:** Blocks the event loop for ~200-500ms per call with 12 rounds.
**Fix:** Use `bcrypt.hash()` and `bcrypt.compare()` async variants.

#### 3.2 Callback-based AWS SDK Calls

```
helper/aws.js:28-45 → s3.getSignedUrl('putObject', {...}, (err, url) => {...})
helper/aws.js:70-86 → sns.publish({...}, (err, data) => {...})
helper/aws.js:117-132 → s3.putObject({...}, (err, data) => {...})
helper/aws.js:178-189 → s3.getObject({...}, (err, data) => {...})
```
**Fix:** Migrate to AWS SDK v3 with native async/await support.

#### 3.3 Callback-based Email Sending

```
helper/notification.js:33-51 → template.render(data, (err, result) => {...})
helper/notification.js:44-50 → transporter.sendMail(mailOptions, (mailSendErr, info) => {...})
```
**Fix:** Nodemailer v6+ supports `await transporter.sendMail(options)`.

#### 3.4 Mongoose `.remove()` — Deprecated

```
modules/feed/feedUtils.js:210 → FeedList.find({user: userId}).remove()
```
**Fix:** Replace with `.deleteMany()` or `.deleteOne()`.

#### 3.5 `.indexOf() !== -1` Instead of `.includes()`

```
helper/validate.js:84 → aEnum.indexOf(str) !== -1
modules/feed/feedRoute.js:45 → constants.supportedMime.image.indexOf(file.type) === -1
modules/feed/feedRoute.js:47 → constants.supportedMime.video.indexOf(file.type) === -1
modules/feed/feedUtils.js:19 → Video type check with indexOf
modules/feed/feedUtils.js:101 → Video type check with indexOf
```
**Fix:** Replace with `.includes()`.

---

### 4. Outdated Code Patterns

#### 4.1 CommonJS `require()` Instead of ES Modules

All 22+ backend files use `require()`:
```
server.js:2-22 → const express = require('express'); etc.
```
**Fix:** Migrate to `import/export` syntax with `"type": "module"` in package.json.

#### 4.2 Promise Chains Instead of async/await

Pervasive throughout — every controller uses `.then().catch()`:
```
modules/feed/feedController.js:80-97 → .then().catch() chains
modules/feed/feedController.js:145-453 → Multiple nested .then() chains
modules/user/userController.js → Extensive promise chains
modules/connection/connectionController.js → Promise chains throughout
```
**Fix:** Refactor all controllers to `async/await` with try-catch.

#### 4.3 Mixed Response Patterns

```
modules/user/userController.js:272-276 → res.writeHead(200, {'Content-Type': 'text/html'}) + res.end()
modules/user/userController.js:297-300 → Same HTML response pattern
All other endpoints → res.status().json({})
```
**Fix:** Standardize on `res.status().json()` or use a template engine for HTML pages.

#### 4.4 Bug: `reject.error()` in staticUtils.js

```
modules/static/staticUtils.js:17 → reject.error() (should be reject(error))
```

---

### 5. Security Analysis

#### Strengths
- Bcrypt password hashing with 12 rounds (strong, but synchronous)
- JWT token-based authentication with middleware enforcement
- Helmet.js security headers enabled
- CORS configured with dynamic origin validation
- Input validation framework (`helper/validate.js` — 244 lines)
- Unique MongoDB indexes on email and connection pairs
- Keychain storage on iOS (good implementation)

#### Vulnerabilities & Concerns

| Issue | Location | Severity | Fix |
|-------|----------|----------|-----|
| No rate limiting | `server.js` | **CRITICAL** | Add `express-rate-limit` |
| No CSRF protection | `server.js` | **HIGH** | Add CSRF tokens for state-changing requests |
| Synchronous bcrypt | `userController.js:119,181,242,356` | **HIGH** | Switch to async `bcrypt.hash()` / `bcrypt.compare()` |
| S3 public-read ACL | `aws.js:33,112` | **HIGH** | Use signed URLs for private content |
| JWT algorithm not enforced | `jwt.js` | **HIGH** | Use `jsonwebtoken` with explicit algorithm (e.g., HS256) |
| No input sanitization | `server.js` | **HIGH** | Add `express-validator` or `helmet-csp` |
| 50MB body limit | `server.js:38-39` | **MEDIUM** | Reduce for non-upload endpoints |
| No file virus scanning | `feedRoute.js` | **MEDIUM** | Add ClamAV or cloud-based scanning |
| Error objects exposed | Multiple controllers | **MEDIUM** | Sanitize error responses |
| Plain-text reset token | `userController.js:245-250` | **MEDIUM** | Hash reset tokens before storage |
| Hardcoded phone in test | `userController.js:21` | **LOW** | Remove test code |
| Sample secret in repo | `sample.env:15` | **LOW** | Remove example secret value |

---

### 6. Database & Query Concerns

#### Complex Aggregation Pipelines
- `feedController.js` contains a 25+ stage aggregation pipeline (lines 103-338) for the main feed
- Multiple `$lookup`, `$filter`, `$map`, `$project` stages
- Performance degrades with scale without proper indexes

#### Missing Indexes (Performance Risk)
- No index on `feed.user` for user-specific queries
- No index on `feed.storyExpiration` for expiration-based filtering
- No index on `feed.feedType` for type-filtered queries
- No compound index on `notification.user + createdAt` for sorted queries

#### N+1 Query Patterns
- `connectionController.js`: Separate lookups that could use `$lookup` aggregation
- `notificationUtils.js`: Sequential user data fetches

#### Denormalized Data
- `feedListModel.js` stores pre-aggregated feeds per user (stories + liveStreams arrays)
- Updated by cron job on startup and by `feedUtils.updateFeedListForUser()`
- Risk of stale data if updates fail silently

---

### 7. Real-time / WebSocket Implementation

**Socket.IO v4** configured in `server.js:56-115`:

| Event | Direction | Purpose |
|-------|-----------|---------|
| `onFeedJoin` | Client → Server | Join a feed's viewer room |
| `onFeedUnjoin` | Client → Server | Leave a feed's viewer room |
| `liveFeedCount` | Server → Client | Broadcast viewer count to room |
| `disconnect` | System | Cleanup on connection loss |

**Not Implemented:**
- No live comment broadcasting
- No live viewer list
- No real-time reaction notifications (hydroxUp)
- No typing indicators
- No presence system

---

### 8. Error Handling & Logging

#### Error Handling Patterns
- **Pattern 1:** Promise chains with `logger.error(err)` — doesn't always return error to client
- **Pattern 2:** Raw error objects in responses: `res.status(400).json({ error: err })`
- **Pattern 3:** i18n translation keys: `res.status(401).json({ error: req.t('UNAUTH') })`
- **Missing:** No `try-catch` blocks (no async/await usage), no global error handler

#### Logging
- **Framework:** Winston (console transport only)
- **Format:** `YYYY-MM-DD hh:mm:ss [level] message`
- **Issues:**
  - No file logging or log rotation
  - No structured logging (JSON format)
  - No request correlation IDs
  - No debug-level logging
  - Sensitive data may leak into logs

---

### 9. Build, Config & Testing

#### ESLint Configuration (`.eslintrc.json`)
- Base: `airbnb-base` (older config format)
- `no-var`: warning only (should be error)
- Many rules set to warning instead of error
- **Fix:** Upgrade to ESLint v9+ flat config, enforce strict rules

#### Jest Configuration (`jest.config.js`)
- Test environment: `node`
- Coverage threshold: 20% lines (low)
- 18 test files with ~4,500 lines of test code
- Coverage areas: helpers, middleware, all modules

#### Test Files (18 total)
```
__tests__/connection/connectionController.test.js   (361 lines)
__tests__/connection/connectionUtils.test.js         (119 lines)
__tests__/connection/connectionValidationRules.test.js (49 lines)
__tests__/feed/feedController.test.js                (695 lines)
__tests__/feed/feedUtils.test.js                     (229 lines)
__tests__/feed/feedValidationRules.test.js            (151 lines)
__tests__/user/userController.test.js                (687 lines)
__tests__/user/userValidationRules.test.js            (190 lines)
__tests__/notification/notificationController.test.js (140 lines)
__tests__/notification/notificationHelper.test.js     (193 lines)
__tests__/notification/notificationUtils.test.js      (191 lines)
__tests__/notification/notificationValidationRules.test.js (22 lines)
__tests__/helpers/auth.test.js                       (114 lines)
__tests__/helpers/aws.test.js                        (220 lines)
__tests__/helpers/jwt.test.js                        (82 lines)
__tests__/helpers/validate.test.js                   (316 lines)
__tests__/middleware.test.js                         (214 lines)
__tests__/cron.test.js                               (76 lines)
```

#### Missing
- No CI/CD pipeline (no GitHub Actions, GitLab CI, etc.)
- No TypeScript
- No Node.js version pinned in `package.json` (no `engines` field)
- No `.nvmrc` or `.node-version` file
- No API documentation generation (Swagger exists but needs verification)
- No Docker configuration

---

### 10. Environment Variables Reference

The backend requires **43+ environment variables** across 9 categories:

| Category | Variables | Count |
|----------|----------|-------|
| **Server** | PORT, RootUrl, DeepLinkRoot, CORS_ALLOWED_ORIGINS | 4 |
| **Database** | DB_URL | 1 |
| **JWT** | JwtSecret | 1 |
| **AWS** | AwsAccessKey, AwsSecretAccessKey, AwsRegion, AwsS3Bucket, AwsS3BucketLiveStream, AwsCloudFront, PreSignedUrlExpiration, SnsAwsRegion | 8 |
| **SMTP** | SmtpHost, SmtpPort, SmtpUsername, SmtpPassword, DefaultFrom, DefaultReplyTo | 6 |
| **APN** | ApnP8, ApnKeyId, ApnTeamId, ApnBundleId, ApnPushEnv | 5 |
| **Wowza** | WowzaProtocol, WowzaHost, WowzaPort, WowzaApiPort, WowzaUsername, WowzaPassword, WowzaApp | 7 |
| **Branch.io** | BranchKey | 1 |
| **App Config** | DefaultFollowings, SendOtp, ContactUSAdminEmail | 3 |

**Issue:** No environment variable validation at startup — missing vars cause runtime errors.

---

### 11. External Service Integrations

| Service | Purpose | Integration File |
|---------|---------|-----------------|
| **AWS S3** | Media file storage (profiles, stories) | `helper/aws.js` |
| **AWS CloudFront** | CDN for media delivery | `helper/aws.js` |
| **AWS SNS** | SMS delivery (OTP, invitations) | `helper/aws.js` |
| **Wowza Streaming Engine** | RTMP live stream management | `helper/wowza.js` |
| **Facebook Graph API** | Social login verification | `helper/auth.js` |
| **YouTube Data API v3** | Live stream creation/management | `modules/feed/feedController.js` |
| **Branch.io** | Deep linking | `helper/branch.js` |
| **SMTP (configurable)** | Email delivery | `helper/notification.js` |
| **Apple Push Notification** | iOS push notifications | `helper/notification.js` |

---

## Frontend (iOS) Analysis

**Base Path:** `HydroX - Front End - iOS/`
**Active Development:** Staging (v0.1 Build 27)
**Production Release:** v1.0.1 Build 1
**Deployment Target:** iOS 16.0
**Total Swift Files:** 75 per build target (×2 = 150 total)
**Total Lines of Code:** ~15,273 per target

---

### 12. Architecture & Code Organization

**Pattern:** Classic **MVC** (Model-View-Controller) with feature-based folder organization.

#### File Inventory by Category

| Category | Files | Total Lines | Key Files |
|----------|-------|-------------|-----------|
| **View Controllers** | 30 | ~9,400 | FeedViewController (1,249), GoLiveVC (953), ProfileTableVC (686) |
| **Models** | 10 | 922 | ItFeedList (177), FeedDetails (153), RecentStoryModel (127) |
| **Helpers** | 7 | 618 | Helper (382), DBManager (294), UserDefaultHelper (140) |
| **Managers** | 3 | 641 | ApiManager (228), ContactManager (267), ILSocketManager (146) |
| **Extensions** | 6 | 292 | Date (78), UIView (55), NBTextField (83) |
| **Resources/Libs** | 7 | 2,139 | SwiftyCamViewController (1,252), RPCircularProgress (457) |
| **Views/Cells** | 8 | ~600 | FeedCell (387), NotificationCell, ContactCell |
| **Supporting** | 4 | 479 | AppDelegate (391), SceneDelegate (42) |

#### Largest Files (Refactoring Candidates)

| File | Lines | Responsibilities |
|------|-------|-----------------|
| `SwiftyCamViewController.swift` | **1,252** | Camera capture, AVFoundation, recording, photo/video output |
| `FeedViewController.swift` | **1,249** | Table view, pagination, networking, socket.io, pull-to-refresh, empty state |
| `GoLiveVC.swift` | **953** | Wowza SDK, multi-platform streaming, filters, timer, socket.io |
| `ProfileTableViewController.swift` | **686** | Profile display, followers, stories, edit, follow/unfollow |
| `RegistrationTableViewController.swift` | **589** | Registration form, validation, API calls, Facebook login |
| `ContactViewController.swift` | **524** | Contact sync, table view, search, follow actions |
| `SendToViewController.swift` | **465** | Friend selection, multi-select, share actions |
| `LiveStreamingConfigurationVC.swift` | **425** | YouTube/Facebook/HydroX stream config, Google auth |
| `LoginTableViewController.swift` | **409** | Login form, email/password, Facebook, validation |
| `AppDelegate.swift` | **391** | Firebase, Branch, push notifications, deep linking, networking |

#### Architecture Concerns

**AppDelegate handles 12+ responsibilities:**
1. Firebase initialization
2. Database setup (SQLite copy)
3. Contact manager initialization
4. Badge management
5. Push notification registration
6. Push notification routing (6 notification types)
7. Google Sign-In configuration
8. IQKeyboardManager setup
9. Branch deep link handling
10. Facebook SDK initialization
11. Web service calls (device registration, profile fetch, OTP verification)
12. View controller instantiation and presentation

**Fix:** Extract into dedicated services:
- `FirebaseService`, `NotificationRouter`, `DeepLinkService`, `DeviceRegistrationService`

---

### 13. Outdated CocoaPods

| Pod | Current | Latest | Status | Impact |
|-----|---------|--------|--------|--------|
| **Alamofire** | **4.9** | **5.x / 6.x** | **CRITICAL — 3+ major versions behind** | 26+ files, complete API refactor needed |
| SwiftyJSON | 5.0 | 5.x | Outdated approach | Replace with `Codable` |
| SQLite.swift | 0.15 | 0.15+ | Functional | Consider GRDB or SwiftData |
| SwiftLoader | 0.4 | 0.4 | Minimal maintenance | Low risk |
| SimpleImageViewer | Git fork | N/A | Custom fork — maintenance risk | Consider replacing |
| BranchSDK | 3.0 | 4.x | One major version behind | Update available |
| Socket.IO-Client-Swift | 16.0 | 16.x | Current | OK |

**Pods at Current Versions (Good):**
- FBSDKLoginKit 17.0, FBSDKShareKit 17.0
- GoogleSignIn 8.0, GoogleAPIClientForREST/YouTube 3.0
- FirebaseCrashlytics 11.0, FirebaseAnalytics 11.0
- SDWebImage 5.0, IQKeyboardManagerSwift 7.0
- libPhoneNumber-iOS 1.2

#### Alamofire 4.9 Impact — 26+ Files

**ApiManager.swift** (core networking — 8 methods):
```
Line 55:  Alamofire.request("\(targetUrl)", method: .get).responseJSON
Line 73:  Alamofire.request(targetUrl, method: .post, parameters: parameter).responseJSON
Line 97:  Alamofire.request(targetUrl, method: .post, parameters: parameter, headers: headers).responseJSON
Line 121: Alamofire.upload(multipartFormData:...)
Line 154: Alamofire.upload(imgData, to: path, method: .put).responseJSON
Line 176: Alamofire.request("\(targetUrl)", method: .get, headers: headers).responseJSON
Line 202: Alamofire.request(targetUrl, method: .post, encoding: JSONEncoding.default...)
Line 219: Alamofire.request(targetUrl, method: .post, encoding: JSONEncoding.default).responseJSON
```

**GoLiveVC.swift** (5 call sites):
```
Line 771: Alamofire.request(...).responseJSON (POST - start stream)
Line 820: Alamofire.request(...).responseJSON (POST - stream config)
Line 858: Alamofire.request(...).responseJSON (POST - empty params)
Line 894: Alamofire.request(...).responseJSON (POST - empty params)
Line 923: Alamofire.request(...).responseJSON (GET - stream status)
```

**Breaking changes in Alamofire v5:** `Alamofire.request()` → `AF.request()`, serializers changed, closure signatures changed, `responseJSON` removed (use `responseDecodable`).

---

### 14. Deprecated Swift/iOS APIs

#### 14.1 NSKeyedArchiver/Unarchiver — Deprecated Patterns (8 occurrences)

**UserDefaultHelper.swift** (both builds):
```
Lines 100-105: NSKeyedUnarchiver.unarchivedObject(ofClasses:..., from: data)
Lines 111-115: NSKeyedArchiver.archivedData(withRootObject:..., requiringSecureCoding: false)
```

**GoLiveVC.swift** (both builds):
```
Line 294/298: NSKeyedUnarchiver.unarchiveObject(with: savedConfig) as? WowzaConfig
Line 314/318: NSKeyedArchiver.archivedData(withRootObject: goCoderConfig)
```

**Fix:** Replace with `Codable` + `JSONEncoder`/`JSONDecoder`.

#### 14.2 UserDefaults.synchronize() — Deprecated (no-op since iOS 12)

```
GoLiveVC.swift Line 316 (Staging) / Line 320 (Production): UserDefaults.standard.synchronize()
```
**Fix:** Remove — iOS 12+ syncs automatically.

#### 14.3 KVC value(forKey:)/setValue(forKey:) — Type-Unsafe

**UserDefaultHelper.swift** (Lines 19, 24, 40, 57, 138):
```swift
Foundation.UserDefaults.standard.value(forKey: key) as? String
Foundation.UserDefaults.standard.setValue(sValue, forKey: key)
```

**RPCircularProgress.swift** (Lines 183, 280, 298, 446, 451):
```swift
animation.value(forKey: AnimationKeys.completionBlock) as? CompletionBlockObject
```

#### 14.4 UIColor(patternImage:) for Backgrounds

```
NotificationViewController.swift Lines 57, 79, 82: UIColor(patternImage: UIImage(named:...)!)
```
**Fix:** Use `UIImageView` with content mode instead.

#### 14.5 Old Notification Center Pattern

**VideoViewController.swift** (Lines 35, 38, 47, 49):
```swift
NotificationCenter.default.addObserver(self, selector: #selector(...),
                                       name: NSNotification.Name.UIApplicationDidBecomeActive, ...)
```
**Fix:** Use `NotificationCenter.default.publisher(for:)` (Combine) or closure-based observers.

---

### 15. Unsafe Code Patterns

#### 15.1 Force Casts (`as!`) — 474 Occurrences

**Severity: CRITICAL — Any of these can cause a runtime crash.**

**Highest-concentration files:**

| File | Count | Examples |
|------|-------|---------|
| `AppDelegate.swift` | 10+ | `as! HTTPURLResponse` (lines 302, 343, 370), `as! ViewLiveVideoViewController` (178) |
| `LoginTableViewController.swift` | 10+ | JSON parsing, storyboard instantiation (lines 97, 133-135, 178) |
| `ProfileTableViewController.swift` | 15+ | `as! HTTPURLResponse` (lines 175, 231, 258, 281), dictionary casts |
| `NotificationViewController.swift` | 8+ | `as! HTTPURLResponse` (91), `as! NotificationCell` |
| `FeedViewController.swift` | 10+ | Array access, cell casting, storyboard instantiation |
| `GoLiveVC.swift` | 10+ | Configuration casting, response handling |
| Model files | 50+ | `as! String`, `as! NSArray`, `as! Int` throughout all 10 model files |

**Fix:** Replace all `as!` with `as?` + `guard let` or `if let`:
```swift
// Before (crash risk):
let vc = storyboard.instantiateViewController(withIdentifier: "id") as! MyVC

// After (safe):
guard let vc = storyboard.instantiateViewController(withIdentifier: "id") as? MyVC else { return }
```

#### 15.2 Force Unwraps (`!`) — 40+ Critical Instances

```
ForgetPasswordVC.swift:48 → (vwForgetPassword.txtName.text?.isEmpty)!
ForgetPasswordVC.swift:53 → !Helper.isValidEmail(vwForgetPassword.txtName.text!)
ForgetPasswordVC.swift:67 → json.dictionaryObject!["error"]
NotificationViewController.swift:51 → UIFontConst.POPPINS_MEDIUM!
NotificationViewController.swift:57 → UIImage(named: "img_bg_plain")!
NotificationViewController.swift:124 → self.arrNotificationList.notification!.count
LoginTableViewController.swift:63 → self.vwForgetPassView.txtName.text!
FeedViewController.swift → self.arrfeedList![index] (multiple)
AppDelegate.swift → Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
```

---

### 16. Memory Management Issues

#### 16.1 Missing `[weak self]` in Closures

Only **1 instance** of `[weak self]` found in the entire app (SettingsViewController.swift:97 — Google Sign-In).

**All API response handlers, notification observers, and Socket.IO handlers capture `self` strongly**, creating potential retain cycles.

**Example (every API call in the app):**
```swift
// Current (retain cycle risk):
ApiManager.Instance.sendHttpGetWithHeader(url) { json, error, response in
    self.tableView.reloadData()  // Strong capture of self
}

// Should be:
ApiManager.Instance.sendHttpGetWithHeader(url) { [weak self] json, error, response in
    self?.tableView.reloadData()
}
```

#### 16.2 `[unowned self]` Usage (Crash Risk)

**13 instances** in SwiftyCamViewController.swift (both builds):
```
Line 280: [unowned self] in camera session queue
Line 291: [unowned self] in camera session
Line 379: [unowned self] in photo capture
Line 482: [unowned self] in video recording
Line 571: [unowned self] in device rotation
Line 861: [unowned self] in video output
```
**Risk:** `[unowned self]` crashes if `self` is deallocated. Use `[weak self]` instead.

#### 16.3 Minimal `deinit` Implementations

Only **5 `deinit` methods** across 75 Swift files:
```
FeedViewController.swift:100 → deinit { self.deinitItsoket() }
NBTextField.swift:36 → deinit with notification cleanup
ContactManager.swift:264 → deinit with observer removal
+ duplicates in Production
```

**Missing:** Most view controllers don't clean up notification observers, timers, or socket connections.

---

### 17. Missing Modern iOS Features

Since the deployment target is **iOS 16.0**, all of these features are available and should be adopted:

| Feature | Status | Available Since | Current Pattern | Occurrences |
|---------|--------|----------------|-----------------|-------------|
| **async/await** | NOT USED | iOS 13 / Swift 5.5 | Closure callbacks | All networking |
| **@MainActor** | NOT USED | iOS 13 / Swift 5.5 | `DispatchQueue.main.async` | **126 occurrences** |
| **Combine** | NOT USED | iOS 13 | NotificationCenter + delegates | 16+ notification observers |
| **SwiftUI** | NOT USED | iOS 13 | 100% UIKit + Storyboards | All screens |
| **Structured Concurrency** | NOT USED | iOS 13 / Swift 5.5 | GCD (73 instances) | All background work |
| **Codable** | NOT USED | Swift 4 | SwiftyJSON + manual parsing | All 10 model files |
| **@MainActor isolation** | NOT USED | iOS 13 | Manual dispatch | All UI updates |

#### GCD Usage (73+ instances)
```
DispatchQueue.main.async { ... }         — 126 occurrences (UI updates)
DispatchQueue.global(qos: .background)   — Background tasks
```

**Fix:** Adopt structured concurrency with `Task`, `async let`, `@MainActor`, and `actor` types.

---

### 18. Networking Layer

#### Architecture: Direct Alamofire Calls (No Protocol Abstraction)

**ApiManager.swift** (228 lines) — Singleton pattern:

```swift
class ApiManager {
    static let Instance = ApiManager()

    // 8 HTTP methods:
    func sendHttpGetWithoutHeader()         // Unauthenticated GET
    func sendHttpGetWithHeader()            // Authenticated GET (x-auth-token)
    func httpPostRequestWithoutHeader()     // Unauthenticated POST
    func httpPostRequestWithHeader()        // Authenticated POST
    func httpPostEncodingRequestWithHeader() // JSON-encoded POST
    func sendMultiPart()                    // Multipart form data upload
    func sendMultiPartAWS()                // AWS S3 direct upload
    func sendPostEncodingWithoutHeader()   // Unauthenticated JSON POST
}
```

**Callback Pattern:**
```swift
typealias ServiceResponse = (JSON, NSError?, URLResponse?) -> Void
typealias ErrorResponse = (NSError?, URLResponse?) -> Void
```

**Configuration loaded from Info.plist** (per environment):
- `Base_URL`, `socketURL`, `ytClientID`, `FB_URL_Scheme`
- `WowzaKey`, `Branch_URI_Scheme`, `ThumbnailBaseURL`
- `StreamingHost`, `StreamingAppName`, `StreamingUsername`, `StreamingPassword`

**Issues:**
- No request/response interceptors
- No retry logic
- No request queuing
- No response caching
- No protocol-based abstraction for testing
- Token stored in UserDefaults (not Keychain)

---

### 19. Data Persistence

#### Three-Layer Storage

| Layer | Implementation | Purpose | Security |
|-------|---------------|---------|----------|
| **UserDefaults** | `UserDefaultHelper.swift` (140 lines) | User prefs, tokens, device info | ⚠️ Not encrypted |
| **SQLite** | `DBManager.swift` (294 lines) via SQLite.swift | Contacts, stories cache | Not encrypted |
| **Keychain** | `KeychainHelper.swift` (92 lines) | Secure credentials | ✓ Encrypted |

**UserDefaults Keys:**
```
pref_user_registered_token  ← Auth token (⚠️ should be in Keychain)
pref_device_id, pref_device_token
pref_user_verified
pref_notification
fb_Id, fb_Token  ← Facebook credentials (⚠️ should be in Keychain)
```

**SQLite Tables:**
- **Contacts** (10 columns): id, name, number, identifier, following, connection_id, user_id, app_user, profilePic, png
- **Stories** (2 columns): storyId, userId

**Issues:**
- Auth token and Facebook tokens stored in UserDefaults instead of Keychain
- SQLite database not encrypted
- NSKeyedArchiver used for dictionary storage (deprecated)

---

### 20. Authentication Flows

| Method | Implementation | Files |
|--------|---------------|-------|
| **Email/Password** | LoginTableViewController → ApiManager POST `/user/login` | LoginTableViewController.swift |
| **Facebook** | FBSDKLoginKit → FacebookLoginManager → ApiManager POST `/user/fb-login` | FacebookLoginManager.swift, LoginTableViewController.swift |
| **Google** | GoogleSignIn SDK → configured in AppDelegate | AppDelegate.swift, SettingsViewController.swift |
| **Phone OTP** | Branch.io deep link → ResendOTPVC → ApiManager GET `/user/verify-number/:code` | ResendOTPVC.swift, AppDelegate.swift |

**Token Lifecycle:**
1. Login → JWT received → stored in UserDefaults
2. All authenticated requests include `x-auth-token` header
3. Logout → POST `/user/logout` → clear UserDefaults + Keychain

---

### 21. UI Patterns & Storyboards

#### Storyboard Files (10 total)

| File | Size | Screens |
|------|------|---------|
| `Main.storyboard` | 218 KB | Initial flow, login, registration, main navigation |
| `SettingFeed.storyboard` | 155 KB | Feed, notifications, requests, profile |
| `StoryShare.storyboard` | 33 KB | Story capture, sharing, privacy |
| `Menu.storyboard` | 28 KB | Side/tab menu navigation |
| `FeedAction.storyboard` | 22 KB | Comments, interactions |
| `LaunchScreen.storyboard` | 4.3 KB | Launch screen |
| `FeedInfoView.xib` | 4.6 KB | Empty state view |
| `ILCustomViews.xib` | 5.3 KB | Custom text field component |
| `BaseViewController.xib` | 7 KB | Base VC template |
| `AppSettings.storyboard` | 25 KB | Wowza framework settings |

#### UI Implementation
- **Layout:** Hybrid — storyboard constraints + programmatic `CAGradientLayer` + some manual frames
- **Custom Components:** `ILCustomViews` (@IBDesignable), `RPCircularProgress`, `SwiftyCamButton`, `Meter`
- **Styling:** Poppins/Roboto fonts, purple-to-blue gradient theme via `UIColor` extension
- **Navigation:** Tab-based + storyboard segues + programmatic push/pop via Helper methods

**Issues:**
- Storyboards cause merge conflicts and are hard to version control
- 10+ files use `instantiateViewController(withIdentifier:)` with string literals (typo risk)
- Manual frame calculations in some views instead of Auto Layout

---

### 22. Accessibility & Localization

#### Accessibility: NOT IMPLEMENTED

- Zero `accessibilityLabel` usage
- Zero `accessibilityHint` usage
- Zero `isAccessibilityElement` configuration
- No VoiceOver support
- No Dynamic Type support beyond system defaults
- No accessibility identifiers for UI testing

#### Localization: MINIMAL

- Only **5 instances** of `NSLocalizedString` (all in SwiftyCamViewController for camera permission alerts)
- No `Localizable.strings` files
- All user-facing text hardcoded in Swift code and storyboards
- English only
- `MessageConst.swift` centralizes some strings but without localization

---

### 23. Testing

#### Test Files (3 files, 429 total lines)

| File | Lines | Coverage |
|------|-------|---------|
| `HydroXTests.swift` | 61 | Basic smoke tests: bundle validation, date comparison, string trimming |
| `ApiManagerTests.swift` | 230 | ApiManager singleton, URLProtocol stubbing, header injection |
| `RegistrationVC.swift` | 138 | Partial registration test |

#### Missing Test Coverage
- No view controller tests
- No model tests
- No integration tests
- No UI tests (XCUITest)
- No snapshot tests
- No data persistence tests
- No socket.io tests
- No authentication flow tests

---

### 24. Debug & Hardcoded Values

#### Debug `print()` Statements — 404 Occurrences

**Severity: HIGH** — These appear in production builds and can leak sensitive data.

**Top files by print count:**
- SwiftyCamViewController.swift — Camera operation logs
- Helper.swift — Error descriptions (`print(error?.localizedDescription ?? "error")`)
- DBManager.swift — Database operation results
- FeedViewController.swift — Feed loading debug info
- GoLiveVC.swift — Streaming status logs
- Multiple view controllers — API response logging

**Fix:** Replace with `os.log` or a logging framework with log-level control. Strip from release builds.

#### Hardcoded URLs

```
Helper.swift:19 → "https://hydrox-stage.app.link/invite"
Config.swift:13 → "https://stage.api.hydrox.io/api/v1/"
LiveStreamingConfigurationVC.swift:220 → "https://www.youtube.com/my_live_events"
GoLiveVC.swift:765 → "https://www.googleapis.com/youtube/v3/liveStreams?..."
GoLiveVC.swift:813 → "https://www.googleapis.com/youtube/v3/liveBroadcasts?..."
```

**Note:** Base URL is properly loaded from Info.plist per environment. YouTube API URLs are acceptable as constants.

---

## 25. Existing TODOs in Codebase

| File | Line | Comment |
|------|------|---------|
| `modules/feed/feedController.js` | 342 | TODO: Remove objects which are Hidden By user |
| `modules/feed/feedController.js` | 343 | TODO: Remove objects which are Private and not shared with me |
| `modules/connection/connectionController.js` | 346 | TODO: Turned off phone number parameter for checking app crash or not |
| `FeedViewController.swift` (Staging) | 523 | TODO: Remove Code after testing |
| `FeedViewController.swift` (Production) | 519 | TODO: Remove Code after testing |
| `SwiftyCamViewController.swift` (Staging) | 432 | TODO: Add Support for Retina Flash and add front flash |
| `SwiftyCamViewController.swift` (Staging) | 557 | TODO: Look into switching camera during video recording |
| `SwiftyCamViewController.swift` (Production) | 428 | TODO: Add Support for Retina Flash and add front flash |
| `SwiftyCamViewController.swift` (Production) | 553 | TODO: Look into switching camera during video recording |

---

## Quantitative Summary

### Pattern Counts

| Pattern | Backend | iOS | Total |
|---------|---------|-----|-------|
| Force casts (`as!`) | N/A | **474** | 474 |
| Debug `print()` statements | — | **404** | 404 |
| `require()` (CommonJS) | **243** | N/A | 243 |
| `@objc` annotations | N/A | **158** | 158 |
| `DispatchQueue.main.async` | N/A | **126** | 126 |
| `MARK:` comments (good practice) | N/A | **264** | 264 |
| `UIApplication.shared` usage | N/A | **61** | 61 |
| Force unwraps (`!`) | N/A | **40+** | 40+ |
| `.indexOf()` (should use `.includes()`) | **5** | N/A | 5 |
| `[weak self]` captures | N/A | **1** | 1 |
| `[unowned self]` (risky) | N/A | **13** | 13 |
| `deinit` implementations | N/A | **5** | 5 |
| TODO/FIXME comments | **3** | **6** | 9 |
| `NSKeyedArchiver` usage | N/A | **8** | 8 |
| `synchronize()` (deprecated) | N/A | **2** | 2 |

### Overall Metrics

| Metric | Backend | iOS (per target) | Total |
|--------|---------|-------------------|-------|
| Source files | 22 | 75 | 97 |
| Lines of code | ~9,086 | ~15,273 | ~24,359 |
| Test files | 18 | 3 | 21 |
| Test lines | ~4,500 | ~429 | ~4,929 |
| Deprecated packages/pods | 12 | 3 | 15 |
| Deprecated API patterns | 15+ | 10+ | 25+ |
| Critical severity items | 7 | 6 | 13 |
| High severity items | 5 | 8 | 13 |
| Medium severity items | 5 | 10+ | 15+ |
| API endpoints | 45 | N/A | 45 |
| External integrations | 9 | 8 | 17 |
| CI/CD pipelines | 0 | 0 | 0 |
| Environment variables | 43+ | Per-env Info.plist | — |

---

## Prioritized Modernization Roadmap

### Phase 1: Critical Fixes (Immediate — Safety & Stability)

**Backend:**
- [x] Replace synchronous `bcrypt.hashSync()`/`compareSync()` with async variants (4 locations in `userController.js`) — **DONE**
- [x] Add rate limiting (`express-rate-limit`) to `server.js` — **DONE**
- [x] Replace deprecated `jwt-simple` with `jsonwebtoken` (enforce HS256 algorithm) — **DONE**
- [x] Fix `reject.error()` bug in `modules/static/staticUtils.js:17` — **DONE**
- [x] Remove deprecated Mongoose connection options in `config/database.js:5-8` — **DONE**
- [x] Replace `.remove()` with `.deleteMany()` in `modules/feed/feedUtils.js:210` — **DONE**
- [x] Add environment variable validation at startup (use `envalid` or `joi`) — **DONE** (custom `config/validateEnv.js`)

**iOS:**
- [x] Fix force casts (`as!`) → safe `as?` + `guard let` (prioritized in NotificationViewController, ForgetPasswordVC) — **PARTIAL — key files done**
- [ ] Add `[weak self]` to all closure-based API callbacks (currently only 1 instance in entire app)
- [x] Replace `[unowned self]` with `[weak self]` in SwiftyCamViewController (6 locations per build × 2 builds) — **DONE**
- [x] Remove `UserDefaults.synchronize()` calls (2 locations in GoLiveVC) — **DONE**
- [ ] Move auth token and Facebook tokens from UserDefaults to Keychain
- [x] Replace NSKeyedArchiver with JSONSerialization in UserDefaultHelper (both builds) — **DONE**

### Phase 2: High Priority (1-2 Months — Architecture & Dependencies)

**Backend:**
- [ ] Upgrade Mongoose v5 → v7+ (all modules affected)
- [ ] Replace `aws-sdk` v2 → `@aws-sdk/*` v3 modular SDK (`helper/aws.js`)
- [x] Replace `moment.js` with native Date arithmetic in `feedController.js` (3 locations) — **DONE**
- [ ] Replace `connect-multiparty` with `multer` (`modules/feed/feedRoute.js`)
- [ ] Convert all controllers to async/await (replace promise chains)
- [ ] Add input sanitization middleware to `server.js`
- [ ] Add CSRF protection
- [ ] Change S3 ACL from `public-read` to private with signed URLs

**iOS:**
- [ ] Upgrade Alamofire 4.9 → 5.x/6.x (26+ files affected, complete API migration)
- [ ] Replace SwiftyJSON with `Codable` protocol (all 10 model files)
- [ ] Implement async/await in ApiManager (replace callback typedefs)
- [ ] Replace 126 `DispatchQueue.main.async` calls with `@MainActor`
- [ ] Remove 404 `print()` statements — replace with `os.log` or structured logging
- [ ] Extract MVVM ViewModels for FeedViewController (1,249 lines) and GoLiveVC (953 lines)
- [ ] Refactor AppDelegate into dedicated services (currently 12+ responsibilities)

### Phase 3: Strategic Improvements (3-6 Months — Modernization)

**Backend:**
- [ ] Migrate from CommonJS `require()` to ES Modules `import/export`
- [ ] Replace `email-templates-v2` and deprecated SMTP transport
- [ ] Replace `apn` package with `@parse/node-apn` or Firebase Admin SDK
- [ ] Upgrade ESLint to v9+ flat config — enforce `no-var` as error
- [ ] Add TypeScript (gradual migration starting with new code)
- [ ] Implement CI/CD pipeline (GitHub Actions: lint, test, deploy)
- [ ] Add structured JSON logging with correlation IDs
- [ ] Add missing database indexes (feed.user, feed.storyExpiration, feed.feedType)
- [ ] Pin Node.js version in `engines` field and `.nvmrc`
- [ ] Add graceful shutdown handler

**iOS:**
- [ ] Adopt Combine for reactive patterns (replace NotificationCenter observers, delegates)
- [ ] Replace IQKeyboardManager with native keyboard handling (iOS 15+)
- [ ] Update BranchSDK 3.0 → 4.x
- [ ] Migrate modified screens from Storyboards to programmatic UI
- [ ] Add accessibility support (VoiceOver labels, Dynamic Type)
- [ ] Add localization infrastructure (`Localizable.strings`, `NSLocalizedString`)
- [ ] Update SQLite.swift or migrate to GRDB/SwiftData
- [ ] Introduce SwiftUI for new screens

### Phase 4: Long-term Polish (Ongoing)

**Backend:**
- [x] Replace `indexOf()` patterns with `.includes()` (5 locations) — **DONE**
- [ ] Convert synchronous fs operations to async
- [ ] Increase test coverage thresholds (currently 20% minimum)
- [ ] Add API documentation (generate from Swagger/OpenAPI spec)
- [ ] Add Docker configuration for consistent deployments
- [ ] Implement live comment broadcasting via Socket.IO
- [ ] Add request correlation IDs for distributed tracing

**iOS:**
- [x] Replace KVC `value(forKey:)`/`setValue(forKey:)` with typed property access in UserDefaultHelper — **DONE**
- [ ] Adopt structured concurrency (`Task`, `async let`, `actor`)
- [ ] Refactor remaining large view controllers (ProfileTableVC, ContactVC, etc.)
- [ ] Add comprehensive test coverage (unit, integration, UI)
- [ ] Remove SimpleImageViewer custom fork dependency
- [x] Replace `UIColor(patternImage:)` force unwraps with safe unwrapping (NotificationViewController, both builds) — **PARTIAL**
- [ ] Add snapshot testing for UI components
- [ ] Eliminate all `@objc` bridging where possible (158 occurrences)

---

## Appendix A: Complete API Endpoint Reference

### Public Endpoints (No Auth Required)
```
POST   /api/v1/user/create
POST   /api/v1/user/login
POST   /api/v1/user/fb-login
POST   /api/v1/user/forget-password
GET    /api/v1/user/reset-password/:userId/:cToken
GET    /api/v1/user/verify-email/:userId/:vToken
POST   /api/v1/notification/contact-us
POST   /api/v1/feed/sns-notification
GET    /api/v1/static/privacy-policy
GET    /api/v1/static/terms-of-use
```

### Authenticated Endpoints (x-auth-token required)
```
# User
GET    /api/v1/user/profile-pic-aws-presinged-url
GET    /api/v1/user/resend-otp
GET    /api/v1/user/verify-number/:vCode
POST   /api/v1/user/change-password
GET    /api/v1/user/me
POST   /api/v1/user/logout
POST   /api/v1/user/update-profile
POST   /api/v1/user/send-invitation

# Device
POST   /api/v1/device/create
PUT    /api/v1/device/update
POST   /api/v1/device/update-notification-pref
GET    /api/v1/device/test-push

# Connection (Social)
POST   /api/v1/connection/follow
POST   /api/v1/connection/unfollow
GET    /api/v1/connection/followers
GET    /api/v1/connection/followings
GET    /api/v1/connection/hydrox-users
GET    /api/v1/connection/search

# Feed (Stories & Live)
POST   /api/v1/feed/new-story
GET    /api/v1/feed/recent-stories
GET    /api/v1/feed/stories
POST   /api/v1/feed/go-live-req
GET    /api/v1/feed/live-req-count
GET    /api/v1/feed/live-req
POST   /api/v1/feed/activate-story
POST   /api/v1/feed/add-comment
POST   /api/v1/feed/report
GET    /api/v1/feed/comments/:feedId
POST   /api/v1/feed/seen
POST   /api/v1/feed/seen-by
POST   /api/v1/feed/go-live-get-stream-id
POST   /api/v1/feed/go-live-start-publishing
POST   /api/v1/feed/go-live-send-notification
POST   /api/v1/feed/go-live-stop-publishing
POST   /api/v1/feed/hydrox-up
POST   /api/v1/feed/hide-by-user
GET    /api/v1/feed/feed-detail/:feedId
GET    /api/v1/feed/my-stories
POST   /api/v1/feed/remove-feed

# Notification
GET    /api/v1/notification/list
```

### WebSocket Events
```
Client → Server: onFeedJoin(feedId)
Client → Server: onFeedUnjoin(feedId)
Server → Client: liveFeedCount(count)
```

## Appendix B: iOS Privacy Manifest

**File:** `PrivacyInfo.xcprivacy`

| Data Type | Linked to User | Purpose |
|-----------|---------------|---------|
| Name | Yes | User profile display |
| Email Address | Yes | Account authentication |
| Phone Number | Yes | Account verification, contact matching |
| Photos/Videos | Yes | User-generated stories/live content |
| Contacts | No | Match friends on platform |
| Device ID | Yes | Push notification registration |
| Crash Data | No | Firebase Crashlytics |

**Required Reason APIs:**
- NSUserDefaults (CA92.1) — App-scoped preferences
- File Timestamp APIs (C617.1) — Display timestamps
- System Boot Time (35F9.1) — Elapsed time measurement
- Disk Space (E174.1) — Pre-write capacity check

---

## Appendix C: Implementation Changelog

> **Date:** March 14, 2026
> **Implemented by:** Automated analysis-driven modernization pass

The following changes were implemented based on the findings in this analysis document. Each change maps to a specific finding and roadmap item above.

---

### Backend Changes

#### 1. Replaced synchronous bcrypt with async variants (`modules/user/userController.js`)

**Finding:** Section 3.1 — Synchronous Bcrypt blocks the event loop for ~200-500ms per call.

**Changes made (4 locations):**

| Line (approx.) | Before | After |
|----------------|--------|-------|
| `userCtr.create` | `bcrypt.hashSync(password, BCRYPT_ROUNDS)` | `bcrypt.hash(password, BCRYPT_ROUNDS).then(...)` |
| `userCtr.login` | `bcrypt.compareSync(password, user.password)` | `bcrypt.compare(password, user.password).then(...)` |
| `userCtr.forgetPassword` | `bcrypt.hashSync(randomPassword, BCRYPT_ROUNDS)` | `bcrypt.hash(randomPassword, BCRYPT_ROUNDS).then(...)` |
| `userCtr.changePassword` | `bcrypt.compareSync(password, user.password)` + `bcrypt.hashSync(newPassword, BCRYPT_ROUNDS)` | `bcrypt.compare(...).then(...)` + `bcrypt.hash(...).then(...)` |

**Impact:** Eliminates event loop blocking during password operations. Each call now runs asynchronously, freeing the event loop for other requests.

---

#### 2. Added rate limiting to `server.js`

**Finding:** Section 5 — No rate limiting (CRITICAL severity).

**Changes made:**
- Installed `express-rate-limit` npm package
- Added general API rate limiter: 100 requests per 15-minute window per IP on `/api/` routes
- Added stricter auth rate limiter: 20 requests per 15-minute window on `/api/v1/user/login`, `/api/v1/user/create`, `/api/v1/user/forget-password`
- Uses `standardHeaders: true` (returns rate limit info in `RateLimit-*` headers) and `legacyHeaders: false`

**Files modified:** `server.js`, `package.json`

---

#### 3. Replaced `jwt-simple` with `jsonwebtoken` (`helper/jwt.js`)

**Finding:** Section 5 — JWT algorithm not enforced (HIGH severity).

**Changes made:**
- Replaced `jwt-simple` require with `jsonwebtoken`
- `getAuthToken()`: Changed from `jwt.encode(data, secret)` to `jwt.sign(data, secret, { algorithm: 'HS256' })`
- `decodeAuthToken()`: Changed from `jwt.decode(token, secret)` to `jwt.verify(token, secret, { algorithms: ['HS256'] })`
- Installed `jsonwebtoken` npm package

**Impact:** Enforces HS256 algorithm explicitly, preventing algorithm confusion attacks. `jwt.verify()` also validates token expiry and signature integrity.

---

#### 4. Fixed `reject.error()` bug (`modules/static/staticUtils.js:17`)

**Finding:** Section 4.4 — Bug: `reject.error()` should be `reject(error)`.

**Change:** `reject.error(err)` → `reject(err)`

**Impact:** Error handling in `getStaticContent()` now correctly rejects the promise. Previously, calling `.error()` on the reject function would throw a TypeError, masking the actual template rendering error.

---

#### 5. Removed deprecated Mongoose connection options (`config/database.js`)

**Finding:** Section 2 — Mongoose v5 deprecated connection options (no-op in v6+).

**Change:** Removed all 4 deprecated options from `mongoose.connect()`:
- `useNewUrlParser: true`
- `useUnifiedTopology: true`
- `useCreateIndex: true`
- `useFindAndModify: false`

Now uses: `mongoose.connect(process.env.DB_URL)`

**Impact:** Eliminates deprecation warnings and prepares for Mongoose v6+/v7+ upgrade.

---

#### 6. Replaced `.remove()` with `.deleteMany()` (`modules/feed/feedUtils.js:209`)

**Finding:** Section 3.4 — `FeedList.find({user: userId}).remove()` uses deprecated `.remove()`.

**Change:** `FeedList.find({ user: userId }).remove()` → `FeedList.deleteMany({ user: userId })`

**Impact:** Uses the modern Mongoose API. `.remove()` was deprecated in Mongoose 5.x and removed in 6.x.

---

#### 7. Replaced `.indexOf()` with `.includes()` (5 locations)

**Finding:** Section 3.5 — `.indexOf() !== -1` pattern should use `.includes()`.

**Files and changes:**
| File | Before | After |
|------|--------|-------|
| `helper/validate.js:84` | `aEnum.indexOf(str) !== -1` | `aEnum.includes(str)` |
| `modules/feed/feedRoute.js:45` | `constants.supportedMime.image.indexOf(file.type) === -1` | `!constants.supportedMime.image.includes(file.type)` |
| `modules/feed/feedRoute.js:47` | `constants.supportedMime.video.indexOf(file.type) === -1` | `!constants.supportedMime.video.includes(file.type)` |
| `modules/feed/feedUtils.js:19` | `constants.supportedMime.video.indexOf(file.type) !== -1` | `constants.supportedMime.video.includes(file.type)` |
| `modules/feed/feedUtils.js:101` | `constants.supportedMime.video.indexOf(file.type) !== -1` | `constants.supportedMime.video.includes(file.type)` |

---

#### 8. Added environment variable validation at startup

**Finding:** Section 10 — No environment variable validation; missing vars cause runtime errors.

**Changes made:**
- Created new file `config/validateEnv.js` with validation for 22 required environment variables
- Added `require('./config/validateEnv')()` call in `server.js` immediately after `dotenv.config()`
- Server exits with error code 1 and descriptive message if any required vars are missing

**Required vars validated:** `PORT`, `DB_URL`, `JwtSecret`, AWS credentials (4), SMTP config (5), APN config (4)

---

#### 9. Replaced `moment.js` with native Date arithmetic (`modules/feed/feedController.js`)

**Finding:** Section 2 — `moment` is in maintenance-only mode.

**Changes made (3 locations):**
- Removed `const moment = require('moment')` import
- Replaced `new Date(moment().add(constants.story.expirationDays, 'days').format())` with `new Date(Date.now() + constants.story.expirationDays * 24 * 60 * 60 * 1000)` (2 occurrences for story expiration)
- Replaced `new Date(moment().add(constants.story.liveExpirationDays, 'days').format())` with `new Date(Date.now() + constants.story.liveExpirationDays * 24 * 60 * 60 * 1000)` (1 occurrence for live stream expiration)

**Impact:** Eliminates the `moment` dependency for these use cases. Native Date arithmetic is zero-dependency and handles the simple "add N days" operation correctly.

---

### iOS Changes (Applied to Both Staging and Production Builds)

#### 10. Replaced `[unowned self]` with `[weak self]` in SwiftyCamViewController

**Finding:** Section 16.2 — `[unowned self]` crashes if `self` is deallocated.

**Files modified:**
- `Staging/HydroX/HydroX/Resources/SourceForStory/SwiftyCamViewController.swift` (6 locations)
- `Production/HydroX/HydroX/Resources/SourceForStory/SwiftyCamViewController.swift` (6 locations)

**Locations changed:** Camera session queue closures (lines 284, 295, 383, 486, 575, 858 in Staging)

**Impact:** Prevents potential crashes when the view controller is deallocated while async camera operations are still in-flight. `[weak self]` safely nils out the reference instead of crashing.

---

#### 11. Removed deprecated `UserDefaults.synchronize()` calls in GoLiveVC

**Finding:** Section 14.2 — `synchronize()` is a no-op since iOS 12.

**Files modified:**
- `Staging/HydroX/HydroX/View Controllers/GoLive/GoLiveVC.swift`
- `Production/HydroX/HydroX/View Controllers/GoLive/GoLiveVC.swift`

**Change:** Replaced `UserDefaults.standard.synchronize()` with a comment noting iOS 12+ auto-syncs.

---

#### 12. Replaced KVC `value(forKey:)`/`setValue(forKey:)` with typed UserDefaults API in UserDefaultHelper

**Finding:** Section 14.3 — KVC methods are type-unsafe.

**Files modified:**
- `Staging/HydroX/HydroX/Helpers/UserDefaultHelper.swift`
- `Production/HydroX/HydroX/Helpers/UserDefaultHelper.swift`

**Changes:**
| Method | Before | After |
|--------|--------|-------|
| `getPREF()` | `UserDefaults.standard.value(forKey:) as? String` | `UserDefaults.standard.string(forKey:)` |
| `setPREF()` | `UserDefaults.standard.setValue(_, forKey:)` | `UserDefaults.standard.set(_, forKey:)` |
| `setIntPREF()` | `UserDefaults.standard.setValue(_, forKey:)` | `UserDefaults.standard.set(_, forKey:)` |
| `setDoublePREF()` | `UserDefaults.standard.setValue(_, forKey:)` | `UserDefaults.standard.set(_, forKey:)` |
| `setBundleSetting()` | `UserDefaults.standard.setValue(_, forKey:)` | `UserDefaults.standard.set(_, forKey:)` |

---

#### 13. Replaced NSKeyedArchiver/Unarchiver with JSONSerialization in UserDefaultHelper

**Finding:** Section 14.1 — NSKeyedArchiver patterns are deprecated.

**Files modified:**
- `Staging/HydroX/HydroX/Helpers/UserDefaultHelper.swift`
- `Production/HydroX/HydroX/Helpers/UserDefaultHelper.swift`

**Changes:**
- `getDicPREF()`: Replaced `NSKeyedUnarchiver.unarchivedObject(ofClasses:from:)` with `JSONSerialization.jsonObject(with:options:)`
- `setDicPREF()`: Replaced `NSKeyedArchiver.archivedData(withRootObject:requiringSecureCoding:)` with `JSONSerialization.data(withJSONObject:options:)`

**Impact:** Eliminates dependency on NSCoding/NSSecureCoding for simple dictionary serialization. JSON is more portable and future-proof.

---

#### 14. Fixed deprecated NSNotification.Name patterns in VideoViewController

**Finding:** Section 14.5 — Old `NSNotification.Name.UIApplicationDidBecomeActive` pattern.

**Files modified:**
- `Staging/HydroX/HydroX/View Controllers/Stroy/VideoViewController.swift`
- `Production/HydroX/HydroX/View Controllers/Stroy/VideoViewController.swift`

**Changes:**
| Before | After |
|--------|-------|
| `NSNotification.Name.UIApplicationDidBecomeActive` | `UIApplication.didBecomeActiveNotification` |
| `NSNotification.Name.UIApplicationDidEnterBackground` | `UIApplication.didEnterBackgroundNotification` |

---

#### 15. Fixed force unwraps and force casts in NotificationViewController

**Finding:** Sections 15.1 & 15.2 — Force casts and force unwraps cause crash risk.

**Files modified:**
- `Staging/HydroX/HydroX/View Controllers/Notification/NotificationViewController.swift`
- `Production/HydroX/HydroX/View Controllers/Notification/NotificationViewController.swift`

**Changes:**
| Before | After |
|--------|-------|
| `UIFontConst.POPPINS_MEDIUM!` | `if let font = UIFontConst.POPPINS_MEDIUM { ... }` |
| `UIImage(named: "img_bg_plain")!` | `if let bgImage = UIImage(named: "img_bg_plain") { ... }` |
| `(reponse as! HTTPURLResponse).statusCode` | `(reponse as? HTTPURLResponse)?.statusCode` |
| `Int(page)!` | `Int(page) ?? 0` |

---

#### 16. Fixed force unwraps in ForgetPasswordVC

**Finding:** Section 15.2 — Force unwraps on optional text fields.

**Files modified:**
- `Staging/HydroX/HydroX/View Controllers/ForgetPassword/ForgetPasswordVC.swift`
- `Production/HydroX/HydroX/View Controllers/ForgetPassword/ForgetPasswordVC.swift`

**Changes:**
| Before | After |
|--------|-------|
| `(vwForgetPassword.txtName.text?.isEmpty)!` | `guard let emailText = vwForgetPassword.txtName.text, !emailText.isEmpty else { ... }` |
| `Helper.isValidEmail(vwForgetPassword.txtName.text!)` | `Helper.isValidEmail(emailText)` (uses guard-bound variable) |
| `self.vwForgetPassword.txtName.text!` (parameter) | `self.vwForgetPassword.txtName.text ?? ""` |
| `json.dictionaryObject!["error"]` | `json.dictionaryObject?["error"]` |
| `json.dictionaryObject!["msg"]` | `json.dictionaryObject?["msg"]` |

---

### Summary of All Changes

| Category | Changes Made | Files Modified |
|----------|-------------|----------------|
| **Backend — Security** | Async bcrypt, rate limiting, JWT algorithm enforcement | `userController.js`, `server.js`, `jwt.js` |
| **Backend — Bug Fixes** | `reject.error()` → `reject(err)` | `staticUtils.js` |
| **Backend — Deprecated APIs** | Mongoose options, `.remove()`, `.indexOf()`, `moment.js` | `database.js`, `feedUtils.js`, `validate.js`, `feedRoute.js`, `feedController.js` |
| **Backend — Infrastructure** | Environment variable validation | `config/validateEnv.js` (new), `server.js` |
| **Backend — Dependencies** | Installed `express-rate-limit`, `jsonwebtoken` | `package.json` |
| **iOS — Crash Prevention** | `[unowned self]` → `[weak self]`, force unwrap fixes, force cast fixes | `SwiftyCamViewController.swift` (×2), `NotificationViewController.swift` (×2), `ForgetPasswordVC.swift` (×2) |
| **iOS — Deprecated APIs** | `synchronize()` removal, NSKeyedArchiver → JSONSerialization, KVC → typed API, NSNotification.Name modernization | `GoLiveVC.swift` (×2), `UserDefaultHelper.swift` (×2), `VideoViewController.swift` (×2) |

**Total files modified:** 20 (8 backend + 12 iOS)
**New files created:** 1 (`config/validateEnv.js`)
