//
//  ProfileModel.swift
//  ITZLIT
//
//  Created by devang.bhatt on 10/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

class Profile {
    var email: String?
    var fullName: String?
    var phoneNumber: String?
    var _id: String?
    var profilePic: String?
    
    init(dictionary: [String:Any]) {
        if let email = dictionary["email"] as? String {
            self.email = email
        }
        if let fullName = dictionary["fullName"] as? String {
            self.fullName = fullName
        }
        if let phoneNumber = dictionary["phoneNumber"] as? String {
            self.phoneNumber = phoneNumber
        }
        if let _id = dictionary["_id"] as? String {
            self._id = _id
        }
        if let profilePic = dictionary["profilePic"] as? String {
            self.profilePic = profilePic
        }
    }
 }
