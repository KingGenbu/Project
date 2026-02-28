//
//  MessageConst.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 24/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

enum App : String {
    case fbButtonTitle = "Login with Facebook"
}

enum ValidationMessage: String {
    case emptyProfilePicture = "Please select profile picture."
    case emptyFullName = "Please enter full name."
    case emptyEmailAdress = "Please enter email address."
    case invalidEmailAddress = "Please enter valid email address."
    case emptyMobileNumber = "Please enter mobile number."
    case emptyPassword = "Please enter password."
    case validPassword = "Password must be at least 6 letters long, contain a capital letter and contain a lowercase letter."
    case passwordLength = "Please enter password of minimum 6 charaters."
    case emptyConfirmPassword = "Please enter confirm password."
    case mismatchPasswordAndConfPassword = "Password and confirm password does not match."
    case validMobileNumber = "Please enter valid mobile number."
    
    case currentPass = "Please enter current password."
    case newPass = "Please enter new password."
    case mismatchNewPasswordAndConfPassword = "New Password and confirm password does not match."
    case selectUser = "Please select at least one user"
    case videoLength = "Video length should be atleast 3 seconds."
    case inValidOptionToGoLive = "Please select atleast one option to go live."
    case liveVideoLength = "Live video must be 4 seconds in length."
 }

enum AppMessage: String {
    case verifyMessage = "Please verify your mobile number by clicking the link that you have recieved via sms."
    case verifyLoginMessage = "Please login to continue."
    case logoutMessage = "Are you sure you want to logout?"
    case publicText = "Your post will be published on social feed."
    case noContactFound = "No contact found."
    case notNotificationFound = "No notifications found."
    case internetConnectionOffline = "The Internet connection appears to be offline."
    case enterComment = "Please enter Comment"
    case noFeedFound = "Your friends Live stream & Story will appear here."
    case storyRemoved = "Oops! Seems this story was removed."
    case liveStreamRemoved = "Oops! Seems this live stream was removed."
 }
