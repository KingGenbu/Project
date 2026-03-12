//
//  AppDelegate.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 24/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import GoogleSignIn
import UserNotifications
import Branch
import IQKeyboardManagerSwift
import FirebaseCore
import SimpleImageViewer

enum NotificationType : String {

    case typeFollow = "Follow"
    case typeIsLive = "IsLive"
    case typeWasLive = "WasLive"
    case typeStory = "ShareStory"
    case itzlitDone = "ItzlitDone"
    case goLiveReq = "GoLiveReq"
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var arrFeedDetail = FeedDetailModel()
    var branch = Branch.getInstance()

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        DBManager.shared.copyDatabaseIfNeeded()
        ContactManager.shared.setUpcontactUpdateNotify()
        application.applicationIconBadgeNumber = 0

        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) &&
            (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            DispatchQueue.global(qos: .background).async {
                ContactManager.shared.setUpContactToDbWith(Loader: false, onCompletion: { _ in })
            }
            DispatchQueue.main.async {
                Helper.WSGetProfileCalled()
            }
            self.getUTCDateTime()
        }

        // Check if launched from a remote notification tap
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            self.notificationData(userInfo: notification)
        }

        DispatchQueue.main.async {
            if UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id) == nil {
                self.WSCreateDeviceId(onCompletionHandler: { isSucess in
                    if isSucess {
                        let center = UNUserNotificationCenter.current()
                        center.delegate = self
                        center.requestAuthorization(options: [.sound, .alert, .badge]) { granted, error in
                            guard error == nil else { return }
                            if granted {
                                DispatchQueue.main.async {
                                    application.registerForRemoteNotifications()
                                }
                            } else {
                                print("Push notifications denied")
                            }
                        }
                    }
                })
            } else {
                if UserDefaultHelper.getPREF(AppUserDefaults.pref_device_token) != nil {
                    self.WSDeviceUpdate()
                }
            }
        }

        UNUserNotificationCenter.current().delegate = self
        self.setupGoogleSignIn()

        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true

        branch?.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { params, error in
            if error == nil, let parameter = params as? [String: Any],
               let otpNumber = parameter["otp"] as? String {
                self.WSVerifyMobileNumber(otpNumber)
            } else if let error = error {
                print("Branch io error: ", error.localizedDescription)
            }
        })

        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)

        return true
    }

    // MARK: - UISceneSession lifecycle (iOS 13+)

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    // MARK: - URL handling

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.scheme == ApiManager.branchScheme {
            return Branch.getInstance().application(app, open: url, options: options)
        } else if url.scheme == ApiManager.fbUrlScheme {
            return ApplicationDelegate.shared.application(app, open: url, options: options)
        } else {
            return GIDSignIn.sharedInstance.handle(url)
        }
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
        return true
    }

    // MARK: - Push notifications

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let strDevicetoken = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
        print("strDevicetoken", strDevicetoken)
        UserDefaultHelper.setPREF(strDevicetoken, key: AppUserDefaults.pref_device_token)
        self.WSDeviceUpdate()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String: Any] {
            self.notificationData(userInfo: userInfo)
        }
    }

    // MARK: - Notification routing

    func notificationData(userInfo: [String: Any]) {
        // Resolve the root view controller from the active scene window
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController

        guard let type = userInfo["type"] as? String else { return }

        if type == NotificationType.typeFollow.rawValue {
            // No navigation required for follow notifications

        } else if type == NotificationType.typeIsLive.rawValue {
            let viewliveVideoVC = Helper.settingFeedStoryBoard
                .instantiateViewController(withIdentifier: StoryboardIdentefier.viewLiveVideoVC.rawValue)
                as! ViewLiveVideoViewController
            if let extrasDict = userInfo["extras"] as? [String: Any],
               let feedId = extrasDict["feed"] as? String {
                ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.feedDetails + feedId,
                onComplete: { json, error, response in
                    guard error == nil, (response as? HTTPURLResponse)?.statusCode == 200 else {
                        print("error:", error?.localizedDescription ?? "error")
                        return
                    }
                    if let arrJsonFeedDetails = json.dictionaryObject?["doc"] as? [[String: Any]] {
                        if self.arrFeedDetail.arrFeedDetails == nil {
                            self.arrFeedDetail.arrFeedDetails = []
                        }
                        for item in arrJsonFeedDetails {
                            self.arrFeedDetail.arrFeedDetails.append(FeedDetail(values: item))
                        }
                        viewliveVideoVC.arrFeedDetail = self.arrFeedDetail.arrFeedDetails
                        let nav = UINavigationController(rootViewController: viewliveVideoVC)
                        rootVC?.present(nav, animated: true)
                    }
                }, onError: { error, _ in
                    print("error:", error?.localizedDescription ?? "error")
                })
            }

        } else if type == NotificationType.goLiveReq.rawValue {
            let navController = rootVC as? UINavigationController
            let liveStreamingConfig = Helper.settingFeedStoryBoard
                .instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue)
                as! LiveStreamingConfigurationVC
            navController?.pushViewController(liveStreamingConfig, animated: true)

        } else if type == NotificationType.typeStory.rawValue {
            if let extrasDict = userInfo["extras"] as? [String: Any],
               let feedId = extrasDict["feed"] as? String {
                ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.feedDetails + feedId,
                onComplete: { json, error, response in
                    guard error == nil, (response as? HTTPURLResponse)?.statusCode == 200 else {
                        print("error:", error?.localizedDescription ?? "error")
                        return
                    }
                    if let arrJsonFeedDetails = json.dictionaryObject?["doc"] as? [[String: Any]] {
                        self.arrFeedDetail.arrFeedDetails = []
                        for item in arrJsonFeedDetails {
                            self.arrFeedDetail.arrFeedDetails.append(FeedDetail(values: item))
                        }
                        guard let feedDetail = self.arrFeedDetail.arrFeedDetails.last else { return }
                        let ownerDetails = owner(name: feedDetail.userFullName ?? "",
                                                 image: #imageLiteral(resourceName: "img_profile"),
                                                 originalImage: feedDetail.userProfilePic ?? "")
                        var arrFeeds = [feed]()
                        let feedCon = feedContant { feeds in
                            let createdDate = Date().getDifferanceFromCurrentTime(serverDate: feedDetail.createdAt! as Date!)
                            let storyMedia = feed(seenStoryId: "", thumbId: "", thumb: "",
                                                  orignalMedia: (feedDetail.mediaDict?.path)!,
                                                  feedId: "", time: createdDate, discription: "",
                                                  lits: "", comments: "",
                                                  mediaType: feedDetail.feedType == StoryType.storyImage.rawValue ? .image : .video,
                                                  owner: ownerDetails, type: .none,
                                                  duration: (feedDetail.mediaDict?.duration)!,
                                                  viewers: 0, branchLink: feedDetail.branchLink ?? "",
                                                  masterIndex: nil, index: nil,
                                                  individualFeedType: individualFeedType(rawValue: feedDetail.feedType!)!,
                                                  privacyLevel: privacyLevel(rawValue: feedDetail.privacyLevel!)!)
                            arrFeeds.append(storyMedia)
                            feeds.feedList = arrFeeds
                            feeds.bottomtype = .none
                            feeds.feedType = .story
                            feeds.owner = ownerDetails
                            feeds.turnSoket = false
                        }
                        let configuration = ImageViewerConfiguration { _ in }
                        DispatchQueue.main.async {
                            rootVC?.present(ImageViewerController(configuration: configuration, contant: feedCon),
                                            animated: true)
                        }
                    }
                }, onError: { error, _ in
                    print("error:", error?.localizedDescription ?? "error")
                })
            }
        }
    }

    // MARK: - Google Sign-In setup

    func setupGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    // MARK: - Local data flush

    func getUTCDateTime() {
        if Date().getCurrentUTCDateTime() >= Date().getFlushUTCDateTime() {
            if let prefDate = UserDefaults.standard.object(forKey: "pref_date_golive") as? Date {
                if Date().getFlushUTCDateTime() >= prefDate {
                    DBManager.shared.clearStoryDetailTable()
                }
            }
        }
    }

    // MARK: - Web services

    func WSCreateDeviceId(onCompletionHandler: ((_ isSucess: Bool) -> ())?) {
        let timeZone = TimeZone.current.abbreviation()
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let bundleID = Bundle.main.bundleIdentifier
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let deviceToken = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_token) ?? ""
        let parameter: [String: Any] = [
            WebserviceRequestParmeterKey.timeZone: timeZone!,
            WebserviceRequestParmeterKey.deviceType: "ios",
            WebserviceRequestParmeterKey.appName: appName,
            WebserviceRequestParmeterKey.appIdentifier: bundleID!,
            WebserviceRequestParmeterKey.appVersion: appVersion,
            WebserviceRequestParmeterKey.appBuildNumber: appBuildNumber,
            WebserviceRequestParmeterKey.deviceToken: deviceToken,
        ]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.createDevice, parameter: parameter,
        onCompletion: { json, error, response in
            if error == nil, (response as! HTTPURLResponse).statusCode == 200,
               let deviceID = json.dictionaryObject?["deviceId"] as? String {
                print("Create Device ID:", deviceID)
                UserDefaultHelper.setPREF(deviceID, key: AppUserDefaults.pref_device_id)
                UserDefaultHelper.setBoolPREF(true, key: AppUserDefaults.pref_notification)
                onCompletionHandler?(true)
            }
            Helper.hideProgressBar()
        }) { error, _ in
            onCompletionHandler?(false)
            print(error ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }

    func WSDeviceUpdate() {
        let timeZone = TimeZone.current.abbreviation()
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let bundleID = Bundle.main.bundleIdentifier
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let deviceToken = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_token)
        let deviceID = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)
        let parameter: [String: Any] = [
            WebserviceRequestParmeterKey.timeZone: timeZone!,
            WebserviceRequestParmeterKey.deviceType: "ios",
            WebserviceRequestParmeterKey.appName: appName,
            WebserviceRequestParmeterKey.appIdentifier: bundleID!,
            WebserviceRequestParmeterKey.appVersion: appVersion,
            WebserviceRequestParmeterKey.appBuildNumber: appBuildNumber,
            WebserviceRequestParmeterKey.deviceToken: deviceToken!,
            WebserviceRequestParmeterKey.deviceId: deviceID!,
        ]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.updateDevice, parameter: parameter,
        onCompletion: { json, error, response in
            if error == nil {
                print(json)
                if (response as! HTTPURLResponse).statusCode == 200,
                   let deviceID = json.dictionaryObject?["deviceId"] as? String {
                    print("Update Device ID:", deviceID)
                    UserDefaultHelper.setPREF(deviceID, key: AppUserDefaults.pref_device_id)
                }
            }
            Helper.hideProgressBar()
        }) { error, _ in
            print(error ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }

    func WSVerifyMobileNumber(_ otpNumber: String) {
        Helper.showProgressBar()
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController

        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.verifyMobileNumber + otpNumber,
        onComplete: { json, error, response in
            print("Verify mobile number ws called")
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200,
                   let verifiedMessage = json.dictionaryObject?["msg"] as? String {
                    Helper.WSGetProfileCalled()
                    Helper.showAlertDialog(APP_NAME, message: verifiedMessage, clickAction: {
                        (rootVC as? UINavigationController)?.popToRootViewController(animated: false)
                    })
                }
                if let errorMessage = json.dictionaryObject?["error"] as? String {
                    Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                    Helper.hideProgressBar()
                    return
                }
            } else {
                print("Verify mobile number:", error?.localizedDescription ?? "error")
            }
            Helper.hideProgressBar()
        }) { error, _ in
            print("Verify mobile number:", error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
        }
    }
}
