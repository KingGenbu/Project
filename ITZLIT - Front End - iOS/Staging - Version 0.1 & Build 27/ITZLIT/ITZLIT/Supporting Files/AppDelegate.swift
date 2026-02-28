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
import Google
import UserNotifications
import Branch
import IQKeyboardManagerSwift
import Fabric
import Crashlytics
import SimpleImageViewer

enum NotificationType : String {
    
    case typeFollow = "Follow"
    case typeIsLive = "IsLive"
    case typeWasLive = "WasLive"
    case typeStory = "ShareStory"
    case itzlitDone = "ItzlitDone"
    case goLiveReq = "GoLiveReq"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    lazy var configuration = Configuration()
    var arrFeedDetail = FeedDetailModel()
    var branch = Branch.getInstance()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        DBManager.shared.copyDatabaseIfNeeded()
        ContactManager.shared.setUpcontactUpdateNotify()
        application.applicationIconBadgeNumber = 0
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            
            DispatchQueue.global(qos: .background).async {
                ContactManager.shared.setUpContactToDbWith(Loader: false, onCompletion: {(refresh) in
                })
                
            }
            DispatchQueue.main.async {
                Helper.WSGetProfileCalled()
            }
            self.getUTCDateTime()
        }
        
        // Check if launched from notification
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            self.notificationData(userInfo: notification)
        }
        
        DispatchQueue.main.async {
            if UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id) == nil {
                self.WSCreateDeviceId(onCompletionHandler: { (isSucess) in
                    if isSucess {
                        if #available(iOS 10.0, *) {
                            let center  = UNUserNotificationCenter.current()
                            center.delegate = self
                            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                                if error == nil{
                                    if granted {
                                        DispatchQueue.main.async {
                                            application.registerForRemoteNotifications()
                                        }
                                    } else{
                                        print("denied")
                                    }
                                }
                            }
                        } else{
                            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound], completionHandler: { (granted, error) in
                                if granted {
                                    print("ios 11 Granted")
                                    application.registerForRemoteNotifications()
                                } else {
                                    print("Denied")
                                }
                            })
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
        
        // IQ library enbled
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        IQKeyboardManager.sharedManager().shouldResignOnTouchOutside = true
        
        branch?.initSession(launchOptions: launchOptions, andRegisterDeepLinkHandler: { (params, error) in
            if error == nil {
                if let parameter = params as? [String:Any] {
                    //    print("Branch IO params: ",params as? [String:Any] ?? "no params")
                    if let otpNumber = parameter["otp"] as? String {
                        self.WSVerifyMobileNumber(otpNumber)
                    }
                }
            } else {
                print("Branch io error:  ",error?.localizedDescription ?? "error")
            }
        })
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        UIApplication.shared.isStatusBarHidden = false
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == ApiManager.branchScheme  {
            return Branch.getInstance().application(app, open: url, options: options)
        } else if url.scheme == ApiManager.fbUrlScheme  {
            return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        }  else {
            let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String
            let annotation = options[UIApplicationOpenURLOptionsKey.annotation]
            return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        ILSocketManager.shared.pauseConnection()
    }
    
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
//         Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ILSocketManager.shared.resumeConnection()
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        if UIApplication.shared.applicationState == .active {
//            if let userInfo = notification.request.content.userInfo as? [String:Any] {
//                self.notificationData(userInfo: userInfo)
//            }
//        }
        completionHandler([.alert, .badge, .sound])
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let strDevicetoken = deviceToken.reduce("", {($0 + String(format: "%02X", $1))})
        print("strDevicetoken", strDevicetoken)
        UserDefaultHelper.setPREF(strDevicetoken, key: AppUserDefaults.pref_device_token)
        self.WSDeviceUpdate()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String:Any] {
            self.notificationData(userInfo: userInfo)
        }
    }
    
    func notificationData(userInfo: [String: Any]) {
        if let userNotificationDict = userInfo as [String: Any]? {
            if let type = userNotificationDict["type"] as? String{
                if type == NotificationType.typeFollow.rawValue {
                    
                } else if type == NotificationType.typeIsLive.rawValue {
                    let viewliveVideoVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.viewLiveVideoVC.rawValue) as! ViewLiveVideoViewController
                    if let extrasDict = userNotificationDict["extras"] as? [String:Any] {
                        if let feedId = extrasDict["feed"] as? String {
                            ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.feedDetails + feedId, onComplete: { (json, error, response) in
                                if error == nil {
                                    if (response as? HTTPURLResponse)?.statusCode == 200 {
                                        
                                        if let arrJsonFeedDetails = json.dictionaryObject!["doc"] as? [[String:Any]] {
                                            
                                            if self.arrFeedDetail.arrFeedDetails == nil {
                                                self.arrFeedDetail.arrFeedDetails = []
                                            }
                                            
                                            var feedDetail = FeedDetail(values: [:])
                                            
                                            for feedDetailItem in arrJsonFeedDetails {
                                                feedDetail = FeedDetail(values: feedDetailItem)
                                                self.arrFeedDetail.arrFeedDetails.append(feedDetail)
                                            }
                                            
                                            viewliveVideoVC.arrFeedDetail = self.arrFeedDetail.arrFeedDetails
                                            
                                            let navController = UINavigationController(rootViewController: viewliveVideoVC)
                                            self.window?.rootViewController?.present(navController, animated: true, completion: nil)
                                        }
                                    } else {
                                        print("error:", error?.localizedDescription ?? "error")
                                    }
                                } else {
                                    print("error:", error?.localizedDescription ?? "error")
                                }
                            }, onError: { (error, response) in
                                print("error:", error?.localizedDescription ?? "error")
                            })
                        }
                    }
                } else if type == NotificationType.goLiveReq.rawValue {
                    
                    let rootViewController = self.window?.rootViewController as?
                    UINavigationController
                     let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
                    rootViewController?.pushViewController(liveStreamingConfig, animated: true)

                 } else if type == NotificationType.typeStory.rawValue {
                    if let extrasDict = userNotificationDict["extras"] as? [String:Any] {
                        if let feedId = extrasDict["feed"] as? String {
                            ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.feedDetails + feedId, onComplete: { (json, error, response) in
                                if error == nil {
                                    if (response as? HTTPURLResponse)?.statusCode == 200 {
                                        
                                        if let arrJsonFeedDetails = json.dictionaryObject!["doc"] as? [[String:Any]] {
                                            
                                            self.arrFeedDetail.arrFeedDetails = []
                                            
                                            
                                            var feedDetail = FeedDetail(values: [:])
                                            
                                            for feedDetailItem in arrJsonFeedDetails {
                                                feedDetail = FeedDetail(values: feedDetailItem)
                                                self.arrFeedDetail.arrFeedDetails.append(feedDetail)
                                            }
                                            
                                            let ownerDetails = owner(name: feedDetail.userFullName ?? "", image: #imageLiteral(resourceName: "img_profile"), originalImage: feedDetail.userProfilePic ?? "")
                                            var arrFeeds = [feed]()
                                            let feedCon = feedContant { (feeds) in
                                       
                                                
                                                let createdDate = Date().getDifferanceFromCurrentTime(serverDate: feedDetail.createdAt!  as Date!)
                                                
                                                let storyMedia = feed(seenStoryId: "", thumbId: "", thumb: "", orignalMedia:  (feedDetail.mediaDict?.path)!, feedId: "", time: createdDate, discription: "", lits: "", comments: "", mediaType: (feedDetail.feedType == StoryType.storyImage.rawValue ? mediaType.image : mediaType.video ), owner: ownerDetails, type: .none, duration: (feedDetail.mediaDict?.duration)!, viewers: 0, branchLink: feedDetail.branchLink ?? "", masterIndex: nil, index: nil, individualFeedType: individualFeedType.init(rawValue: feedDetail.feedType!)!, privacyLevel: privacyLevel(rawValue: feedDetail.privacyLevel!)!)
                                                
                                                arrFeeds.append(storyMedia)
                                                
                                                feeds.feedList = arrFeeds
                                                feeds.bottomtype = .none
                                                feeds.feedType = .story
                                                feeds.owner = ownerDetails
                                                feeds.turnSoket =  false
                                            }
                                            
                                            
                                            let configuration = ImageViewerConfiguration { config in
                                            }
                                            DispatchQueue.main.async {
                                                self.window?.rootViewController?.present(ImageViewerController(configuration: configuration, contant: feedCon), animated: true, completion: nil)
                                            }
                                        }
                                        
                                    } else {
                                        print("error:", error?.localizedDescription ?? "error")
                                    }
                                } else {
                                    print("error:", error?.localizedDescription ?? "error")
                                }
                            }, onError: { (error, response) in
                                print("error:", error?.localizedDescription ?? "error")
                            })
                        }
                    }
                }
            }
        }
    }
    
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        if let userInfo = userInfo as? [String:Any] {
//            self.notificationData(userInfo: userInfo)
//        }
//    }
    
    /// configure google sign in
    func setupGoogleSignIn() {
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
    }
    
    /// MARK: Flush Local store data of go live requested from story detail screen.
    func getUTCDateTime() {
        if Date().getCurrentUTCDateTime() >= Date().getFlushUTCDateTime() {
            if let prefDate = UserDefaults.standard.object(forKey: "pref_date_golive") as? Date {
                if Date().getFlushUTCDateTime() >= prefDate {
//                    print("Flush story detail table")
                    DBManager.shared.clearStoryDetailTable()
                }
            }
        }
    }
    
    // WS create device id called
    func WSCreateDeviceId(onCompletionHandler: ((_ isSucess:Bool) -> ())?) {
        
        let timeZone = TimeZone.current.abbreviation()
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let bundleID = Bundle.main.bundleIdentifier
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let deviceToken = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_token) ?? ""
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.timeZone: timeZone!,
                                        WebserviceRequestParmeterKey.deviceType: "ios",
                                        WebserviceRequestParmeterKey.appName : appName,
                                        WebserviceRequestParmeterKey.appIdentifier: bundleID!,
                                        WebserviceRequestParmeterKey.appVersion: appVersion,
                                        WebserviceRequestParmeterKey.appBuildNumber: appBuildNumber,
                                        WebserviceRequestParmeterKey.deviceToken: deviceToken ]
        
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.createDevice, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let deviceID = json.dictionaryObject!["deviceId"] as? String {
                        print("Create Device ID:", deviceID)
                        UserDefaultHelper.setPREF(deviceID, key: AppUserDefaults.pref_device_id)
                        UserDefaultHelper.setBoolPREF(true, key: AppUserDefaults.pref_notification)
                        onCompletionHandler!(true)
                    }
                }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            onCompletionHandler!(false)
            print(error ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    /// Web service Device update called
    func WSDeviceUpdate() {
        let timeZone = TimeZone.current.abbreviation()
        let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let bundleID = Bundle.main.bundleIdentifier
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuildNumber = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        let deviceToken = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_token)
        let deviceID = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)
        
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.timeZone: timeZone!,
                                        WebserviceRequestParmeterKey.deviceType: "ios",
                                        WebserviceRequestParmeterKey.appName : appName,
                                        WebserviceRequestParmeterKey.appIdentifier: bundleID!,
                                        WebserviceRequestParmeterKey.appVersion: appVersion,
                                        WebserviceRequestParmeterKey.appBuildNumber: appBuildNumber,
                                        WebserviceRequestParmeterKey.deviceToken: deviceToken!,
                                        WebserviceRequestParmeterKey.deviceId: deviceID! ]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.updateDevice, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                print(json)
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let deviceID = json.dictionaryObject!["deviceId"] as? String {
                        print("Update Device ID:", deviceID)
                        UserDefaultHelper.setPREF(deviceID, key: AppUserDefaults.pref_device_id)
                    }
                }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    /// WS Verify Mobile Number called
    func WSVerifyMobileNumber(_ otpNumber: String) {
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.verifyMobileNumber + otpNumber, onComplete: { (json, error, response) in
            print("Verify mobile number ws called")
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let verifiedMessage = json.dictionaryObject!["msg"] as? String {
                        Helper.WSGetProfileCalled()
                        Helper.showAlertDialog(APP_NAME, message: verifiedMessage, clickAction: {
                            (self.window?.rootViewController as? UINavigationController)?.popToRootViewController(animated: false)
                        })
                    }
                }
                if let errorMessage = json.dictionaryObject!["error"] as? String {
                    Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                    Helper.hideProgressBar()
                    return
                }
                if (response as! HTTPURLResponse).statusCode == 400 {
                    let resendOTPVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.resendOTP.rawValue) as! ResendOTPVC
                    if self.window?.rootViewController != resendOTPVC {
                        //      let navController = UINavigationController(rootViewController: resendOTPVC)
                        //     Helper.Push_Pop_to_ViewController(destinationVC: resendOTPVC, isAnimated: true, navigationController: navController)
                    }
                }
            } else {
                print("Verify mobile number :",error?.localizedDescription ?? "error")
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print("Verify mobile number :",error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
        }
    }
}

