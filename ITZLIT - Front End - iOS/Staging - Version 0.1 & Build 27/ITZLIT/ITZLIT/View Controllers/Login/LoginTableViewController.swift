//
//  LoginTableViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 26/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Alamofire

class LoginTableViewController: UITableViewController {
    @IBOutlet var vwEmail: ILCustomViews!
    @IBOutlet var vwPassword: ILCustomViews!
    @IBOutlet var btnSignIn: UIButton!
    @IBOutlet var btnForgotPassword: UIButton!
    @IBOutlet var btnFBLogin: FBSDKLoginButton!
    @IBOutlet var btnCreateNewAccount: UIButton!
    @IBOutlet var vwForgetPassword: UIView!
    @IBOutlet var btnSubmit: UIButton!
    @IBOutlet var vwForgetPassView: ILCustomViews!
    @IBOutlet var vwForgetPasswordMain: UIView!
    @IBOutlet weak var imgLogo: UIImageView!
    
    var isForgetPassword: Bool = false
    var appdelegate: AppDelegate! = nil
    var isFromRegistration: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        if #available(iOS 11.0, *) {
             self.tableView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        btnFBLogin.readPermissions = ["public_profile", "email"]
        btnFBLogin.delegate = self
        btnFBLogin.setAttributedTitle(NSAttributedString(string: App.fbButtonTitle.rawValue, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 18)]), for: .normal)
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
     }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Action method for sign in button
    @IBAction func btnSignInTapped(_ sender: UIButton?) {
        self.view.endEditing(true)
         if self.isValid(isCheckForForgotPass: false) {
            self.WSSignInCalled()
        }
    }
    
    /// Action method for Submit button
    @IBAction func btnSubmitTapped(_ sender: UIButton?) {
        if isValid(isCheckForForgotPass: true) {
            self.WSForgetPasswordCalled()
        }
     }
    
    /// WS called for Forget Password
    func WSForgetPasswordCalled() {
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.email : self.vwForgetPassView.txtName.text!]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.forgetPassword, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let errorMessage = json.dictionaryObject!["error"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                        return
                    }
                    if let message = json.dictionaryObject!["msg"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: message, clickAction: {})
                    }
                } else {
                    if let message = json.dictionaryObject!["error"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: message, clickAction: {})
                    }
                }
             }
            Helper.hideProgressBar()
        }, onError: { (error, response) in
            print(error ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    
    /// Action method for Forget Password button
    @IBAction func btnForgotPasswordTappd(_ sender: UIButton) {
        self.view.endEditing(true)
        isForgetPassword = true
        vwForgetPassword.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.btnSubmit.addGradientToBackground()
        self.appdelegate = UIApplication.shared.delegate as! AppDelegate
        self.vwForgetPassword.frame = (self.appdelegate.window?.frame)!
        self.appdelegate.window?.addSubview(self.vwForgetPassword)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissChangePasswordView(_:)))
        tapGesture.delegate = self
        self.vwForgetPassword.addGestureRecognizer(tapGesture)
        
        self.tableView.isScrollEnabled = false
     }
    
    /// Selector method to dismiss change password view
    @objc func dismissChangePasswordView(_ sender: UITapGestureRecognizer) {
        isForgetPassword = false
        self.view.endEditing(true)
        self.vwForgetPassword.removeFromSuperview()
        self.tableView.isScrollEnabled = true
        self.vwForgetPassword.removeGestureRecognizer(sender)
     }
    
    @IBAction func btnLoginWithFbTapped(_ sender: UIButton) {
       FBSDKLoginManager().logOut()
    }
    
    @IBAction func btnCreateNewAccoutTapped(_ sender: UIButton) {
        self.vwEmail.txtName.text = ""
        self.vwPassword.txtName.text = ""
        let registrationVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.registration.rawValue) as! RegistrationTableViewController
        self.navigationController?.pushViewController(registrationVC, animated: true)
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func WSSignInCalled() {
        let deviceId =  UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.deviceId: deviceId!,
                                        WebserviceRequestParmeterKey.email :  self.vwEmail.txtName.text!,
                                        WebserviceRequestParmeterKey.password:  self.vwPassword.txtName.text!]
        
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.userLogin, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    if let token = json.dictionaryObject!["token"] as? String {
                        UserDefaultHelper.setPREF(token, key: AppUserDefaults.pref_user_registered_token)
                        if (json.dictionaryObject!["isVerified"] as? Bool) == true {
                            UserDefaultHelper.setBoolPREF((json.dictionaryObject!["isVerified"] as! Bool), key: AppUserDefaults.pref_user_verified)
                            self.vwEmail.txtName.text = ""
                            self.vwPassword.txtName.text = ""
                            Helper.WSGetProfileCalled()
                            if self.isFromRegistration {
                                var arrNavigationController = self.navigationController?.viewControllers
                                for controller in arrNavigationController! {
                                    if controller.isKind(of: RegistrationTableViewController.self) {
                                        let indexOfReg = arrNavigationController?.index(of: controller)
                                        arrNavigationController?.remove(at: indexOfReg!)
                                        self.navigationController?.viewControllers = arrNavigationController!
                                        _ = self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            } else {
                                _ = self.navigationController?.popViewController(animated: true)
                            }
                            self.syncContact()
                        } else {
                            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyMessage.rawValue, button1Title: "OK", button1ActionStyle: UIAlertActionStyle.default, button2Title: "Resend OTP", onButton1Click: {
                                
                            }, onButton2Click: {
                                let resendOTPVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.resendOTP.rawValue) as! ResendOTPVC
                                Helper.Push_Pop_to_ViewController(destinationVC: resendOTPVC, isAnimated: true, navigationController: self.navigationController!)
                            })
                        }
                    }
                } else {
                    if let errorMessage = json.dictionaryObject!["error"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                        Helper.hideProgressBar()
                        return
                    }
                }
            }
            Helper.hideProgressBar()
        }, onError: { (error, response) in
            print(error ?? "error")
            if let errorMessage = error?.localizedDescription {
                Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
            }
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
            Helper.hideProgressBar()
        })
    }
 
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func syncContact()  {
        ContactManager.shared.inProgressSync = true
        DispatchQueue.global(qos: .background).async {
            
            ContactManager.shared.setUpContactToDbWith(Loader: false, onCompletion: {(refresh) in
                
            
            ContactManager.shared.inProgressSync = false
               NotificationCenter.default.post(name: Notification.Name(rawValue: "handleStoreDidChangeNotification"), object: "Login")
            })
        }
    } 
    func configureUI() {
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.backgroundColor = UIColor.clear
        self.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        self.title =  ViewControllerTitle.signIn.rawValue
        
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "Poppins-Medium", size: 18.0) ?? UIFont.boldSystemFont(ofSize: 18.0), NSAttributedStringKey.foregroundColor: UIColor.white]
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
       
        let btnBackBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnBackTapped(_:)))
        self.navigationItem.leftBarButtonItem = btnBackBarButton
        
        DispatchQueue.main.async {
            self.btnSignIn.addGradientToBackground()
            self.btnCreateNewAccount.addGradientToBackground()
            self.btnSubmit.addGradientToBackground()
        }
 
        self.imgLogo.layer.cornerRadius = self.imgLogo.frame.height / 2.0
        self.imgLogo.clipsToBounds = true
        self.btnSignIn.layer.cornerRadius = self.btnSignIn.frame.height/10.0
        self.btnCreateNewAccount.layer.cornerRadius = self.btnCreateNewAccount.frame.height/10.0
        self.btnFBLogin.layer.cornerRadius = self.btnFBLogin.frame.height/10
        
        self.vwPassword.txtName.delegate = self
        self.vwEmail.txtName.delegate = self
        
        self.vwEmail.txtName.returnKeyType = .next
        self.vwPassword.txtName.returnKeyType = .done
        
        self.vwPassword.txtName.isSecureTextEntry = true
        self.vwEmail.txtName.keyboardType = .emailAddress
        self.vwEmail.txtName.autocorrectionType = .no
        self.vwEmail.txtName.font = UIFontConst.ROBOTO_LIGHT
        self.vwPassword.txtName.font = UIFontConst.ROBOTO_LIGHT
        
        self.vwEmail.lblName.font = UIFontConst.POPPINS_LIGHT
        self.vwPassword.lblName.font = UIFontConst.POPPINS_LIGHT
        
        self.vwForgetPassView.txtName.delegate = self
        self.vwForgetPassView.txtName.autocorrectionType = .no
        self.vwForgetPassView.txtName.keyboardType = .emailAddress
        self.vwForgetPassView.txtName.returnKeyType = .done
        self.vwForgetPassView.txtName.textColor = .lightGray
        self.vwForgetPassView.txtName.font = UIFontConst.ROBOTO_LIGHT
        self.btnSubmit.layer.cornerRadius = 5.0
    }
    
    func isValid(isCheckForForgotPass: Bool) -> Bool {
        
         if !isCheckForForgotPass {
            if (vwEmail.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyEmailAdress.rawValue, clickAction: {
                    self.vwEmail.txtName.becomeFirstResponder()
                })
                return false
            } else if (!Helper.isValidEmail(vwEmail.txtName.text!)) {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.invalidEmailAddress.rawValue, clickAction: {
                    self.vwEmail.txtName.becomeFirstResponder()
                })
                return false
            } else if (vwPassword.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyPassword.rawValue, clickAction: {
                    self.vwPassword.txtName.becomeFirstResponder()
                })
                return false

            }
        } else {
            if (vwForgetPassView.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyEmailAdress.rawValue, clickAction: {
                    self.vwForgetPassView.txtName.becomeFirstResponder()
                })
                return false
            } else if (!Helper.isValidEmail(vwForgetPassView.txtName.text!)) {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.invalidEmailAddress.rawValue, clickAction: {
                    self.vwForgetPassView.txtName.becomeFirstResponder()
                })
                return false

            }

        }
        return true
    }
}

extension LoginTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tableView.isScrollEnabled = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isForgetPassword == true {
            if textField == self.vwForgetPassView.txtName {
                self.vwPassword.txtName.resignFirstResponder()
                self.btnSubmitTapped(nil)
            }
        } else {
            if textField == self.vwEmail.txtName {
                self.vwPassword.txtName.becomeFirstResponder()
            } else {
                self.vwPassword.txtName.resignFirstResponder()
                self.btnSignInTapped(nil)
            }
        }
        
        return true
    }
}

extension LoginTableViewController: UIGestureRecognizerDelegate {
  
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.vwForgetPasswordMain) ?? false {
            return false
        }
        return true
    }
 }

extension LoginTableViewController: FBSDKLoginButtonDelegate {
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        FBLoginManager.loginButton(loginButton, didCompleteWith: result, error: error) { (success, dictResult) in
            if success {
                self.WSUserFBLoginCalled(dictResult: dictResult)
              }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        FBLoginManager.loginButtonDidLogOut(loginButton)
    }
    
    func WSUserFBLoginCalled(dictResult : [String:Any]) {
        let fbID:String = UserDefaultHelper.getPREF(AppUserDefaults.fb_Id)! 
        let fbToken:String = UserDefaultHelper.getPREF(AppUserDefaults.fb_Token)!
        let parameter: [String: Any] = ["fbProvider": [WebserviceRequestParmeterKey.fbId: fbID,
                                        WebserviceRequestParmeterKey.fbAccessToken : fbToken],
                                        WebserviceRequestParmeterKey.deviceId :
                                        UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)!]
        
        Helper.showProgressBar()
        ApiManager.Instance.sendPostEncodingWithoutHeader(urlPath: WebserverPath.fbUserLogin, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                 if ((response as! HTTPURLResponse).statusCode == 499) {
                    let registrationVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.registration.rawValue) as! RegistrationTableViewController
                     Helper.isFBData = true
                    registrationVC.isFBData = Helper.isFBData
                    registrationVC.dictFBResult = dictResult
                    self.navigationController?.pushViewController(registrationVC, animated: true)
                } else {
                    if (json.dictionaryObject!["isVerified"] as? Bool) == true {
                        Helper.isFBData = true
                        UserDefaultHelper.setBoolPREF(Helper.isFBData, key: AppUserDefaults.pref_Fb_Login)
                        UserDefaultHelper.setBoolPREF(json.dictionaryObject!["isVerified"] as! Bool, key: AppUserDefaults.pref_user_verified)
                        if let token = json.dictionaryObject!["token"] as? String {
                            UserDefaultHelper.setPREF(token, key: AppUserDefaults.pref_user_registered_token)
                        }
                        if self.isFromRegistration {
                            var arrNavigationController = self.navigationController?.viewControllers
                            for controller in arrNavigationController! {
                                if controller.isKind(of: RegistrationTableViewController.self) {
                                    let indexOfReg = arrNavigationController?.index(of: controller)
                                    arrNavigationController?.remove(at: indexOfReg!)
                                    self.navigationController?.viewControllers = arrNavigationController!
                                    _ = self.navigationController?.popViewController(animated: true)
                                }
                            }
                        } else {
                            _ = self.navigationController?.popViewController(animated: true)
                        }
                        
                        Helper.WSGetProfileCalled()
                        self.syncContact()
                        
                    } else {
                         Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyMessage.rawValue, button1Title: "OK", button1ActionStyle: UIAlertActionStyle.default, button2Title: "Resend OTP", onButton1Click: {
                         }, onButton2Click: {
                            let resendOTPVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.resendOTP.rawValue) as! ResendOTPVC
                            Helper.Push_Pop_to_ViewController(destinationVC: resendOTPVC, isAnimated: true, navigationController: self.navigationController!)
                        })
                     }
                 }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error?.localizedDescription ?? "errror fb user")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
 }
