//
//  SettingsViewController.swift
//  HydroX
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

    var fbLoginManager = LoginManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let strVersionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let strBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            self.lblVersionBuild.text = "Version: " + strVersionNumber + "," + " Build: " + strBuildNumber
        }
        self.configureNotificationFacebookAndGoogleSignInSwitchValue()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
    }


    /// Configure UI
    func configureUI() {
        self.title = ViewControllerTitle.settings.rawValue
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedString.Key.foregroundColor: UIColor.white]

        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)

        self.vwAccount.dropShadow(scale: true)
        self.vwPushNotification.dropShadow(scale: true)
    }

    /// Navigation left bar button action method
    @objc func leftBarBackButton(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    /// Configure user's switch values for Notification, Google and Facebook switch
    func configureNotificationFacebookAndGoogleSignInSwitchValue() {
        switchFB.setOn(UserDefaultHelper.getPREF(AppUserDefaults.fb_Token) != nil, animated: false)
        switchYouTube.setOn(UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken) != nil, animated: false)
        let notifOn = UserDefaultHelper.getPREF(AppUserDefaults.pref_notificationPref) == "Yes"
            || UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_notification)
        switchNotification.setOn(notifOn, animated: false)
    }

    /// Action method for Facebook Switch
    @IBAction func switchFBTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.switchFB.setOn(false, animated: false)
            self.FBSignIn { isSucess in
                if isSucess {
                    if let token = AccessToken.current?.tokenString {
                        UserDefaultHelper.setPREF(token, key: AppUserDefaults.fb_Token)
                    }
                    self.switchFB.setOn(true, animated: true)
                }
            }
        } else {
            self.FBLogOut()
        }
    }

    /// Action method for YouTube Switch
    @IBAction func switchYouTubeTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.switchYouTube.setOn(false, animated: false)
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: ApiManager.ytClientID)
            GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
                guard let self = self else { return }
                if error == nil, let accessToken = result?.user.accessToken.tokenString {
                    UserDefaultHelper.setPREF(accessToken, key: AppUserDefaults.pref_google_accessToken)
                    self.switchYouTube.setOn(true, animated: true)
                } else {
                    self.switchYouTube.setOn(false, animated: false)
                }
            }
        } else {
            GIDSignIn.sharedInstance.signOut()
            GIDSignIn.sharedInstance.disconnect { _ in
                UserDefaultHelper.delPREF(AppUserDefaults.pref_google_accessToken)
            }
            self.switchYouTube.setOn(false, animated: true)
        }
    }

    /// Action method for Push notification Switch
    @IBAction func switchPushNotificationTapped(_ sender: UISwitch) {
        let isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        if sender.isOn {
            if isRegistered {
                self.WSUpdateNotificationPref("Yes")
            } else {
                self.switchNotification.setOn(false, animated: false)
                showSettingsAlert(message: "Allow access for notification from settings")
            }
        } else {
            if isRegistered {
                self.WSUpdateNotificationPref("No")
            } else {
                self.switchNotification.setOn(false, animated: false)
                showSettingsAlert(message: "Allow access for notification from settings")
            }
        }
    }

    private func showSettingsAlert(message: String) {
        Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: message,
                                          button1Title: "Cancel", button1ActionStyle: .cancel,
                                          button2Title: "Settings", onButton1Click: nil) {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
        }
    }

    /// WS called to configure notification switch
    func WSUpdateNotificationPref(_ strNotificationPref: String) {
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.notificationPref: strNotificationPref,
                                        WebserviceRequestParmeterKey.deviceId: UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)!]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.notificationPref, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as? HTTPURLResponse)?.statusCode == 200 {
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
    private func FBSignIn(onCompletionHandler: @escaping (_ isSucess: Bool) -> ()) {
        guard UserDefaultHelper.getPREF(AppUserDefaults.fb_Token) == nil else { return }
        fbLoginManager.logIn(permissions: ["public_profile", "email"], from: self) { result, error in
            guard error == nil, let result = result, !result.isCancelled else {
                onCompletionHandler(false)
                return
            }
            guard result.grantedPermissions.contains("email"),
                  AccessToken.current != nil else {
                self.switchFB.setOn(false, animated: false)
                onCompletionHandler(false)
                return
            }
            GraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"]).start { _, result, error in
                guard error == nil else {
                    onCompletionHandler(false)
                    return
                }
                onCompletionHandler(true)
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
