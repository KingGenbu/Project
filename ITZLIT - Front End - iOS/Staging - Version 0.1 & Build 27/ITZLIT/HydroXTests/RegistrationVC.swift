//
//  RegistrationVC.swift
//  HydroXTests
//
//  Created by devang.bhatt on 06/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import XCTest

// MARK: - Character helpers (kept local to avoid polluting the main module)

private extension Character {
    var isUppercaseASCII: Bool {
        guard let ascii = asciiValue else { return false }
        return ascii >= Character("A").asciiValue! && ascii <= Character("Z").asciiValue!
    }

    var isLowercaseASCII: Bool {
        guard let ascii = asciiValue else { return false }
        return ascii >= Character("a").asciiValue! && ascii <= Character("z").asciiValue!
    }

    var asciiValue: UInt32? {
        return String(self).unicodeScalars.first?.value
    }
}

// MARK: - Validation helpers (mirror the rules enforced by the backend)

class RegistrationVC: XCTestCase {

    // MARK: - Password helpers

    /// Returns true if `pass` contains at least one uppercase ASCII letter.
    private func hasUppercase(_ pass: String) -> Bool {
        return pass.contains { $0.isUppercaseASCII }
    }

    /// Returns true if `pass` contains at least one lowercase ASCII letter.
    private func hasLowercase(_ pass: String) -> Bool {
        return pass.contains { $0.isLowercaseASCII }
    }

    /// Returns true if `pass` is at least 6 and at most 30 characters.
    private func isValidLength(_ pass: String) -> Bool {
        return pass.count >= 6 && pass.count <= 30
    }

    /// Combines all password rules: length, uppercase, and lowercase.
    private func isValidPassword(_ pass: String) -> Bool {
        return isValidLength(pass) && hasUppercase(pass) && hasLowercase(pass)
    }

    // MARK: - Email helper

    /// Very light email format check: must contain "@" with non-empty local and domain parts.
    private func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count == 2 else { return false }
        let domain = parts[1]
        return domain.contains(".")
    }

    // MARK: - Password length tests

    func testPasswordMinimumLength() {
        XCTAssertFalse(isValidLength("Hi1"),          "3 chars should fail minimum length")
        XCTAssertFalse(isValidLength("Hello"),         "5 chars should fail minimum length")
        XCTAssertTrue(isValidLength("Hello1"),         "6 chars should pass")
        XCTAssertTrue(isValidLength("LongPassword1"),  "13 chars should pass")
    }

    func testPasswordMaximumLength() {
        let exactly30 = String(repeating: "Aa", count: 15)   // 30 chars
        let tooLong   = String(repeating: "Aa", count: 15) + "X" // 31 chars
        XCTAssertTrue(isValidLength(exactly30), "30-char password should pass")
        XCTAssertFalse(isValidLength(tooLong),  "31-char password should fail")
    }

    // MARK: - Uppercase requirement tests

    func testPasswordRequiresUppercase() {
        XCTAssertFalse(hasUppercase("helloworld"),  "All-lowercase should fail uppercase check")
        XCTAssertFalse(hasUppercase("hello123!"),   "No uppercase letters should fail")
        XCTAssertTrue(hasUppercase("Hello"),        "Leading capital should pass")
        XCTAssertTrue(hasUppercase("hElLo"),        "Mixed case should pass")
        XCTAssertTrue(hasUppercase("HELLO"),        "All-uppercase should pass uppercase check")
    }

    // MARK: - Lowercase requirement tests

    func testPasswordRequiresLowercase() {
        XCTAssertFalse(hasLowercase("HELLOWORLD"),  "All-uppercase should fail lowercase check")
        XCTAssertTrue(hasLowercase("Hello"),        "Leading capital + lowercase should pass")
        XCTAssertTrue(hasLowercase("hElLo"),        "Mixed case should pass")
    }

    // MARK: - Combined password validation tests

    func testValidPasswordPasses() {
        XCTAssertTrue(isValidPassword("Hello1"),        "Valid password should pass")
        XCTAssertTrue(isValidPassword("@HElloWorld"),   "Password with special chars should pass")
        XCTAssertTrue(isValidPassword("MyPass99"),      "Alphanumeric mixed-case should pass")
    }

    func testInvalidPasswordFails() {
        XCTAssertFalse(isValidPassword("hi"),          "Too short, no uppercase → fail")
        XCTAssertFalse(isValidPassword("helloworld"),  "No uppercase → fail")
        XCTAssertFalse(isValidPassword("HELLOWORLD"),  "No lowercase → fail")
        XCTAssertFalse(isValidPassword("Hello"),       "5 chars (too short) → fail")
        XCTAssertFalse(isValidPassword(""),            "Empty string → fail")
    }

    func testPasswordEdgeCases() {
        // Exactly 6 chars with both cases
        XCTAssertTrue(isValidPassword("aB1234"))
        // Exactly 6 chars but all lowercase
        XCTAssertFalse(isValidPassword("abcdef"))
        // Password with only digits (no letters at all)
        XCTAssertFalse(isValidPassword("123456"))
    }

    // MARK: - Email validation tests

    func testValidEmailPasses() {
        XCTAssertTrue(isValidEmail("user@example.com"))
        XCTAssertTrue(isValidEmail("test.name+tag@sub.domain.org"))
    }

    func testInvalidEmailFails() {
        XCTAssertFalse(isValidEmail("notanemail"),    "No @ symbol → fail")
        XCTAssertFalse(isValidEmail("@nodomain"),     "Empty local part → fail")
        XCTAssertFalse(isValidEmail("user@"),         "No domain → fail")
        XCTAssertFalse(isValidEmail(""),              "Empty string → fail")
        XCTAssertFalse(isValidEmail("user@nodot"),    "Domain without dot → fail")
    }
}
