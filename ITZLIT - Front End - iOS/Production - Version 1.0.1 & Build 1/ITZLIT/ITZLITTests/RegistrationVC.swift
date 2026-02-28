//
//  RegistrationVC.swift
//  ITZLITTests
//
//  Created by devang.bhatt on 06/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import XCTest

extension Character {
    var isUppercase: Bool {
        guard self.asciiValue != nil else {
            return false
        }
        
        return self.asciiValue! >= Character("A").asciiValue! &&
            self.asciiValue! <= Character("Z").asciiValue!
    }
    
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.first?.value
    }
}

class RegistrationVC: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func isPWDUpperCase(pass: String) -> Bool {
         for p in pass where p.isUppercase {
           return true
        }
        return false
    }
    
    func validPassLenght(pass: String)-> Bool {
        if pass.count >= 6 {
            return true
        } else {
           return false
        }
    }
    
    
    
    func testValidatePassword() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let password = "@HElloWorld"
        
        
        let isvalid = isPWDUpperCase(pass: password) && validPassLenght(pass: password)
        print(isvalid)
//        XCTAssert(isPWDUpperCase(pass: password) == false, "Password hsould contains upper case")
//        XCTAssert(validPassLenght(pass: password) == true, "Password hsould contains atleast 6 charaters")
//        XCTAssert(isvalid, "Password not valid")
        
        XCTAssertTrue(isvalid)
    }
  
    
}
