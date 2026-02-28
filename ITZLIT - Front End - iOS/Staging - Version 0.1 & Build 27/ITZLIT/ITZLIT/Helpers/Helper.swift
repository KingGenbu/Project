//
//  Helper.swift
//  ITZLIT
//
//  Created by devang.bhatt on 27/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftLoader
import FBSDKLoginKit
import MessageUI

let APP_NAME = "ITZLIT"

class Helper : NSObject, MFMailComposeViewControllerDelegate {
    static let appdelegate = UIApplication.shared.delegate as? AppDelegate
    static let invitationLink = "https://itzlit-stage.app.link/invite"
    static let networkNotAvailableCode = -1009
    static let emailValidExpression = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
    static var isFBData: Bool = false
    
    static let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
    static let storyShareStoryBoard = UIStoryboard(name: "StoryShare", bundle: nil)
    static let settingFeedStoryBoard = UIStoryboard(name: "SettingFeed", bundle: nil)
    static let feedActionStoryBoard = UIStoryboard(name: "FeedAction", bundle: nil)
    
    //MARK:- Load Custome View Extension -
    
    class func loadFromNibNamed(_ nibNamed: String, bundle : Bundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiate(withOwner: nil, options: nil)[0] as? UIView
    }
    
    /// show alert dialog box
    class func showAlertDialog(_ title:String, message: String, clickAction:@escaping ()->() ) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.message = message
        alertView.title = title
        alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            clickAction()
        }))
        
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController! else {return}
        
        if let TabviewCntrl = viewController as? UITabBarController
        {
            if let navVC = TabviewCntrl.selectedViewController as? UINavigationController
            {
                navVC.visibleViewController?.present(alertView, animated: true, completion: nil)
            }
        }else{
            
            if let alertWindow = UIWindow(frame: UIScreen.main.bounds) as UIWindow? {
                alertWindow.windowLevel = UIWindowLevelAlert
                alertWindow.rootViewController = UIViewController()
                alertWindow.makeKeyAndVisible()
                alertWindow.rootViewController?.present(alertView, animated: true, completion: nil)
            } else {
                viewController.present(alertView, animated: true, completion: nil)
            }
        }
    }
    
    /// return date into string format
    class func convertDateFormat(serverDateFormate: String, newDateFormate: String, date: String)-> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = serverDateFormate
        let date = dateFormatter.date(from: date)
        dateFormatter.dateFormat = newDateFormate
        
        return date! //dateFormatter.string(from: date!)
    }
    
    
    /// Show alert dialog with two buttons
    class func showAlertDialogWith2Button(onVC viewController:UIViewController, title:String, message:String,button1Title:String, button1ActionStyle:UIAlertActionStyle, button2Title:String, onButton1Click:(()->())?, onButton2Click:(()->())?) {
        DispatchQueue.main.async {
            let alert : UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: button1Title, style:button1ActionStyle, handler: { (action:UIAlertAction) in
                onButton1Click?()
            }))
            
            alert.addAction(UIAlertAction(title: button2Title, style:.default, handler: { (action:UIAlertAction) in
                onButton2Click?()
            }))
            
            alert.view.setNeedsLayout()
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    /// validation to check email is enter valid or not
    class func isValidEmail(_ email:String)-> Bool{
        let emailRegEx = emailValidExpression
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let result = emailTest.evaluate(with: email)
        return result
    }
    
    class func isValidPassword(_ pass: String) -> Bool{
        for p in pass where p.isUppercase && pass.count >= 6  {
            return true
        }
        return false
    }
    
    class func showProgressBar() {
        var config : SwiftLoader.Config = SwiftLoader.Config.init()
        config.size = 150.0
        config.spinnerColor = .white
        config.backgroundColor = UIColor(red: 42.0/255.0, green: 39.0/255.0, blue: 74.0/255.0, alpha: 1.0)
        //        config.foregroundColor = .black
        SwiftLoader.show(animated: true)
    }
    class func showProgressBarWith(title:String) {
        var config : SwiftLoader.Config = SwiftLoader.Config.init()
        config.size = 150.0
        config.spinnerColor = .white
        config.backgroundColor = UIColor(red: 42.0/255.0, green: 39.0/255.0, blue: 74.0/255.0, alpha: 1.0)
        //        config.foregroundColor = .black
        SwiftLoader.show(title: title, animated: true)
    }
    class func hideProgressBar() {
        SwiftLoader.hide()
    }
    
     /// Returns a image that fills in newSize
    class func resizedImage(image:UIImage,newSize: CGSize) -> UIImage {
        
        guard image.size != newSize else { return image }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    class func WSGetProfileCalled() {
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.profile, onComplete: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    UserDefaultHelper.setDicPREF(json.dictionaryObject!, key: AppUserDefaults.pref_dictProfile)
                }
            } else {
                print(error?.localizedDescription ?? "error in profile ws called")
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error?.localizedDescription ?? "error alamofire")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    
    /// WS Get presigned url called
    class func WSGetPresingedUrl(completionHandler:@escaping (Bool)->()) {
        ApiManager.Instance.sendHttpGetWithoutHeader(path: WebserverPath.awsPresingedUrl, onComplete: { (json, error, response) in
            if error == nil {
                if let presignedUrl = json.dictionaryObject!["preSignedUrl"] as? String {
                    UserDefaultHelper.setPREF(presignedUrl, key: AppUserDefaults.pref_presignedUrl)
                }
                if let url = json.dictionaryObject!["url"] as? String {
                    UserDefaultHelper.setPREF(url, key: AppUserDefaults.pref_AWS_URL)
                }
                completionHandler(true)
            } else {
                print(error?.localizedDescription ?? "error in presigned url response")
                completionHandler(false)
            }
        }) { (error, repsonse) in
            print(error ?? "error")
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
            completionHandler(false)
        }
    }
    
    class func WSLogoutCalled(navigation: UINavigationController) {
        let viewController = navigation.viewControllers.last
        Helper.showAlertDialogWith2Button(onVC: viewController!, title: APP_NAME, message: AppMessage.logoutMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Logout", onButton1Click: nil) {
            
            let deviceId = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)!
            
            let parameter: [String:Any] = [WebserviceRequestParmeterKey.deviceId : deviceId]
            
            Helper.showProgressBar()
            ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.logout, parameter: parameter, onCompletion: { (json, error, response) in
                if error == nil {
                    if (response as! HTTPURLResponse).statusCode == 200 {
                        if let msg = json.dictionaryObject!["msg"] as? String {
                            Helper.showAlertDialog(APP_NAME, message: msg, clickAction: {})
                        }
                        DBManager.shared.clearDb()
                        UserDefaultHelper.delPREF(AppUserDefaults.pref_device_token)
                        UserDefaultHelper.delDicPREF(AppUserDefaults.pref_dictProfile)
                        UserDefaultHelper.delPREF(AppUserDefaults.fb_Token)
                        UserDefaultHelper.delBoolPREF(AppUserDefaults.pref_user_verified)
                        UserDefaultHelper.delPREF(AppUserDefaults.pref_user_registered_token)
                        UserDefaultHelper.delBoolPREF(AppUserDefaults.pref_Fb_Login)
                        FBSDKLoginManager().logOut()
                        navigation.popToRootViewController(animated: true)
                        navigation.dismiss(animated: false, completion: nil)
                    }
                }
                Helper.hideProgressBar()
            }) { (error, response) in
                print(error ?? "error alamofire")
                if error?.code == Helper.networkNotAvailableCode {
                    Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
                }
                Helper.hideProgressBar()
            }
        }
    }
    
    class func getActionSheetForMenu(navigation : UINavigationController) -> UIAlertController{
        let asMenuOption: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        asMenuOption.view.tintColor = UIColor.black.withAlphaComponent(0.5)
        asMenuOption.title = nil
        asMenuOption.message = nil
        let homeActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.home.rawValue, style: .default) { action -> Void in
            self.navigateToHomeScren(navigation: navigation)
        }
        if #available(iOS 11.0, *) {
            homeActionButton.accessibilityAttributedLabel = NSAttributedString(string: "", attributes: [NSAttributedStringKey.font: UIFontConst.POPPINS_LIGHT ?? UIFont.boldSystemFont(ofSize: 18.0)])
        } else {
            // Fallback on earlier versions
        }
        asMenuOption.addAction(homeActionButton)
        
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            
            let inviteFriendsActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.inviteFriends.rawValue, style: .default) { action -> Void in
                self.navigateToInviteFriends(navigation: navigation)
            }
            asMenuOption.addAction(inviteFriendsActionButton)
            
            let myProfileActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.myProfile.rawValue, style: .default) { action -> Void in
                self.navigateToMyProfile(navigation: navigation)
            }
            asMenuOption.addAction(myProfileActionButton)
            
        } else {
            let loginActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.login.rawValue, style: .default) { action -> Void in
                self.navigateToLogin(navigation: navigation)
            }
            asMenuOption.addAction(loginActionButton)
            
            let signUpActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.signUp.rawValue, style: .default) { action -> Void in
                self.navigateToRegistration(navigation: navigation)
            }
            asMenuOption.addAction(signUpActionButton)
        }
        
        let supportActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.support.rawValue, style: .default) { action -> Void in
            
            self.navigateToSupportView(navigation: navigation)
        }
        asMenuOption.addAction(supportActionButton)
        
        let termsActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.termsOfUse.rawValue, style: .default) { action -> Void in
            
            self.navigateToTermsAndPrivacyScreen(isFromPrivacyPolicy: false, navigation: navigation)
        }
        asMenuOption.addAction(termsActionButton)
        
        let privacyPolicyActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.privacyPolicy.rawValue, style: .default) { action -> Void in
            self.navigateToTermsAndPrivacyScreen(isFromPrivacyPolicy: true, navigation: navigation)
        }
        asMenuOption.addAction(privacyPolicyActionButton)
        
        let settingsActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.settings.rawValue, style: .default) { action -> Void in
            self.navigateToSettingsScreen(navigation: navigation)
        }
        asMenuOption.addAction(settingsActionButton)
        
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            
            let logoutActionButton: UIAlertAction = UIAlertAction(title: MenuTitle.logout.rawValue, style: .destructive) { action -> Void in
                
                self.WSLogoutCalled(navigation: navigation)
            }
            asMenuOption.addAction(logoutActionButton)
        }
        
        let cancelActionButton: UIAlertAction =  UIAlertAction(title: MenuTitle.cancel.rawValue, style: .cancel, handler: nil)
        asMenuOption.addAction(cancelActionButton)
        
        return asMenuOption
    }
    
    class func Push_Pop_to_ViewController(destinationVC:UIViewController,isAnimated:Bool, navigationController : UINavigationController){
        
        var VCFound:Bool = false
        // Get all viewcontrollers From navigatonController
        let viewControllers: [UIViewController] = navigationController.viewControllers
        var indexofVC:NSInteger = 0
        for  vc  in viewControllers {
            if (vc as AnyObject).nibName == (destinationVC.nibName) {
                VCFound = true
                break
            } else {
                indexofVC += 1
            }
        }
        if VCFound == true {
            navigationController .popToViewController(viewControllers[indexofVC], animated: isAnimated)
        } else {
            DispatchQueue.main.async {
                navigationController .pushViewController(destinationVC , animated: isAnimated)
            }
        }
    }
    
    static func navigateToMyProfile(navigation : UINavigationController) {
        let profileVC = mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.profile.rawValue) as! ProfileTableViewController
        Push_Pop_to_ViewController(destinationVC: profileVC, isAnimated: true, navigationController: navigation)
    }
    
    static func navigateToInviteFriends(navigation : UINavigationController) {
        let contactVC = mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.contact.rawValue) as! ContactViewController
        Push_Pop_to_ViewController(destinationVC: contactVC, isAnimated: true, navigationController: navigation)
    }
    
    static func navigateToLogin(navigation : UINavigationController) {
        let loginVC = mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.login.rawValue) as! LoginTableViewController
        Push_Pop_to_ViewController(destinationVC: loginVC, isAnimated: true, navigationController: navigation)
    }
    
    static func navigateToRegistration(navigation : UINavigationController) {
        let registrationVC = mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.registration.rawValue) as! RegistrationTableViewController
        Push_Pop_to_ViewController(destinationVC: registrationVC, isAnimated: true, navigationController: navigation)
    }
    
    static func navigateToHomeScren(navigation : UINavigationController) {
        if !(navigation.viewControllers.last?.isKind(of: HomeViewController.self))! {
            let homeVC = mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.home.rawValue) as! HomeViewController
            
            Push_Pop_to_ViewController(destinationVC: homeVC, isAnimated: true, navigationController: navigation)
         }
    }
    
    static func navigateToSettingsScreen(navigation : UINavigationController) {
        let settingsVC = settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.settingsVC.rawValue) as! SettingsViewController
        
        Push_Pop_to_ViewController(destinationVC: settingsVC, isAnimated: true, navigationController: navigation)
    }
    
    static func navigateToTermsAndPrivacyScreen(isFromPrivacyPolicy: Bool, navigation : UINavigationController) {
        let termsAndPrivacyVC = mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.termsAndPrivacyVC.rawValue) as! TermsAndPrivacyViewController
        termsAndPrivacyVC.isFromPrivacyPolicy = isFromPrivacyPolicy
        Push_Pop_to_ViewController(destinationVC: termsAndPrivacyVC, isAnimated: true, navigationController: navigation)
    }
    
    static func navigateToSupportView(navigation: UINavigationController) {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.showMailComposer(navigation: navigation)
     }
}

extension MFMailComposeViewController: MFMailComposeViewControllerDelegate {
    func showMailComposer(navigation: UINavigationController) {
        if MFMailComposeViewController.canSendMail() {
            let strVersionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let strBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
            
            self.mailComposeDelegate = self
            self.setToRecipients(["Itzlitlive@gmail.com"])
            self.setSubject("ITZLIT Support")
            self.setMessageBody("Version:  " + strVersionNumber + "\n" + "Build:  " + strBuildNumber, isHTML: false)
            navigation.present(self, animated: true, completion: nil)
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}

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
