//
//  ILConst.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 24/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

enum StoryboardIdentefier:String {
    case home = "SBIDHomeVC"
    case login = "SBIDLoginVC"
    case registration = "SBIDRegistration"
    case contact = "SBIDContactVC"
    case notification = "SBIDNotification"
    case sendTo = "SBIDSendToVC"
    case profile = "SBIDProfileVC"
    case story = "StoryCapture"
    case Photo = "PhotoViewController"
    case video = "VideoViewController"
    case storyInterface = "SBIDStoryInterfaceVC"
    case shareStory = "SBIDShareStory"
    case comment = "SBIDFeedCommentVC"
    case removeItzlitFriend = "SDIDRemoveItzlitFriendVC"
    case storyHistory = "StoryHistoryVC"
    case resendOTP = "SBIDResendOTPVC"
    case forgetPassword = "SBIDForgetPassword"
    case searchItzlitFriendsVC = "SBIDSearchItzlitFriendsVC"
    case settingsVC = "SBIDSettingsVC"
    case liveStreamingConfigurationVC = "SBIDLiveStreamingConfiguration"
    case termsAndPrivacyVC = "SBIDTermsAndPrivacyVC"
    case feedVC = "SBIDFeedVC"
    case requestList = "RequestListViewController"
    case goLive = "SBIDGoLiveVC"
    case viewLiveVideoVC = "ViewLiveVideoVC"
}

enum CellIdentifier: String {
    case contactCell = "contactCell"
    case sendToCell = "sendToCell"
    case cellRemoIzlitFriends = "cellRemoIzlitFriends"
    case globalSearchCell = "globalSearchCell"
    case notificationCell = "notificationCell"
    case feedHeaderCell = "FeedHeaderCell"
    case feedCellOld = "FeedCellOld"
    case feedCell = "FeedCell"
    case listUser  = "ListUser"
    case  feedCollection = "FeedCollectionViewCell"
    case feedCommentCell = "feedCommentCell"
}

//MARK:- Return the screen size
struct ScreenSize {
    static let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}
enum ViewControllerTitle: String {
    case commentsList = "C O M M E N T S"
    case viewList = "V I E W S"
    case requestList = "R E Q U E S T S"
    case notification = "N O T I F I C A T I O N S"
    case contactITZLITFriends = "ITZLIT FRIENDS"
    case sendTo = "S e n d  t o..."
    case profile = "M Y  P R O F I L E"
    case searchGlobal = "I T Z L I T  F R I E N D S"
    case signIn = "S I G N  I N"
    case signUp = "S I G N   U P"
    case settings = "S E T T I N G S"
    case liveStreaming = "L I V E  S T R E A M I N G"
    case privacyPolicy = "P R I V A C Y  P O L I C Y"
    case termOfUse = "T E R M S  O F  U S E"
    case feed = "S O C I A L  F E E D"
    case live = "L I V E"
}

enum MenuTitle : String {
    case home = "Home"
    case login = "Login"
    case signUp = "Sign Up"
    case inviteFriends = "Invite Friends"
    case myProfile = "My Profile"
    case support = "Support"
    case settings = "Settings"
    case termsOfUse = "Terms of Use"
    case privacyPolicy = "Privacy Policy"
    case logout = "Logout"
    case cancel = "Cancel"
}
