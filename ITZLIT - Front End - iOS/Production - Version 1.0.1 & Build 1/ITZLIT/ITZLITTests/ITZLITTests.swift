//
//  ITZLITTests.swift
//  ITZLITTests
//
//  Created by devang.bhatt on 06/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import XCTest

/// Smoke-test suite. Each area gets its own dedicated test file; this file
/// verifies that the test bundle itself boots correctly and provides a home
/// for cross-cutting checks that don't belong to a single feature.
class ITZLITTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Bundle sanity

    /// Ensures the test host application launched without crashing.
    func testTestBundleLoads() {
        XCTAssertNotNil(Bundle.main.bundleIdentifier,
                        "Main bundle should have a bundle identifier")
    }

    // MARK: - Date / time utilities (used throughout the app)

    func testDateComparisonFutureIsLater() {
        let now = Date()
        let future = Date(timeIntervalSinceNow: 3600)
        XCTAssertTrue(future > now, "A date one hour from now should be later than now")
    }

    func testDateComparisonPastIsEarlier() {
        let now = Date()
        let past = Date(timeIntervalSinceNow: -3600)
        XCTAssertTrue(past < now, "A date one hour ago should be earlier than now")
    }

    // MARK: - String utilities relied on by multiple view controllers

    func testTrimmingWhitespaceProducesNonEmptyResult() {
        let padded = "  hello world  "
        XCTAssertEqual(padded.trimmingCharacters(in: .whitespaces), "hello world")
    }

    func testTrimmingWhitespaceOnlyStringProducesEmpty() {
        let spaces = "   "
        XCTAssertTrue(spaces.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func testStringIsEmptyAfterTrim() {
        XCTAssertTrue("".trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
