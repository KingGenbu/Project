//
//  SettingsViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 24/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleAPIClientForREST
import GoogleSignIn

class SettingsViewController: UIViewController {
    
    @IBOutlet var vwAccount: UIView!
    @IBOutlet var vwPushNotification: UIView!
    
    @IBOutlet var switchFB: UISwitch!
    @IBOutlet var switchYouTube: UISwitch!
    @IBOutlet var switchNotification: UISwitch!
    @IBOutlet weak var lblVersionBuild: UILabel!
    
    var fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
    var gidSignIn = GIDSignIn.sharedInstance()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let strVersionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, let strBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            self.lblVersionBuild.text = "Version: " + strVersionNumber + "," + " Build: " + strBuildNumber
        }
        self.configureNotificationFacebookAndGoogleSignInSwitchValue()
        
        self.configureGoogleSignIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Configure UI
    func configureUI() {
         self.title = ViewControllerTitle.settings.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton
        
         navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        statusBar.tintColor = .white
        
        self.vwAccount.dropShadow(scale: true)
        self.vwPushNotification.dropShadow(scale: true)
    }
    
    /// Navigation left bar button action method
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    /// Configure user's switch values for Notification, Google and Facebook switch
    func configureNotificationFacebookAndGoogleSignInSwitchValue() {
        if UserDefaultHelper.getPREF(AppUserDefaults.fb_Token) != nil {
            self.switchFB.setOn(true, animated: false)
        } else {
            self.switchFB.setOn(false, animated: false)
        }
        
        if UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken) != nil {
            self.switchYouTube.setOn(true, animated: false)
        } else {
            self.switchYouTube.setOn(false, animated: false)
        }
        
        if UserDefaultHelper.getPREF(AppUserDefaults.pref_notificationPref) == "Yes" || UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_notification) == true {
            self.switchNotification.setOn(true, animated: false)
        } else {
            self.switchNotification.setOn(false, animated: false)
        }
    }
    
    // Configure Google Sign-in.
    func configureGoogleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeYouTube, kGTLRAuthScopeYouTubeForceSsl]
        GIDSignIn.sharedInstance().clientID = ApiManager.ytClientID
    }
    
    /// Action method for Facebook Switch
    @IBAction func switchFBTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.switchFB.setOn(false, animated: false)
            self.FBSignIn(onCompletionHandler: {isSucess in
                if isSucess {
                    let token = FBSDKAccessToken.current().tokenString
//                    print("FBToken", token ?? "")
                    UserDefaultHelper.setPREF(token!, key: AppUserDefaults.fb_Token)
                    self.switchFB.setOn(true, animated: true)
                }
            })
        } else {
            self.FBLogOut()
        }
    }
    
    /// Action method for YouTube Switch
    @IBAction func switchYouTubeTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.switchYouTube.setOn(false, animated: false)
            gidSignIn?.signIn()
        } else {
            gidSignIn?.signOut()
            gidSignIn?.disconnect()
        }
    }
    
    /// Action method for Push notification Switch
    @IBAction func switchPushNotificationTapped(_ sender: UISwitch) {
        if sender.isOn {
            let isRegisteredForRemoteNotification = UIApplication.shared.isRegisteredForRemoteNotifications
            if isRegisteredForRemoteNotification {
                self.WSUpdateNotificationPref("Yes")
            } else {
                self.switchNotification.setOn(false, animated: false)
                Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: "Allow access for notification from settings", button1Title: "Cancel", button1ActionStyle: UIAlertActionStyle.default, button2Title: "Settings", onButton1Click: nil, onButton2Click: {
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: { (success) in
                            if success {
//                                print("Settings opened: \(success)") // Prints true
                            }
                        })
                    }
                })
            }
            
        } else {
            let isRegisteredForRemoteNotification = UIApplication.shared.isRegisteredForRemoteNotifications
            if isRegisteredForRemoteNotification {
                self.WSUpdateNotificationPref("No")
            } else {
                self.switchNotification.setOn(false, animated: false)
                Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: "Allow access for notification from settings", button1Title: "Cancel", button1ActionStyle: UIAlertActionStyle.default, button2Title: "Settings", onButton1Click: nil, onButton2Click: {
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: { (success) in
                            if success {
//                                print("Settings opened: \(success)") // Prints true
                            }
                        })
                    }
                })
            }
         }
    }
    
    /// WS called to configure notification switch
    func WSUpdateNotificationPref(_ strNotificationPref: String) {
        
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.notificationPref: strNotificationPref, WebserviceRequestParmeterKey.deviceId : UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)!]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.notificationPref, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if strNotificationPref == "Yes" {
                        UserDefaultHelper.setPREF(strNotificationPref, key: AppUserDefaults.pref_notificationPref)
                        self.switchNotification.setOn(true, animated: true)
                    } else {
                        UserDefaultHelper.setBoolPREF(false, key: AppUserDefaults.pref_notification)
                        UserDefaultHelper.delPREF(AppUserDefaults.pref_device_token)
                        UserDefaultHelper.setPREF(strNotificationPref, key: AppUserDefaults.pref_notificationPref)
                        self.switchNotification.setOn(false, animated: true)
                    }
                }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
            print(error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
        }
    }
}

// MARK: - Custom Methods for Facebook sign in
extension SettingsViewController {
    /// Method for Facebook sign in
    private func FBSignIn(onCompletionHandler: @escaping (_ isSucess:Bool) -> ()) {
        if UserDefaultHelper.getPREF(AppUserDefaults.fb_Token) == nil {
            fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
                if (error == nil){
                    let fbloginresult : FBSDKLoginManagerLoginResult = result!
                    if fbloginresult.grantedPermissions != nil {
                        if(fbloginresult.grantedPermissions.contains("email")) {
                            if((FBSDKAccessToken.current()) != nil){
                                FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                                    if (error == nil){
                                        print(result!)
                                        if connection?.urlResponse.statusCode == 200 {
                                            if let dictResult = result as? [String:Any] {
                                                if let userID = dictResult["id"] as? String {
                                                    print(userID)
                                                }
                                            }
                                            onCompletionHandler(true)
                                        }
                                    }
                                })
                            }
                        }
                    } else {
                        self.switchFB.setOn(false, animated: false)
                    }
                } else {
                    print(error?.localizedDescription ?? "error")
                }
            }
        }
    }
    
    /// Method for Facebook sign out
    private func FBLogOut() {
        self.fbLoginManager.logOut()
        self.switchFB.setOn(false, animated: true)
        UserDefaultHelper.delPREF(AppUserDefaults.fb_Token)
    }
}

// MARK: - Google Sign In delegate method
extension SettingsViewController: GIDSignInDelegate, GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            if user.authentication.accessToken != nil {
                UserDefaultHelper.setPREF(user.authentication.accessToken, key: AppUserDefaults.pref_google_accessToken)
                self.switchYouTube.setOn(true, animated: false)
            }
        } else {
            self.switchYouTube.setOn(false, animated: false)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        UserDefaultHelper.delPREF(AppUserDefaults.pref_google_accessToken)
        self.switchYouTube.setOn(false, animated: false)
    }
}
