//
//  ProfileTableViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 31/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import SimpleImageViewer

enum StoryType : String {
    case storyImage = "StoryImage"
    case storyVideo = "StoryVideo"
}

enum ThumbSize: String {
    case thumb_300x300 = "thumb_300x300"
    case thumb_750x1334 = "thumb_750x1334"
}

class ProfileTableViewController: UITableViewController,UIGestureRecognizerDelegate {
    
    @IBOutlet var mainVCChangePass: UIView!
    @IBOutlet var vwCurrentPassword: ILCustomViews!
    @IBOutlet var vwNewPassword: ILCustomViews!
    @IBOutlet var vwConfirmPassword: ILCustomViews!
    @IBOutlet var btnChangeCurrentPassword: UIButton!
    
    @IBOutlet var lblChangePassword: UILabel!
    @IBOutlet var vwChangePassword: UIView!
    @IBOutlet var imgProfilePicture: UIImageView!
    @IBOutlet var lblProfileName: UILabel!
    
    @IBOutlet var vwProfileFullName: ILCustomViews!
    @IBOutlet var vwProfileEmail: ILCustomViews!
    @IBOutlet var VwProfileMobileNumber: ILCustomViews!
    
    @IBOutlet var btnCamera: UIButton!
    @IBOutlet var btnChangePassword: UIButton!
    @IBOutlet var btnSave: UIButton!
    
    @IBOutlet weak var collectionHistory: UICollectionView!
    
    var arrRecentStories : [RecentStory]? = []
    var isURLUploadedToAWS:Bool = false
    var imagePicker = UIImagePickerController()
    var appdelegate: AppDelegate! = nil
    var blurEffectView = UIVisualEffectView()
   // var profile: Profile!
    public override var prefersStatusBarHidden: Bool {
        return false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.setupProfileData()
        if #available(iOS 11.0, *) {
            self.tableView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureUI() {
        self.tableView.backgroundView = UIImageView(image: UIImage(named: "img_profile_bg"))
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.isHidden = false
        self.title = ViewControllerTitle.profile.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_profile_bg")!)
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_profile_bg")!)
        statusBar.tintColor = .white
        
        let btnBackBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnBackBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = btnBackBarButton
        setNeedsStatusBarAppearanceUpdate()
        self.imgProfilePicture.layer.cornerRadius = self.imgProfilePicture.frame.height / 2.0
        self.imgProfilePicture.clipsToBounds = true
        self.btnCamera.layer.cornerRadius = self.btnCamera.frame.height / 2.0
        self.btnCamera.clipsToBounds = true
        self.btnChangePassword.layer.cornerRadius = self.btnChangePassword.frame.height / 10.0
        self.btnSave.layer.cornerRadius = self.btnSave.frame.height / 10.0
        
        self.vwProfileFullName.txtName.font = UIFontConst.ROBOTO_LIGHT
        self.vwProfileEmail.txtName.font = UIFontConst.ROBOTO_LIGHT
        self.VwProfileMobileNumber.txtName.font = UIFontConst.ROBOTO_LIGHT
        
        self.vwProfileFullName.lblName.font = UIFontConst.POPPINS_MEDIUM
        self.vwProfileEmail.lblName.font = UIFontConst.POPPINS_MEDIUM
        self.VwProfileMobileNumber.lblName.font = UIFontConst.POPPINS_MEDIUM
        
        self.vwProfileFullName.txtName.textColor = .white
        self.vwProfileEmail.txtName.textColor = .white
        self.vwProfileEmail.txtName.autocorrectionType = .no
        self.VwProfileMobileNumber.txtName.textColor = .white
        self.vwProfileEmail.txtName.keyboardType = .emailAddress
        self.VwProfileMobileNumber.txtName.isEnabled = false
        
        self.vwProfileFullName.txtName.delegate = self
        self.vwProfileEmail.txtName.delegate = self
        
        self.vwCurrentPassword.txtName.delegate = self
        self.vwNewPassword.txtName.delegate = self
        self.vwConfirmPassword.txtName.delegate = self
        
        self.vwCurrentPassword.txtName.returnKeyType = .next
        self.vwNewPassword.txtName.returnKeyType = .next
        self.vwConfirmPassword.txtName.returnKeyType = .done
        
        self.vwCurrentPassword.txtName.isSecureTextEntry = true
        self.vwNewPassword.txtName.isSecureTextEntry = true
        self.vwConfirmPassword.txtName.isSecureTextEntry = true
        
        if UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_Fb_Login) == true {
            self.btnChangePassword.isHidden = true
        } else {
            self.btnChangePassword.isHidden = false
        }
    }
    
    @objc func btnBackBarButtonTapped(_ sender: UIBarButtonItem) {
        self.vwChangePassword.removeFromSuperview()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnCameraTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Choose to select profile picture", message: "", preferredStyle: UIAlertControllerStyle.actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) in
            self.openCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (_) in
            self.openPhotoLibrary()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
        }))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func WSSaveProfileCalled() {
        var url: String = ""
        if UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_Fb_Login) == true {
            if self.isURLUploadedToAWS == true {
                url = UserDefaultHelper.getPREF(AppUserDefaults.pref_AWS_URL) ?? ""
            } else {
                url = UserDefaultHelper.getPREF(AppUserDefaults.pref_fb_profile_url) ?? ""
            }
        } else {
            if self.isURLUploadedToAWS == true {
                url = UserDefaultHelper.getPREF(AppUserDefaults.pref_AWS_URL) ?? ""
            } else {
                let dictProfie = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
                let profileData = Profile(dictionary: dictProfie)
                url = profileData.profilePic ?? ""
            }
        }
        
        var parameter: [String:Any] = [WebserviceRequestParmeterKey.fullName: vwProfileFullName.txtName.text!,
                                       WebserviceRequestParmeterKey.email: vwProfileEmail.txtName.text!,
                                       WebserviceRequestParmeterKey.profilePic: url]
      
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.updateProfile, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    parameter.merge([WebserviceRequestParmeterKey.phoneNumber : self.VwProfileMobileNumber.txtName.text ?? ""], uniquingKeysWith: { (_, new) -> Any in
                        return new
                    })
                    UserDefaultHelper.setDicPREF(parameter, key: AppUserDefaults.pref_dictProfile)
                    if !self.isURLUploadedToAWS == true {
                        if let msg = json.dictionaryObject!["msg"] as? String {
                            Helper.showAlertDialog(APP_NAME, message: msg, clickAction: {})
                        }
                    }
                }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }//
    func openActionSheet(feedId:String,base:UIViewController)  {
        let asMenuOption: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        asMenuOption.view.tintColor = UIColor.black.withAlphaComponent(0.5)
        asMenuOption.title = nil
        asMenuOption.message = nil
        let hideActionButton: UIAlertAction = UIAlertAction(title: "Hide", style: .default) { action -> Void in
            self.hideFeed(feedId:feedId)
        }
        
        
        hideActionButton.setValue(#imageLiteral(resourceName: "hide"), forKey: "image")
        asMenuOption.addAction(hideActionButton)
        let cancelActionButton: UIAlertAction =  UIAlertAction(title: MenuTitle.cancel.rawValue, style: .cancel, handler: nil)
        asMenuOption.addAction(cancelActionButton)
            let deletActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                self.deleteFeed(feedId:feedId)
            }
            
            
            deletActionButton.setValue(#imageLiteral(resourceName: "img_delete"), forKey: "image")
            asMenuOption.addAction(deletActionButton)
        
        base.present(asMenuOption, animated: true, completion: {
            
        })
    }
    ///
    func hideFeed(feedId:String)  {
        
        Helper.showProgressBar()
        
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.feedId: feedId]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.hideFeed, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                
                if (response as! HTTPURLResponse).statusCode == 200  {
                     self.WSRecentStories()
                    
                    
                    let feedData: [String: Any]! = [WebserviceRequestParmeterKey.feedId:parameter[WebserviceRequestParmeterKey.feedId]!,"type":actionType.init(rawValue: 3)!]
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCounters"), object:feedData )
                }
                
            }
        }, onError: { (error, response) in
            //  Helper.hideProgressBar()
            print(error ?? "error")
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    func deleteFeed(feedId:String)  {
        
        Helper.showProgressBar()
        
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.feedId: feedId]
        
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.deleteFeed, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                
                if (response as! HTTPURLResponse).statusCode == 200  {
              self.WSRecentStories()
                    
                    let feedData: [String: Any]! = [WebserviceRequestParmeterKey.feedId:parameter[WebserviceRequestParmeterKey.feedId]!,"type":actionType.init(rawValue: 3)!]
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCounters"), object:feedData )
                }
                
            }
        }, onError: { (error, response) in
            //  Helper.hideProgressBar()
            print(error ?? "error")
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    func activateFeed(feedId:String)  {
        
        Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.feedId: feedId ]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.activateStory, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    
                    self.WSRecentStories()
                    
                }
            }
        }, onError: { (error, response) in
            Helper.hideProgressBar()
            print(error ?? "error")
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    func WSRecentStories() {
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.recentStories, onComplete: { (json, error, response) in
            if error == nil {
                if let dictStories = json.dictionaryObject  {
                    self.arrRecentStories = RecentStory.Populate(list: dictStories["docs"] as! NSArray)
                    if self.arrRecentStories!.count > 0 {
                        self.collectionHistory.dataSource = self
                        self.collectionHistory.delegate = self
                        self.tableView.delegate = self
                        self.tableView.reloadData()
                        self.collectionHistory.reloadData()
                    }
                }
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error ?? "error alamofire")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    
    func setupProfileData() {
        let dictProfie = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
        let profileData = Profile(dictionary: dictProfie)
        if let fullName = profileData.fullName {
            self.lblProfileName.text = fullName
        }
        if let fullName = profileData.fullName {
            self.vwProfileFullName.txtName.text = fullName
        }
        if let email = profileData.email {
            self.vwProfileEmail.txtName.text = email
        }
        if let phoneNumber = profileData.phoneNumber {
            self.VwProfileMobileNumber.txtName.text = phoneNumber
        }
        if let profileURL = profileData.profilePic {
            self.imgProfilePicture.sd_setShowActivityIndicatorView(true)
            self.imgProfilePicture.sd_setIndicatorStyle(.white)
            self.imgProfilePicture.sd_setImage(with: URL(string: profileURL), placeholderImage: nil, completed: nil)
        } else {
            self.imgProfilePicture.image = #imageLiteral(resourceName: "img_profile")
        }
        
        self.WSRecentStories()
    }
    
    func openCamera()  {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func isValid(isChangePass:Bool) -> Bool {
        if isChangePass {
            if (self.vwCurrentPassword.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.currentPass.rawValue, clickAction: {
                    self.vwCurrentPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if (self.vwNewPassword.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.newPass.rawValue, clickAction: {
                    self.vwNewPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if !Helper.isValidPassword(self.vwNewPassword.txtName.text!) {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.validPassword.rawValue, clickAction: {
                    self.vwNewPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if (self.vwConfirmPassword.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyConfirmPassword.rawValue, clickAction: {
                    self.vwConfirmPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if !Helper.isValidPassword(self.vwConfirmPassword.txtName.text!) {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.validPassword.rawValue, clickAction: {
                    self.vwConfirmPassword.txtName.becomeFirstResponder()
                })
                return false
            } else if self.vwConfirmPassword.txtName.text! != self.vwNewPassword.txtName.text! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.mismatchNewPasswordAndConfPassword.rawValue, clickAction: {
                    self.vwConfirmPassword.txtName.becomeFirstResponder()
                })
                return false
            }
        } else {
            if (self.vwProfileFullName.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyFullName.rawValue, clickAction: {
                    self.vwProfileFullName.txtName.becomeFirstResponder()
                })
                return false
            } else if (self.vwProfileEmail.txtName.text?.isEmpty)! {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyEmailAdress.rawValue, clickAction: {
                    self.vwProfileEmail.txtName.becomeFirstResponder()
                })
                return false
            } else if !Helper.isValidEmail(self.vwProfileEmail.txtName.text!) {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.invalidEmailAddress.rawValue, clickAction: {
                    self.vwProfileEmail.txtName.becomeFirstResponder()
                })
                return false
            }
        }
        return true
    }
    
    @IBAction func btnChangePasswordTapped(_ sender: UIButton) {
        self.tableView.isScrollEnabled = false
        self.appdelegate = UIApplication.shared.delegate as! AppDelegate
        self.vwChangePassword.frame = (self.appdelegate.window?.frame)!
        self.appdelegate.window?.addSubview(self.vwChangePassword)
        self.btnChangeCurrentPassword.addGradientToBackground()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissChangePasswordView(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        self.vwChangePassword.addGestureRecognizer(tapGesture)
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: self.mainVCChangePass) ?? false {
            return false
        }
        return true
    }
    
    
    @objc func dismissChangePasswordView(_ sender: UITapGestureRecognizer) {
        self.vwChangePassword.removeFromSuperview()
        self.tableView.isScrollEnabled = true
    }
    
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        if isValid(isChangePass: false) {
            self.WSSaveProfileCalled()
        }
    }
    @IBAction func btnChangeCurrentPasswordTapped(_ sender: UIButton) {
        if isValid(isChangePass: true) {
            let parameter: [String: Any] = [WebserviceRequestParmeterKey.password:vwCurrentPassword.txtName.text!,
                                            WebserviceRequestParmeterKey.newPassword:vwNewPassword.txtName.text!]
            
            Helper.showProgressBar()
            ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.changePassword, parameter: parameter, onCompletion: { (json, error, response) in
                if error == nil {
                    if let msg = json.dictionaryObject!["msg"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: msg, clickAction: {
                            self.vwChangePassword.removeFromSuperview()
                            self.vwCurrentPassword.txtName.text = ""
                            self.vwNewPassword.txtName.text = ""
                            self.vwConfirmPassword.txtName.text = ""
                        })
                    }
                    if let errorMessage = json.dictionaryObject!["error"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                    }
                } else {
                    print(error?.localizedDescription ?? "curr pass api error response")
                }
                Helper.hideProgressBar()
            }, onError: { (error, response) in
                print(error?.localizedDescription ?? "almofire error")
                Helper.hideProgressBar()
                if error?.code == Helper.networkNotAvailableCode {
                    Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
                }
            })
        }
    }
    
    @objc func btnVideoTapped(_ sender: UIButton) {
    }

}

// MARK: - UINavigationControllerDelegate, UIImagePickerControllerDelegate methods
extension ProfileTableViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: false, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.imgProfilePicture.image = info[UIImagePickerControllerEditedImage] as? UIImage
        dismiss(animated: false, completion: nil)
        
        let image = Helper.resizedImage(image: self.imgProfilePicture.image!, newSize: CGSize(width: 300, height: 300))
        Helper.showProgressBar()
        Helper.WSGetPresingedUrl { (isSucess) in
            if isSucess {
                let url = UserDefaultHelper.getPREF(AppUserDefaults.pref_presignedUrl)
                
                ApiManager.Instance.sendMultiPartAWS(path: url!, imgData: UIImageJPEGRepresentation(image, 1.0)!, onComplete: { (json, error, response) in
                    if error == nil {
                        if (response as! HTTPURLResponse).statusCode == 200 {
                            //print("upload",json)
                            self.isURLUploadedToAWS = true
                            self.WSSaveProfileCalled()
                        }
                    }
                    Helper.hideProgressBar()
                }) { (error, response) in
                    print(error?.localizedDescription ?? "error")
                    Helper.hideProgressBar()
                }
            }
        }
        
    }
}

extension ProfileTableViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.tableView.isScrollEnabled = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.vwCurrentPassword.txtName {
            self.vwNewPassword.txtName.becomeFirstResponder()
        } else if textField == self.vwNewPassword.txtName {
            self.vwConfirmPassword.txtName.becomeFirstResponder()
        } else {
            self.vwConfirmPassword.txtName.resignFirstResponder()
        }
        return true
    }
}

//MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension ProfileTableViewController: UICollectionViewDataSource,UICollectionViewDelegate ,UICollectionViewDelegateFlowLayout{
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 5 {
            if self.arrRecentStories!.count > 0 {
                return 280.0
            } else {
                return 0.0
            }
        } else {
            return 85.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let data = arrRecentStories else {
            return 0
        }
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = self.arrRecentStories![indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HistroyImageView", for: indexPath) as! HistroyImageView
        
        if data.feedType == StoryType.storyVideo.rawValue {
            cell.btnVideo.isHidden = false
            cell.btnVideo.tag = indexPath.row
            cell.btnVideo.addTarget(self, action: #selector(btnVideoTapped(_:)), for: .touchUpInside)
        } else {
            cell.btnVideo.isHidden = true
        }
        
        DispatchQueue.main.async {
            cell.imgRecentStory.layer.cornerRadius = cell.imgRecentStory.frame.size.width/2
            cell.imgRecentStory.clipsToBounds = true
        }
        cell.imgRecentStory.sd_setShowActivityIndicatorView(true)
        cell.imgRecentStory.sd_setIndicatorStyle(.whiteLarge)
        
        var imgThumb300 : String = ""
        for path in data.media.thumbs {
            if path.size == ThumbSize.thumb_300x300.rawValue {
                imgThumb300 = path.path
            }
        }
        // data.media.thumbs[3].path
        cell.imgRecentStory.sd_setImage(with: URL(string: imgThumb300), placeholderImage: nil, completed: nil)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dictProfile = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
        let profileData = Profile(dictionary: dictProfile)
        let selectedStory = self.arrRecentStories![indexPath.row]
        var profileImage : String = ""
        if let profilePic = profileData.profilePic {
            profileImage = profilePic
        }
        let ownerDetails = owner(name: self.lblProfileName.text!, image: #imageLiteral(resourceName: "img_placeholder"), originalImage: profileImage)
        var arrFeeds = [feed]()
        let feedCon = feedContant { (feeds) in
            // (selectedStory.feedType == StoryType.storyImage.rawValue ? selectedStory.media.thumbs[1].path : selectedStory.media.thumbs[1].path)
            
            var imgThumb750 : String = ""
            for path in selectedStory.media.thumbs {
                if path.size == ThumbSize.thumb_750x1334.rawValue {
                    imgThumb750 = path.path
                }
            }
            
            let createdDate = Date().getDifferanceFromCurrentTime(serverDate: selectedStory.createdAt! as Date)
            let storyMedia = feed(seenStoryId: "", thumbId: "", thumb: "", orignalMedia: (selectedStory.feedType == StoryType.storyImage.rawValue ? imgThumb750 : selectedStory.media.path ), feedId: selectedStory._id, time: createdDate, discription: selectedStory.caption, lits: "", comments: "", mediaType: (selectedStory.feedType == StoryType.storyImage.rawValue ? mediaType.image : mediaType.video ), owner: ownerDetails, type: .activateStory, duration: selectedStory.media.duration, viewers: selectedStory.viewers, branchLink: "", masterIndex: nil, index: nil, individualFeedType: individualFeedType.init(rawValue: selectedStory.feedType)!, privacyLevel: privacyLevel(rawValue: selectedStory.privacy.level)!)
            
            arrFeeds.append(storyMedia)
            
            feeds.feedList = arrFeeds
            feeds.bottomtype = (indexPath.row == 0 ? .eye :.activateStoryWithEye)
            feeds.feedType = .story
            feeds.owner = ownerDetails
            feeds.turnSoket =  false
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! HistroyImageView
        let configuration = ImageViewerConfiguration { config in
            config.imageView = cell.imgRecentStory
            config.actiondelegate = self
        }
        DispatchQueue.main.async {
            self.present(ImageViewerController(configuration: configuration, contant: feedCon), animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: self.collectionHistory.frame.width/3.0 , height: self.collectionHistory.frame.width/3.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0,0,0,0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension ProfileTableViewController: ActionDelegate{
    func sendGoLiveRequest(index: Int) {
    }
    
    func markAsStroySeenAt(masterIndex: Int, index: Int) {
    }
    
    func actionTrigered(action: actionType, masterIndex: Int?, index: Int?, feedId: String, mediaUrl: String, base: UIViewController, baseFeedType: feedType) {
        if action == .viewerList {
            let list = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.requestList.rawValue) as! RequestListViewController
            list.listType = ""
            list.feedId = feedId
            base.present(UINavigationController(rootViewController: list), animated: true, completion: {
                // UIApplication.shared.isStatusBarHidden = false
            })
        } else if action == .more {
            openActionSheet(feedId: feedId, base: base)
        }
    }

    func startListen(action: actionType, feedId: String) {
    }
    
    func markAsViewed(feedId: String) {
    }
    
    func shouldMakeIt(active: Bool, feedId: String) {
        self.activateFeed(feedId: feedId)
    }
}

class HistroyImageView: UICollectionViewCell {
    @IBOutlet weak var imgRecentStory: UIImageView!
    @IBOutlet weak var btnVideo: UIButton!
}
