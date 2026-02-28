//
//  RegistrationTableViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 26/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import libPhoneNumber_iOS
import SDWebImage
import AVFoundation
import AVKit

class RegistrationTableViewController: UITableViewController {
    
    @IBOutlet var vwFullName: ILCustomViews!
    @IBOutlet var vwEmail: ILCustomViews!
    @IBOutlet var vwMobileNumber: ILCustomViews!
    @IBOutlet var vwPassword: ILCustomViews!
    @IBOutlet var vwConfirmPassword: ILCustomViews!
    @IBOutlet var btnSignUp: UIButton!
    @IBOutlet var btnSignIn: UIButton!
    @IBOutlet var impProfile: UIImageView!
    @IBOutlet var vwFooter: UIView!
    @IBOutlet weak var textViewPolicyAndTerms: IZTextView!
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var btnBarItemPrev: UIBarButtonItem!
    @IBOutlet var btnBarItemNext: UIBarButtonItem!
    @IBOutlet var btnBarItemDone: UIBarButtonItem!
   
    var dictFBResult : [String:Any] = [:]
    var isFBData: Bool = false
    var isImageUploaded: Bool? = nil
    var strFBprofileURL: String = ""
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var playerController : AVPlayerViewController?
    
    let termsOfUseURL = ApiManager.baseUrl + WebserverPath.termsOfUse
    let privacyPolicyURL = ApiManager.baseUrl + WebserverPath.privacyPolicy
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        
        Helper.WSGetPresingedUrl(completionHandler: {_ in})
        self.impProfile.layer.cornerRadius = self.impProfile.frame.height/2
        self.impProfile.layer.masksToBounds = true
        self.impProfile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imgProfileTapped(tapGesture:))))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
        DispatchQueue.main.async {
            self.btnSignUp.addGradientToBackground()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    func addBackgroundVideo() {
        let theURL = Bundle.main.url(forResource: "SampleVideo", withExtension: "mp4")

        player = AVPlayer(url: theURL!)
        playerController = AVPlayerViewController()
        playerController?.view.contentMode = UIViewContentMode.scaleAspectFill
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = false
        playerController!.player = player!
        playerController!.view.frame = view.frame
        self.addChildViewController(playerController!)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer!.frame = self.view.frame
        player?.volume = 0.0
        self.view.layer.insertSublayer(playerLayer!, at: 0)
        self.tableView.backgroundColor = .clear
        self.view.addSubview(self.playerController!.view)
        self.view.sendSubview(toBack: playerController!.view)
        player?.play()
    }
    
    @IBAction func btnBarPrevTapped(_ sender: UIBarButtonItem) {
        if sender.title == "<" {
            self.vwEmail.txtName.becomeFirstResponder()
        }
    }
    
    @IBAction func btnBarNextTappe(_ sender: UIBarButtonItem) {
        if sender.title == ">" {
            self.vwPassword.txtName.becomeFirstResponder()
        }
    }
    
    @IBAction func btnBarDoneTapped(_ sender: UIBarButtonItem) {
        if sender.title == "Done" {
            self.btnSingUpTapped(nil)
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnSingUpTapped(_ sender: UIButton?) {
        self.view.endEditing(true)
        if isValid() {
            if isFBData {
                self.WSFBUserSignUpCalled()
            } else {
                if self.isImageUploaded == true {
                    self.WSSignUpCalled()
                } else {
                    if self.isImageUploaded == true {
                        Helper.showAlertDialog(APP_NAME, message: "Please wait, uploading your profile picture", clickAction: {})
                    } else {
                        self.WSSignUpCalled()
                    }
                }
            }
        }
    }
    
    @IBAction func btnSignInTapped(_ sender: UIButton) {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.login.rawValue) as! LoginTableViewController
        loginVC.isFromRegistration = true
        Helper.Push_Pop_to_ViewController(destinationVC: loginVC, isAnimated: true, navigationController: self.navigationController!)
    }
}

// MARK: - Custom Methods
extension RegistrationTableViewController {
 
    func WSSignUpCalled() {
        let countryCode = Locale.current.regionCode
        let phoneUtil = NBPhoneNumberUtil()
        var formattedNumber: String = ""
        var isValidNumber: Bool = false
        do {
            let myNum = try phoneUtil.parse(self.vwMobileNumber.txtName.text, defaultRegion: countryCode)
//            print("E164 num: ", try! phoneUtil.format(myNum, numberFormat: NBEPhoneNumberFormat.E164) )
            do {
                isValidNumber = phoneUtil.isPossibleNumber(myNum)
//                print(phoneUtil.isPossibleNumber(myNum), isValidNumber)
                formattedNumber = try phoneUtil.format(myNum, numberFormat: NBEPhoneNumberFormat.E164)
            } catch {
                print("number is in not formatted")
            }
//            print("E164 num : ", phoneUtil.isPossibleNumber(myNum) )
            
        } catch {
            print("not valid number")
        }
        
        if isValidNumber == true {
            let deviceId = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)
            
            var aws_url : String = ""
            
            var parameter: [String:Any] = [ WebserviceRequestParmeterKey.deviceId: deviceId!,
                                            WebserviceRequestParmeterKey.fullName : self.vwFullName.txtName.text!,
                                            WebserviceRequestParmeterKey.email : self.vwEmail.txtName.text!,
                                            WebserviceRequestParmeterKey.phoneNumber: formattedNumber,
                                            WebserviceRequestParmeterKey.password: self.vwPassword.txtName.text!]
            
            if self.isImageUploaded == true {
                
                aws_url = UserDefaultHelper.getPREF(AppUserDefaults.pref_AWS_URL)!
                let AWSParameter : [String: Any] = [WebserviceRequestParmeterKey.profilePic : aws_url]
                
                parameter.merge(AWSParameter, uniquingKeysWith: { (oldValue, newValue) -> Any in
                    return newValue
                })
            }
            
            Helper.showProgressBar()
            ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.createUser, parameter: parameter, onCompletion: { (json, error, response) in
                if error == nil {
                    
                    if (response as! HTTPURLResponse).statusCode == 200 {
                        if let token = json.dictionaryObject!["token"] as? String {
                            UserDefaultHelper.setPREF(token, key: AppUserDefaults.pref_user_registered_token)
                        }
                        self.vwFullName.txtName.text = ""
                        self.vwEmail.txtName.text = ""
                        self.vwMobileNumber.txtName.text = ""
                        self.vwPassword.txtName.text = ""
                        self.vwConfirmPassword.txtName.text = ""
                        let resendOTPVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.resendOTP.rawValue) as! ResendOTPVC
                        Helper.Push_Pop_to_ViewController(destinationVC: resendOTPVC, isAnimated: true, navigationController: self.navigationController!)
                    } else {
                        if let error = json.dictionaryObject!["error"] as? String {
                            Helper.showAlertDialog(APP_NAME, message: error, clickAction: {
                                self.vwMobileNumber.txtName.becomeFirstResponder()
                            })
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
        } else {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.validMobileNumber.rawValue, clickAction: {})
        }
     }
    
    func WSFBUserSignUpCalled() {
        let countryCode = Locale.current.regionCode
        let phoneUtil = NBPhoneNumberUtil()
        var formattedNumber: String = ""
        do {
            let myNum = try phoneUtil.parse(self.vwMobileNumber.txtName.text, defaultRegion: countryCode)
//            print("E164 num: ", try! phoneUtil.format(myNum, numberFormat: NBEPhoneNumberFormat.E164) )
            do {
                formattedNumber = try phoneUtil.format(myNum, numberFormat: NBEPhoneNumberFormat.E164)
            } catch {
                print("number is in not formatted")
            }
//            print("E164 num : ", phoneUtil.isPossibleNumber(myNum) )
        } catch {
            print("not valid number")
        }
        let deviceId = UserDefaultHelper.getPREF(AppUserDefaults.pref_device_id)
        let fbID = UserDefaultHelper.getPREF(AppUserDefaults.fb_Id)
        let fbToken = UserDefaultHelper.getPREF(AppUserDefaults.fb_Token)
        
        let FBParameter: [String: Any] = [WebserviceRequestParmeterKey.profilePic : self.strFBprofileURL, WebserviceRequestParmeterKey.deviceId: deviceId!,
          WebserviceRequestParmeterKey.fullName : self.vwFullName.txtName.text!,
              WebserviceRequestParmeterKey.email : self.vwEmail.txtName.text!,
              WebserviceRequestParmeterKey.phoneNumber: formattedNumber,
               "fbProvider": [WebserviceRequestParmeterKey.fbId: fbID!, WebserviceRequestParmeterKey.fbAccessToken : fbToken! ]]
        
        Helper.showProgressBar()
        ApiManager.Instance.sendPostEncodingWithoutHeader(urlPath: WebserverPath.createUser, parameter: FBParameter, onCompletion: { (json, error, response) in
            if error == nil {
                
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let token = json.dictionaryObject!["token"] as? String {
                        UserDefaultHelper.setPREF(token, key: AppUserDefaults.pref_user_registered_token)
                    }
                    let resendOTPVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.resendOTP.rawValue) as! ResendOTPVC
                    Helper.Push_Pop_to_ViewController(destinationVC: resendOTPVC, isAnimated: true, navigationController: self.navigationController!)
                 } else {
                    if let error = json.dictionaryObject!["error"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: error, clickAction: {})
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
    
    @objc func imgProfileTapped(tapGesture: UITapGestureRecognizer) {
        let actionSheet = UIAlertController(title: "Choose to select profile picture", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
            self.openCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (_) in
            self.openPhotoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
            self.dismiss(animated: false, completion: nil)
        }))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func openCamera()  {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
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
        self.title =  ViewControllerTitle.signUp.rawValue
        
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "Poppins-Medium", size: 18.0) ?? UIFont.boldSystemFont(ofSize: 18.0), NSAttributedStringKey.foregroundColor: UIColor.white]
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
        
        let btnBackBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnBackTapped(_:)))
        self.navigationItem.leftBarButtonItem = btnBackBarButton
        
        self.btnSignUp.layer.cornerRadius = self.btnSignUp.frame.height/10.0
        self.vwFullName.txtName.font =  UIFontConst.ROBOTO_LIGHT
        self.vwEmail.txtName.keyboardType = .emailAddress
        self.vwEmail.txtName.autocorrectionType = .no
        self.vwEmail.txtName.font =  UIFontConst.ROBOTO_LIGHT
        self.vwMobileNumber.txtName.keyboardType = .numberPad
        self.vwMobileNumber.txtName.font =  UIFontConst.ROBOTO_LIGHT
        self.vwPassword.txtName.isSecureTextEntry = true
        self.vwPassword.txtName.font =  UIFontConst.ROBOTO_LIGHT
        self.vwConfirmPassword.txtName.isSecureTextEntry = true
        self.vwConfirmPassword.txtName.font =  UIFontConst.ROBOTO_LIGHT
        
        self.vwFullName.lblName.font = UIFontConst.POPPINS_LIGHT
        self.vwEmail.lblName.font = UIFontConst.POPPINS_LIGHT
        self.vwMobileNumber.lblName.font = UIFontConst.POPPINS_LIGHT
        self.vwPassword.lblName.font = UIFontConst.POPPINS_LIGHT
        self.vwConfirmPassword.lblName.font = UIFontConst.POPPINS_LIGHT
        
        self.vwFullName.txtName.returnKeyType = .next
        self.vwEmail.txtName.returnKeyType = .next
        self.vwMobileNumber.txtName.returnKeyType = .next
        self.vwPassword.txtName.returnKeyType = .next
        self.vwConfirmPassword.txtName.returnKeyType = .done
        
        self.vwFullName.txtName.delegate = self
        self.vwEmail.txtName.delegate = self
        self.vwMobileNumber.txtName.delegate = self
        self.vwPassword.txtName.delegate = self
        self.vwConfirmPassword.txtName.delegate = self
        
        self.vwMobileNumber.txtName.inputAccessoryView = toolbar
        self.btnBarItemNext.isEnabled = true
        self.btnBarItemNext.title = ">"
        self.btnBarItemPrev.isEnabled = true
        self.btnBarItemPrev.title = "<"
        self.btnBarItemDone.isEnabled = false
        self.btnBarItemDone.title = ""
        if isFBData {
            
            let indexPathPassword = IndexPath(row: 3, section: 0)
            let indexPathConfirmPass = IndexPath(row: 4, section: 0)
            self.tableView.beginUpdates()
            tableView.reloadRows(at: [indexPathPassword, indexPathConfirmPass], with: .automatic)
            self.tableView.endUpdates()
            
            self.btnBarItemNext.isEnabled = false
            self.btnBarItemNext.title = ""
            self.btnBarItemPrev.isEnabled = false
            self.btnBarItemPrev.title = ""
            self.btnBarItemDone.isEnabled = true
            self.btnBarItemDone.title = "Done"
            
            if let email = dictFBResult["email"] as? String {
                 self.vwEmail.txtName.text = email
            }
            if let firstName = dictFBResult["first_name"] as? String {
                 self.vwFullName.txtName.text = firstName
            }
            if let lastName = dictFBResult["last_name"] as? String {
                 self.vwFullName.txtName.text?.append(lastName)
            }
            if let picture = dictFBResult["picture"] as? [String: Any] {
                if let data = picture["data"] as? [String: Any] {
                    if let profileURL = data["url"] as? String {
                        UserDefaultHelper.setPREF(profileURL, key: AppUserDefaults.pref_fb_profile_url)
                        self.strFBprofileURL = profileURL
                        self.impProfile.sd_setShowActivityIndicatorView(true)
                        self.impProfile.sd_setIndicatorStyle(.gray)
                        self.impProfile.sd_setImage(with: URL(string: profileURL), completed: { (image, error, cache, url) in
                            if error == nil {
                            } else {
                                print("image upload failed")
                            }
                        })
                    }
                }
            }
        }
        configurePrivacyAndTermsLabel()
    }
    
    private func configurePrivacyAndTermsLabel() {
        let labelString = "By signing up, you agree to our ITZLIT Terms\nand that you have read our Privacy Policy."
        textViewPolicyAndTerms.text = labelString
        textViewPolicyAndTerms.font = UIFontConst.POPPINS_REGULAR
        let policyTermsAttributedString = NSMutableAttributedString(string: labelString)
        
        let signUpTextRange = (labelString as NSString).range(of: "By signing up, you agree to our")
        policyTermsAttributedString.addAttribute(NSAttributedStringKey.font, value: UIFontConst.POPPINS_LIGHT_13!, range: signUpTextRange)
        
        let termsRange = (labelString as NSString).range(of: "ITZLIT Terms")
        policyTermsAttributedString.addAttribute(.link, value: termsOfUseURL, range: termsRange)
        policyTermsAttributedString.addAttribute(NSAttributedStringKey.font, value: UIFontConst.POPPINS_MEDIUM_13!, range: termsRange)
        
        let readPrivacyRange = (labelString as NSString).range(of: "and that you have read our")
        policyTermsAttributedString.addAttribute(NSAttributedStringKey.font, value: UIFontConst.POPPINS_LIGHT_13!, range: readPrivacyRange)
        
        let policyRange = (labelString as NSString).range(of: "Privacy Policy")
        policyTermsAttributedString.addAttribute(.link, value: privacyPolicyURL, range: policyRange)
        policyTermsAttributedString.addAttribute(NSAttributedStringKey.font, value: UIFontConst.POPPINS_MEDIUM_13!, range: policyRange)
        
        textViewPolicyAndTerms.attributedText = policyTermsAttributedString
        textViewPolicyAndTerms.textAlignment = .center
        textViewPolicyAndTerms.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.black]
        
    }
    
    func isValid() -> Bool {
        
        if (vwFullName.txtName.text?.isEmpty)! {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyFullName.rawValue, clickAction: {
                self.vwFullName.txtName.becomeFirstResponder()
            })
            return false
        } else if (vwEmail.txtName.text?.isEmpty)! {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyEmailAdress.rawValue, clickAction: {
                self.vwEmail.txtName.becomeFirstResponder()
            })
            return false
        } else if (!Helper.isValidEmail(vwEmail.txtName.text!)) {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.invalidEmailAddress.rawValue, clickAction: {
                self.vwEmail.txtName.becomeFirstResponder()
            })
            return false
        } else if (vwMobileNumber.txtName.text?.isEmpty)! {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyMobileNumber.rawValue, clickAction: {
                self.vwMobileNumber.txtName.becomeFirstResponder()
            })
            return false
        } else if self.vwMobileNumber.txtName.text!.count > 15 {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.validMobileNumber.rawValue, clickAction: {
                self.vwMobileNumber.txtName.becomeFirstResponder()
            })
            return false
        }
        if !isFBData {
            if (vwPassword.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyPassword.rawValue, clickAction: {
                    self.vwPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if !Helper.isValidPassword(vwPassword.txtName.text!) {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.validPassword.rawValue, clickAction: {
                    self.vwPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if (vwConfirmPassword.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyConfirmPassword.rawValue, clickAction: {
                    self.vwConfirmPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if vwConfirmPassword.txtName.text != vwPassword.txtName.text {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.mismatchPasswordAndConfPassword.rawValue, clickAction: {
                    self.vwConfirmPassword.txtName.becomeFirstResponder()
                })
                return false
            }
        }
        return true
    }
 
}

extension RegistrationTableViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        guard navigationController != nil else {
            return true
        }
        
        if URL.absoluteString == (ApiManager.baseUrl + WebserverPath.termsOfUse) {
            Helper.navigateToTermsAndPrivacyScreen(isFromPrivacyPolicy: false, navigation: navigationController!)
            return false
        }
        
        if URL.absoluteString == (ApiManager.baseUrl + WebserverPath.privacyPolicy) {
            Helper.navigateToTermsAndPrivacyScreen(isFromPrivacyPolicy: true, navigation: navigationController!)
            return false
        }
        return true
    }
}

// MARK: - UITextFieldDelegate mehtods
extension RegistrationTableViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == vwMobileNumber.txtName {
            let newString = NSString(string: vwMobileNumber.txtName.text!).replacingCharacters(in: range, with: string)
            if newString.count == 15 {
                return newString.count <= 15
            }  else {
                return newString.count <= 15
            }
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tableView.isScrollEnabled = true
    }
 
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.vwFullName.txtName {
            self.vwEmail.txtName.becomeFirstResponder()
        } else if textField == self.vwEmail.txtName {
            self.vwMobileNumber.txtName.becomeFirstResponder()
        } else if textField == self.vwMobileNumber.txtName {
            self.vwPassword.txtName.becomeFirstResponder()
        } else if textField == self.vwPassword.txtName {
            self.vwConfirmPassword.txtName.becomeFirstResponder()
        } else {
            self.vwConfirmPassword.txtName.resignFirstResponder()
            self.btnSingUpTapped(nil)
        }
        return true
    }
}

// MARK: - UINavigationControllerDelegate, UIImagePickerControllerDelegate methods
extension RegistrationTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: false, completion: nil)
        self.impProfile.image = info[UIImagePickerControllerEditedImage] as? UIImage
        let image = Helper.resizedImage(image: self.impProfile.image!, newSize: CGSize(width: 300, height: 300))
        let url = UserDefaultHelper.getPREF(AppUserDefaults.pref_presignedUrl)
        
         ApiManager.Instance.sendMultiPartAWS(path: url!, imgData: UIImageJPEGRepresentation(image, 1.0)!, onComplete: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    self.isImageUploaded = true
                    print("Upload image for registration")
                }
            }
         }) { (error, response) in
            print(error?.localizedDescription ?? "error")
             self.isImageUploaded = false
        }
    }
}

//MARK: UITableViewDelegate Method

extension RegistrationTableViewController {
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellHeight = super.tableView(tableView, heightForRowAt: indexPath)
        
        return (isFBData && (indexPath.row == 3 || indexPath.row == 4)) ? 1.0 : cellHeight
    }

}
