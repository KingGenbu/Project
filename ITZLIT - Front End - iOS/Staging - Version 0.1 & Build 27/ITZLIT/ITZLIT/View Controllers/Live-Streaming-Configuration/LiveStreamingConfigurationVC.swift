//
//  LiveStreamingConfigurationVC.swift
//  ITZLIT
//
//  Created by devang.bhatt on 24/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Alamofire
import GoogleSignIn
import GoogleAPIClientForREST
import FBSDKCoreKit
import FBSDKLoginKit
import SafariServices
import IQKeyboardManagerSwift

class LiveStreamingConfigurationVC: UIViewController {
    
    @IBOutlet var switchItzlit: UISwitch!
    @IBOutlet var switchYoutube: UISwitch!
    @IBOutlet var switchFB: UISwitch!
    @IBOutlet weak var btnNoSettingEnableForLiveConfig: UIButton!
    @IBOutlet var txtTellAboutStory: UITextField!
    
    var ingestionAddress: String = ""
    var streamName: String = ""
    
    var gidSignIn = GIDSignIn.sharedInstance()
    var fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.configureUI()
        IQKeyboardManager.sharedManager().enableAutoToolbar = true
        IQKeyboardManager.sharedManager().toolbarTintColor = .blue
        self.configureGoogleSignIn()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Configure Google Sign-in.
    func configureGoogleSignIn() {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeYouTube, kGTLRAuthScopeYouTubeForceSsl,kGTLRAuthScopeYouTubeReadonly]
        GIDSignIn.sharedInstance().clientID = ApiManager.ytClientID
    }
    
    @IBAction func switchItzlitTapped(_ sender: UISwitch) {
        
    }
    
    /// Action method for youtube switch
    @IBAction func switchYouTubeTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.switchYoutube.setOn(false, animated: false)
            gidSignIn?.signOut()
            gidSignIn?.disconnect()
            gidSignIn?.signIn()
        } else {
            self.btnNoSettingEnableForLiveConfig.isHidden = true
            self.btnNoSettingEnableForLiveConfig.setTitle("", for: .normal)
            gidSignIn?.signOut()
            gidSignIn?.disconnect()
        }
    }
    
    /// Action method for Facebook switch
    @IBAction func switchFBTapped(_ sender: UISwitch) {
        if sender.isOn {
//            self.switchFB.setOn(false, animated: false)
            self.switchFB.isOn = false
            self.FBSignIn(onCompletionHandler: {isSucess in
                if isSucess {
                    let token = FBSDKAccessToken.current().tokenString
                    UserDefaultHelper.setPREF(token!, key: AppUserDefaults.fb_Token)
                    self.WSCheckPermissionForFBPlublicAction(onCompletionHandler: { (isSucess) in
                        if isSucess {
                            self.switchFB.isOn = true
                        } else {
                            print("public action not granted...!")
                        }
                    })
                }
            })
        } else {
            self.FBLogOut()
        }
    }
    
    /// Check Permisson for YouTube Live Streaming
    func WSCheckPermissionForYTLiveStreamingCalled() {
         if UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken) != nil{
            self.WSCheckPermissionForLiveStreaming(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!) { (isSucess, response) in
                if isSucess {
                    if self.switchFB.isOn {
                        self.WSGetFBStreamURL()
                    } else {
                        let goLiveVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.goLive.rawValue) as! GoLiveVC
                        goLiveVC.isItzlitOn = self.switchItzlit.isOn
                        goLiveVC.isYoutubeOn = self.switchYoutube.isOn
                        goLiveVC.isFBOn = self.switchFB.isOn
                        goLiveVC.strCaption = self.txtTellAboutStory.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        self.btnNoSettingEnableForLiveConfig.isHidden = true
                        self.btnNoSettingEnableForLiveConfig.setTitle("", for: .normal)
                        Helper.Push_Pop_to_ViewController(destinationVC: goLiveVC, isAnimated: true, navigationController: self.navigationController!)
                    }
                }
                else {
                    if let dictResponse = response?.result.value as? [String:Any] {
                        if let error = dictResponse["error"] as? [String:Any] {
                            if let errorMessage = error["message"] as? String {
                                print(errorMessage)
                                self.btnNoSettingEnableForLiveConfig.isHidden = false
                                self.btnNoSettingEnableForLiveConfig.setTitle("Click here to enable for YouTube live streaming.", for: .normal)
                                
                                let animation = CABasicAnimation(keyPath: "position")
                                animation.duration = 0.07
                                animation.repeatCount = 5
                                animation.autoreverses = true
                                animation.fromValue = NSValue(cgPoint: CGPoint(x: self.btnNoSettingEnableForLiveConfig.center.x - 10, y: self.btnNoSettingEnableForLiveConfig.center.y))
                                animation.toValue = NSValue(cgPoint: CGPoint(x: self.btnNoSettingEnableForLiveConfig.center.x + 10, y: self.btnNoSettingEnableForLiveConfig.center.y))
                                
                                self.btnNoSettingEnableForLiveConfig.layer.add(animation, forKey: "position")
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// WS called to check FB Plublic Action is Enabled or not
    func WSCheckPermissionForFBPlublicAction(onCompletionHandler: @escaping (_ isSucess:Bool) -> ()) {
        if FBSDKAccessToken.current() != nil {
            if FBSDKAccessToken.current().hasGranted("publish_actions") {
                print("Granted")
                onCompletionHandler(true)
            } else {
                self.fbLoginManager.logIn(withPublishPermissions: ["publish_actions"], from: self) { (result, error) in
                    if error == nil {
                        let fbloginresult : FBSDKLoginManagerLoginResult = result!
                        if fbloginresult.grantedPermissions != nil {
                            if (fbloginresult.grantedPermissions.contains("publish_actions")) {
                                onCompletionHandler(true)
                            } else {
                                onCompletionHandler(false)
                            }
                        } else {
                            onCompletionHandler(false)
                        }
                    } else {
                        print("error: ", error?.localizedDescription ?? "error")
                        onCompletionHandler(false)
                    }
                }
            }
        } else {
            self.fbLoginManager.logIn(withPublishPermissions: ["publish_actions"], from: self) { (result, error) in
                if error == nil {
                    let fbloginresult : FBSDKLoginManagerLoginResult = result!
                    if fbloginresult.grantedPermissions != nil {
                        if (fbloginresult.grantedPermissions.contains("publish_actions")) {
                            onCompletionHandler(true)
                        } else {
                            onCompletionHandler(false)
                        }
                    } else {
                        onCompletionHandler(false)
                    }
                } else {
                    print("error: ", error?.localizedDescription ?? "error")
                    onCompletionHandler(false)
                }
            }
        }
    }
    
    /// WS to Get Stream URL to Go Live in FB
    func WSGetFBStreamURL() {
        Helper.showProgressBar()
        let parameter: [String:Any] = ["description":self.txtTellAboutStory.text == "" ? "" : self.txtTellAboutStory.text!]
        print("Parameter for Stream URL:  ",  parameter)
        FBSDKGraphRequest.init(graphPath: "me/live_videos", parameters: parameter, httpMethod: "POST").start { (connection, result, error) in
            if error == nil {
                if connection?.urlResponse.statusCode == 200 {
                    if let resultDict = result as? [String:Any] {
                        if let streamURL = resultDict["secure_stream_url"] as? String {
                            print("secure_stream_url : ", streamURL)
                            UserDefaultHelper.setPREF(streamURL, key: AppUserDefaults.pref_stream_url)
                        }
                        self.switchFB.setOn(true, animated: true)
                        let goLiveVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.goLive.rawValue) as! GoLiveVC
                        goLiveVC.isItzlitOn = self.switchItzlit.isOn
                        goLiveVC.isYoutubeOn = self.switchYoutube.isOn
                        goLiveVC.isFBOn = self.switchFB.isOn
                        goLiveVC.strCaption = self.txtTellAboutStory.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        self.navigationController?.pushViewController(goLiveVC, animated: true)
                        
                    }
                }
                Helper.hideProgressBar()
            } else {
                Helper.hideProgressBar()
                print("error: ", error?.localizedDescription ?? "error")
            }
        }
    }
    
    /// Method to navigate to YT settings to enable Go Live settings
    @IBAction func btnNavigateToYouTubeSettingEnableGoLiveTapped(_ sender: UIButton) {
        // https://www.youtube.com/my_live_events //https://www.youtube.com/features
        if UIApplication.shared.canOpenURL(URL(string: "https://www.youtube.com/my_live_events")!) {
            //            let safariVC = SFSafariViewController(url: URL(string: "https://www.youtube.com/my_live_events")!)
            //            self.present(safariVC, animated: true, completion: nil)
            
            UIApplication.shared.open(URL(string: "https://www.youtube.com/my_live_events")!, options: [:], completionHandler: nil)
        }
    }
    
    /// UIButton Action method to Navigate to Go Live Screen
    @IBAction func btnGoLiveTapped(_ sender: UIButton) {
        if isValid() {
            if self.switchYoutube.isOn {
                self.WSCheckPermissionForYTLiveStreamingCalled()
            }
            else {
                if self.switchFB.isOn {
                    self.WSGetFBStreamURL()
                } else {
                    let goLiveVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.goLive.rawValue) as! GoLiveVC
                    goLiveVC.isItzlitOn = self.switchItzlit.isOn
                    goLiveVC.isYoutubeOn = self.switchYoutube.isOn
                    goLiveVC.strCaption = self.txtTellAboutStory.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    goLiveVC.isFBOn = self.switchFB.isOn
                    navigationController?.pushViewController(goLiveVC, animated: true)
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate method to resign textfield.
extension LiveStreamingConfigurationVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Custom Methods
extension LiveStreamingConfigurationVC {
    
    /// Setup UI
    func configureUI() {
        self.title = ViewControllerTitle.liveStreaming.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton
      
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = #imageLiteral(resourceName: "img_background")
        backgroundImage.contentMode = .scaleAspectFill
        self.view.insertSubview(backgroundImage, at: 0)
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
        
        self.txtTellAboutStory.attributedPlaceholder  = NSAttributedString(string: "What would you like to say?", attributes: [NSAttributedStringKey.font: UIFontConst.POPPINS_LIGHT!, NSAttributedStringKey.foregroundColor: UIColor.white])
    }
    
    /// Left UIBarButton selector method
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        _ = self.navigationController?.popViewController(animated: false)
    }
    
    /// WS to check permission that live streaming is enabled for YouTube or not
    func WSCheckPermissionForLiveStreaming(token: String, callback: @escaping (Bool, DataResponse<Any>?) -> Void) {
        //Method:GET https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id%2Csnippet%2CcontentDetails%2Cstatus&mine=true
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json"]
        var originalURL = "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id,snippet,contentDetails,status&mine=true"
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        Helper.showProgressBar()
        Alamofire.request(originalURL, method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    callback(true, response)
                } else {
                    callback(false, response)
                }
                Helper.hideProgressBar()
                return
            case .failure(let failureErr as NSError):
                print(failureErr.localizedDescription)
                Helper.hideProgressBar()
                if failureErr.code == Helper.networkNotAvailableCode {
                    Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
                }
                callback(false, nil)
                return
            }
        }
    }

    /// Validation for switch
    func isValid() -> Bool {
       
        if !(self.switchItzlit.isOn) && !(self.switchYoutube.isOn) && !(self.switchFB.isOn) {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.inValidOptionToGoLive.rawValue, clickAction: {})
            return false
        }
        
        return true
    }
}

// MARK: - Setup for Youtube Login
extension LiveStreamingConfigurationVC: GIDSignInDelegate, GIDSignInUIDelegate {
    
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
                self.switchYoutube.setOn(true, animated: false)
            }
        } else {
            self.switchYoutube.setOn(false, animated: false)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        UserDefaultHelper.delPREF(AppUserDefaults.pref_google_accessToken)
        self.switchYoutube.setOn(false, animated: false)
    }
}

// MARK: - Setup for Facebook Login
extension LiveStreamingConfigurationVC {
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
        } else {
            self.WSCheckPermissionForFBPlublicAction(onCompletionHandler: { (isSucess) in
                if isSucess {
                    self.switchFB.isOn = true
                } else {
                    print("public action not granted...!")
                }
            })
         }
    }
    
    /// Method for Facebook sign out
    private func FBLogOut() {
        self.fbLoginManager.logOut()
        self.switchFB.setOn(false, animated: true)
        UserDefaultHelper.delPREF(AppUserDefaults.fb_Token)
    }
}

extension LiveStreamingConfigurationVC : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func safariViewController(_ controller: SFSafariViewController, excludedActivityTypesFor URL: URL, title: String?) -> [UIActivityType] {
        
        return []
    }
}

