# HydroX App Modernization & Deprecation Analysis

> **Date:** March 13, 2026
> **Application:** HydroX - Social Media App with Live Streaming
> **Components:** Node.js/Express Backend + iOS (Swift/UIKit) Frontend

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Backend (Node.js) Analysis](#backend-nodejs-analysis)
   - [Deprecated Dependencies](#1-deprecated-dependencies)
   - [Deprecated Node.js/JavaScript Patterns](#2-deprecated-nodejsjavascript-patterns)
   - [Outdated Code Patterns](#3-outdated-code-patterns)
   - [Security Concerns](#4-security-concerns)
   - [Build & Config Issues](#5-build--config-issues)
3. [Frontend (iOS) Analysis](#frontend-ios-analysis)
   - [Outdated CocoaPods](#6-outdated-cocoapods)
   - [Deprecated Swift/iOS APIs](#7-deprecated-swiftios-apis)
   - [Architecture Concerns](#8-architecture-concerns)
   - [Missing Modern iOS Features](#9-missing-modern-ios-features)
   - [Unsafe Code Patterns](#10-unsafe-code-patterns)
   - [Data Storage Concerns](#11-data-storage-concerns)
4. [Existing TODOs in Codebase](#12-existing-todos-in-codebase)
5. [Prioritized Modernization Roadmap](#prioritized-modernization-roadmap)

---

## Executive Summary

The HydroX application has significant technical debt across both its Node.js backend and iOS frontend. Key issues include:

- **Backend:** 7 critically deprecated npm packages, pervasive callback-based patterns instead of async/await, CommonJS modules instead of ES modules, and deprecated Node.js APIs
- **Frontend:** Alamofire 4.9 (3+ major versions behind), deprecated iOS APIs (NSKeyedArchiver, UserDefaults.synchronize), no async/await adoption, MVC architecture with massive view controllers, and zero SwiftUI/Combine usage
- **Both:** Missing CI/CD pipeline, minimal test coverage, and no structured error handling

**Total Files Affected:** ~60+ files across both platforms

---

## Backend (Node.js) Analysis

**Base Path:** `HydroX-Backend -NodeJS/`

### 1. Deprecated Dependencies

#### CRITICAL: Must Replace

| Package | Current Version | Status | Replacement | Files Affected |
|---------|----------------|--------|-------------|----------------|
| `aws-sdk` | v2.1692.0 | Deprecated | `@aws-sdk/*` (modular v3) | `helper/aws.js` |
| `moment` | v2.30.1 | Maintenance-only | `date-fns` or `Day.js` | `helper/logger.js`, `modules/feed/feedController.js` |
| `q` | v1.5.1 | Deprecated | Native `Promise` | `helper/auth.js`, `helper/aws.js`, `modules/feed/feedUtils.js`, `modules/user/userController.js` |
| `request` | v2.88.2 | Deprecated | `axios`, `node-fetch`, or native `fetch` (Node 18+) | `helper/auth.js`, `helper/wowza.js` |
| `node-uuid` | v1.4.8 | Deprecated | `crypto.randomUUID()` (Node 15.7+) or `uuid` v4 | `helper/auth.js`, `helper/aws.js`, `modules/feed/feedController.js`, `modules/feed/feedUtils.js`, `modules/user/userController.js` |
| `jwt-simple` | v0.5.6 | Outdated | `jsonwebtoken` or `jose` | `helper/jwt.js` |
| `mongoose` | v5.13.22 | Very outdated | Mongoose v7+ | `config/database.js`, all modules |

#### HIGH: Should Replace

| Package | Current Version | Status | Replacement | Files Affected |
|---------|----------------|--------|-------------|----------------|
| `email-templates-v2` | v2.0.3 | Outdated fork | `mjml` or `nodemailer-templates` | `helper/notification.js` |
| `nodemailer-smtp-transport` | v2.7.4 | Deprecated | Built-in nodemailer transport | `helper/notification.js` |
| `connect-multiparty` | v2.2.0 | Legacy | `multer` | Route middleware |
| `path` | v0.12.7 | Unnecessary wrapper | Native `path` module | Remove from package.json |
| `rmdir` | - | Outdated | Native `fs.rmSync()` (Node 14.14+) | `modules/feed/feedUtils.js` |

#### Detailed Deprecated Dependency Locations

**aws-sdk v2 (deprecated):**
```
helper/aws.js:2 → const aws = require('aws-sdk');
```
AWS SDK v2 entered maintenance mode. The modular v3 SDK (`@aws-sdk/client-s3`, `@aws-sdk/client-sns`) offers smaller bundle size, native Promise support, and continued security patches.

**moment.js (maintenance mode):**
```
helper/logger.js:3,15 → moment().format('YYYY-MM-DD hh:mm:ss')
modules/feed/feedController.js:3,76,515,738 → moment().add(constants.story.expirationDays, 'days')
```
Moment.js recommends against use in new projects. `date-fns` provides tree-shakeable functions; `Day.js` provides a compatible API with 2KB size.

**q promise library (deprecated):**
```
helper/auth.js:3,23 → Q.defer() pattern
helper/aws.js:4,28,57 → Q.defer() with callbacks
modules/feed/feedUtils.js:12,77 → Q.allSettled()
modules/user/userController.js:9,121,414 → Q.defer() pattern
```
The `q` library predates native Promises. Replace `Q.defer()` with `new Promise()` and `Q.allSettled()` with `Promise.allSettled()`.

**request (deprecated):**
```
helper/auth.js:2,24 → request() for Facebook token verification
helper/wowza.js:3,45,68,125,148 → request() for Wowza streaming API calls
```
The `request` library is fully deprecated with no security updates. Use `axios` or Node.js 18+ native `fetch`.

**node-uuid (deprecated):**
```
helper/auth.js:6,18 → uuid.v4() for OTP generation
helper/aws.js:3,27,94,140 → uuid.v4() for S3 key generation
modules/feed/feedController.js:14,716 → uuid.v4() for media naming
modules/feed/feedUtils.js:8,127 → uuid.v4() for file naming
modules/user/userController.js:12,248 → uuid.v4() for avatar naming
```
Renamed to `uuid` package years ago. Better yet, use `crypto.randomUUID()` built into Node.js 15.7+.

---

### 2. Deprecated Node.js/JavaScript Patterns

#### 2.1 `url.parse()` — Deprecated API

```
helper/wowza.js:7 → const { hostname, path } = url.parse(ingestionUrl);
helper/wowza.js:13 → const { hostname, path } = url.parse(streamUrl);
```
**Fix:** Replace with `new URL(ingestionUrl)` constructor.

#### 2.2 Callback-based `fs` methods

```
helper/logger.js:9-12 → fs.access(logDir, (err) => { fs.mkdir(logDir); })
modules/feed/feedController.js:52-54 → fs.unlink(files.story.path) (no callback, deprecated)
modules/feed/feedUtils.js:128 → fs.mkdirSync() (blocks event loop)
modules/feed/feedUtils.js:132 → fs.renameSync() (blocks event loop)
```
**Fix:** Use `fs.promises.access()`, `fs.promises.unlink()`, `fs.promises.mkdir()`, etc.

#### 2.3 Mongoose `.remove()` — Deprecated

```
modules/feed/feedUtils.js:210 → FeedList.find({user: userId}).remove()
```
**Fix:** Replace with `.deleteMany()` or `.deleteOne()`.

#### 2.4 Callback-based AWS S3 Calls

```
helper/aws.js:35,71-86,123-132,178-189 → s3.getSignedUrl('putObject', {...}, (err, url) => {...})
```
**Fix:** AWS SDK v3 supports native Promises and async/await.

#### 2.5 Callback-based Email Sending

```
helper/notification.js:33-51 → template.render(data, (err, result) => {...})
helper/notification.js:44-50 → transporter.sendMail(mailOptions, (mailSendErr, info) => {...})
```
**Fix:** Nodemailer v6+ supports `await transporter.sendMail(options)`.

---

### 3. Outdated Code Patterns

#### 3.1 CommonJS `require()` Instead of ES Modules

**Every file** in the backend uses `require()`:
```
server.js:2-22 → const express = require('express'); etc.
```
**Fix:** Migrate to `import/export` syntax with `"type": "module"` in package.json.

#### 3.2 Promise Chains Instead of async/await

Pervasive throughout the codebase:
```
modules/feed/feedController.js:80-97 → .then().catch() chains
modules/feed/feedController.js:145-453 → Multiple nested .then() chains
modules/user/userController.js → Extensive promise chains
```
**Fix:** Refactor to `async/await` for readability and error handling.

#### 3.3 `.indexOf() !== -1` Instead of `.includes()`

```
modules/feed/feedUtils.js:22,102 → constants.supportedMime.video.indexOf(file.type) !== -1
```
**Fix:** Replace with `constants.supportedMime.video.includes(file.type)`.

#### 3.4 Outdated Lodash Syntax

```
modules/feed/feedUtils.js:105 → _.find(files, 'id', 'original')
```
**Fix:** Use `files.find(f => f.id === 'original')` (native array method).

---

### 4. Security Concerns

| Issue | Location | Severity | Fix |
|-------|----------|----------|-----|
| No input sanitization middleware | `server.js` | HIGH | Add `express-validator` or `joi` |
| No rate limiting | `server.js` | HIGH | Add `express-rate-limit` |
| No compression middleware | `server.js` | MEDIUM | Add `compression` package |
| Direct `process.env` access without validation | Multiple files | MEDIUM | Use `envalid` or `joi` for env validation |
| Deprecated JWT library | `helper/jwt.js` | HIGH | Replace `jwt-simple` with `jsonwebtoken` + algorithm specification |
| Deprecated AWS SDK | `helper/aws.js` | MEDIUM | Upgrade to v3 for latest security patches |
| Basic Helmet config only | `server.js:15` | MEDIUM | Configure CSP, HSTS, and other security headers |

---

### 5. Build & Config Issues

#### 5.1 ESLint Configuration

**File:** `.eslintrc.json`
- Uses older Airbnb config base
- Most rules set to warning (1) instead of error (2)
- `no-var` is only a warning — should be an error to enforce `const`/`let`
- **Fix:** Upgrade to ESLint v9+ flat config, enforce modern rules

#### 5.2 Jest Configuration

**File:** `jest.config.js`
- Coverage threshold set to only 20% lines
- Actual coverage is <1% (no real tests implemented)
- Test files are stubs
- **Fix:** Write tests, increase coverage thresholds incrementally

#### 5.3 No CI/CD Pipeline

No GitHub Actions, GitLab CI, or any CI/CD configuration found.
- **Fix:** Add CI/CD for linting, testing, and deployment

#### 5.4 No TypeScript

The entire backend is plain JavaScript with no type checking.
- **Fix:** Consider migrating to TypeScript for type safety

---

## Frontend (iOS) Analysis

**Base Path:** `HydroX - Front End - iOS/`
**Builds:** Staging (v0.1 Build 27) and Production (v1.0.1 Build 1)
**Deployment Target:** iOS 16.0
**Total Swift Files:** ~156

### 6. Outdated CocoaPods

#### CRITICAL: Alamofire 4.9

| Pod | Current in App | Latest Available | Status |
|-----|---------------|-----------------|--------|
| **Alamofire** | **4.9** | **5.x / 6.x** | **CRITICAL — 3+ major versions behind** |
| SwiftyJSON | 5.0 | 5.x | Outdated approach (use Codable) |
| SQLite.swift | 0.15 | 0.15+ | Outdated (consider GRDB or SwiftData) |
| SwiftLoader | 0.4 | 0.4 | Minimal maintenance |
| SimpleImageViewer | Git fork | N/A | Custom fork — maintenance risk |
| IQKeyboardManagerSwift | 7.0 | 7.x | Functional but outdated approach |
| BranchSDK | 3.0 | 4.x | Update available |

**Pods with Modern Versions (Good):**
- FBSDKLoginKit 17.0
- GoogleSignIn 8.0
- FirebaseCrashlytics 11.0
- FirebaseAnalytics 11.0
- SDWebImage 5.0

#### Alamofire 4.9 Impact

**26 files affected** across both builds. All use deprecated v4 API:

**ApiManager.swift** (core networking — 8 call sites):
```
Line 55: Alamofire.request("\(targetUrl)", method: .get).responseJSON
Line 73: Alamofire.request(targetUrl, method: .post, parameters: parameter).responseJSON
Line 97: Alamofire.request(targetUrl, method: .post, parameters: parameter, headers: headers).responseJSON
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

**LiveStreamingConfigurationVC.swift** (1 call site):
```
Line 304: Alamofire.request(...).responseJSON (GET - config)
```

**Breaking changes in v5:** Complete API refactor — `Alamofire.request()` becomes `AF.request()`, serializers changed, closure signatures changed.

---

### 7. Deprecated Swift/iOS APIs

#### 7.1 NSKeyedArchiver/Unarchiver — Deprecated since iOS 12

**UserDefaultHelper.swift** (both builds):
```
Lines 100-105: NSKeyedUnarchiver.unarchivedObject(ofClasses:..., from: data)
Lines 111-115: NSKeyedArchiver.archivedData(withRootObject:..., requiringSecureCoding: false)
```

**GoLiveVC.swift** (both builds):
```
Line 294 (Staging) / 298 (Production): NSKeyedUnarchiver.unarchiveObject(with: savedConfig) as? WowzaConfig
Line 314 (Staging) / 318 (Production): NSKeyedArchiver.archivedData(withRootObject: goCoderConfig)
```

**Fix:** Replace with `Codable` + `JSONEncoder`/`JSONDecoder`:
```swift
// Save
let data = try JSONEncoder().encode(config)
UserDefaults.standard.set(data, forKey: key)

// Load
let data = UserDefaults.standard.data(forKey: key)
let config = try JSONDecoder().decode(WowzaConfig.self, from: data)
```

#### 7.2 UserDefaults.synchronize() — Deprecated (no-op since iOS 12)

```
GoLiveVC.swift Line 316 (Staging) / 320 (Production): UserDefaults.standard.synchronize()
```

**Fix:** Remove these lines entirely. iOS 12+ syncs automatically.

#### 7.3 KVC: value(forKey:) / setValue(forKey:) — Type-Unsafe

**UserDefaultHelper.swift** (Lines 19, 24, 40, 57, 138):
```swift
Foundation.UserDefaults.standard.value(forKey: key) as? String
Foundation.UserDefaults.standard.setValue(sValue, forKey: key)
```

**RPCircularProgress.swift** (Lines 183, 280, 298, 446, 451):
```swift
animation.value(forKey: AnimationKeys.completionBlock) as? CompletionBlockObject
animation.setValue(completionObject, forKey: AnimationKeys.completionBlock)
```

**Fix:** Use typed property access and `Codable` patterns.

#### 7.4 Old Notification Center Pattern

**VideoViewController.swift** (Lines 35, 38, 47, 49):
```swift
NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive),
                                       name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
```

**Fix:** Use Combine-based `NotificationCenter.default.publisher(for:)` or closure-based observers.

---

### 8. Architecture Concerns

#### 8.1 Massive View Controllers (MVC Anti-pattern)

| File | Lines | Issue |
|------|-------|-------|
| `FeedViewController.swift` | **1,249** | Business logic, networking, UI, delegates all in one file |
| `GoLiveVC.swift` | **900+** | Streaming, config, networking, UI mixed together |
| `AppDelegate.swift` | **392** | Framework setup, networking, UI logic, notification routing |

**Fix:** Adopt MVVM architecture — extract ViewModels to separate business logic from UI.

#### 8.2 AppDelegate Overloaded (12 responsibilities)

**AppDelegate.swift** handles:
1. Firebase initialization
2. Database setup
3. Contact manager setup
4. Badge management
5. Background tasks
6. Deep linking setup
7. Google Sign-in setup
8. IQKeyboardManager setup
9. Push notification handling
10. Notification routing
11. Network requests in notification handlers
12. Web service calls

**Fix:** Extract into dedicated services (FirebaseService, NotificationService, DeepLinkService, etc.).

#### 8.3 100% Storyboard-based UI

5 storyboard files found, 10+ files using `instantiateViewController(withIdentifier:)`.

**Fix:** Migrate to programmatic UI or SwiftUI for new screens. Storyboards cause merge conflicts and are hard to version control.

#### 8.4 Callback-based Networking (Pyramid of Doom)

**ApiManager.swift** defines callback typedefs:
```swift
typealias ServiceResponse = (JSON, NSError?, URLResponse?) -> Void
typealias ErrorResponse = (NSError?, URLResponse?) -> Void
```

All 26+ files using ApiManager use nested callbacks.

**AppDelegate.swift** (Lines 181-200) — Network requests inside notification handlers with nested closures.

**Fix:** Adopt async/await (available since iOS 13, Swift 5.5).

---

### 9. Missing Modern iOS Features

| Feature | Status | Available Since | Impact |
|---------|--------|----------------|--------|
| **async/await** | NOT USED | iOS 13 / Swift 5.5 | All networking is callback-based |
| **@MainActor** | NOT USED | iOS 13 / Swift 5.5 | 20+ files use manual `DispatchQueue.main.async` |
| **Combine** | NOT USED | iOS 13 | No reactive data flows |
| **SwiftUI** | NOT USED | iOS 13 | 100% UIKit |
| **Structured Concurrency** | NOT USED | iOS 13 / Swift 5.5 | No `Task`, `async let`, `actor` usage |
| **Codable** | NOT USED | Swift 4 | Uses SwiftyJSON + NSKeyedArchiver |

Since the deployment target is iOS 16.0, **all of these features are available** and should be adopted.

#### Manual Thread Management (20+ locations)

All use `DispatchQueue.main.async { ... }` instead of `@MainActor`:

```
AppDelegate.swift Lines 48-50, 59-82, 250-253
FeedViewController.swift (multiple)
GoLiveVC.swift (multiple)
+ many more view controllers
```

---

### 10. Unsafe Code Patterns

#### 10.1 Force Casts (`as!`) — Crash Risk

**AppDelegate.swift:**
```
Line 178: ...as! ViewLiveVideoViewController
Line 302: (response as! HTTPURLResponse).statusCode == 200
Line 343: (response as! HTTPURLResponse).statusCode == 200
Line 370: (response as! HTTPURLResponse).statusCode == 200
```

**20+ additional locations** across view controllers with force-cast storyboard instantiation.

**Fix:** Use `as?` with `guard let` for safe unwrapping.

#### 10.2 Force Unwraps (`!`) — Crash Risk

Extensive use throughout:
```
FeedViewController.swift → self.arrfeedList![index]
AppDelegate.swift → Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
```

**Fix:** Use optional binding (`if let`, `guard let`) or provide default values.

---

### 11. Data Storage Concerns

| Storage | Current Approach | Issue | Modern Alternative |
|---------|-----------------|-------|-------------------|
| UserDefaults | KVC + NSKeyedArchiver | Type-unsafe, deprecated serialization | Codable + JSONEncoder |
| SQLite | SQLite.swift v0.15 | Outdated library | SwiftData (iOS 17+) or GRDB |
| Keychain | KeychainHelper (custom) | Well-implemented | No change needed |

---

## 12. Existing TODOs in Codebase

| File | Line | Comment |
|------|------|---------|
| `modules/feed/feedController.js` | 342-343 | TODO: Remove hidden objects |
| `modules/connection/connectionController.js` | 346 | TODO: Phone number parameter handling |

---

## Prioritized Modernization Roadmap

### Phase 1: Critical Fixes (Immediate)

**Backend:**
- [ ] Replace `request` npm package with `axios` or native `fetch`
- [ ] Replace `node-uuid` with `crypto.randomUUID()`
- [ ] Replace `jwt-simple` with `jsonwebtoken`
- [ ] Replace `q` promise library with native `Promise`
- [ ] Fix deprecated `url.parse()` calls in `helper/wowza.js`
- [ ] Fix deprecated `.remove()` Mongoose call in `modules/feed/feedUtils.js`
- [ ] Add rate limiting (`express-rate-limit`)
- [ ] Add input validation middleware

**iOS:**
- [ ] Upgrade Alamofire 4.9 → 5.x (26 files affected)
- [ ] Replace NSKeyedArchiver with Codable (4 locations)
- [ ] Remove UserDefaults.synchronize() calls (2 locations)
- [ ] Fix force casts (`as!`) to safe unwrapping (20+ locations)

### Phase 2: High Priority (1-2 Months)

**Backend:**
- [ ] Upgrade `aws-sdk` v2 → `@aws-sdk/*` v3 (modular)
- [ ] Replace `moment.js` with `date-fns` or `Day.js`
- [ ] Upgrade `mongoose` v5 → v7+
- [ ] Convert callback patterns to async/await across all controllers
- [ ] Replace `connect-multiparty` with `multer`
- [ ] Remove unnecessary `path` wrapper package

**iOS:**
- [ ] Implement async/await in ApiManager (replace callback typedefs)
- [ ] Replace SwiftyJSON with Codable protocol
- [ ] Add @MainActor to UI methods (replace 20+ DispatchQueue.main.async)
- [ ] Extract MVVM ViewModels for FeedViewController (1,249 lines) and GoLiveVC (900+ lines)
- [ ] Refactor AppDelegate into dedicated services

### Phase 3: Strategic Improvements (3-6 Months)

**Backend:**
- [ ] Migrate from CommonJS `require()` to ES Modules `import/export`
- [ ] Replace `email-templates-v2` and `nodemailer-smtp-transport` with modern alternatives
- [ ] Upgrade ESLint config — enforce `no-var` as error, adopt flat config
- [ ] Add TypeScript (gradual migration)
- [ ] Implement CI/CD pipeline (GitHub Actions)
- [ ] Write actual tests (current coverage <1%)

**iOS:**
- [ ] Migrate from Storyboards to programmatic UI for modified screens
- [ ] Adopt Combine for reactive patterns (notifications, data flows)
- [ ] Replace IQKeyboardManager with native keyboard handling
- [ ] Update SQLite.swift or migrate to SwiftData/GRDB
- [ ] Update BranchSDK 3.0 → 4.x
- [ ] Introduce SwiftUI for new screens

### Phase 4: Long-term Polish (Ongoing)

**Backend:**
- [ ] Replace `rmdir` package with native `fs.rmSync()`
- [ ] Convert all synchronous fs operations to async
- [ ] Increase test coverage thresholds progressively
- [ ] Add API documentation (upgrade Swagger/OpenAPI spec)
- [ ] Add structured logging improvements

**iOS:**
- [ ] Replace KVC patterns with typed property access
- [ ] Adopt structured concurrency (`Task`, `async let`, `actor`)
- [ ] Refactor remaining massive view controllers
- [ ] Improve test coverage (currently stub-only)
- [ ] Remove SimpleImageViewer custom fork dependency

---

## Summary Statistics

| Metric | Backend | iOS | Total |
|--------|---------|-----|-------|
| Deprecated packages/pods | 12 | 7 | 19 |
| Deprecated API usages | 15+ | 10+ | 25+ |
| Files needing modernization | 20+ | 40+ | 60+ |
| Critical severity items | 7 | 4 | 11 |
| High severity items | 5 | 6 | 11 |
| Medium severity items | 5 | 10+ | 15+ |
| Test coverage | <1% | Stubs only | Minimal |
| CI/CD pipelines | 0 | 0 | 0 |
