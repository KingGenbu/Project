//
//  SendToViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 30/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import SwiftyJSON
class SendToViewController: UIViewController {
    
    @IBOutlet var lblSelectFriend: UILabel!
    @IBOutlet var lblPublicPrivate: UILabel!
    @IBOutlet var lblStory: UILabel!
    @IBOutlet var switchPublicPrivate: UISwitch!
    @IBOutlet var tblFriends: UITableView!
    @IBOutlet var btnSend: UIButton!
    @IBOutlet var lblSelected: UILabel!
    @IBOutlet weak var vwHeader: UIView!
    
    @IBOutlet var vwSearch: UIView!
    @IBOutlet var txtSearch: UITextField!
    @IBOutlet weak var btnClearPrivateSelection: UIButton!
    
    var btnBackBarButton = UIBarButtonItem()
    var btnSearchBarButton = UIBarButtonItem()
    var isSearch: Bool = false
    var lblNoDataFound : UILabel!
    var mediaType:String!
    var shardImage:UIImage!
    var sharedVideo:URL!
    var arrFollower = [FollowList]()
    var arrSelectedFollower = [String]()
    var strAboutStrory:String!
    var totalCount:Int = 0
    var pageNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.vwHeader.dropShadow(scale: true)
        
        switchPublicPrivate.tintColor = UIColor.lightGray
        tblFriends.layer.cornerRadius = 2.0
        tblFriends.layer.borderWidth = 0.25
        tblFriends.layer.borderColor = UIColor.lightGray.cgColor
        arrSelectedFollower = UserDefaultHelper.getArrPREF("pref_selection") ?? [String]()
        
        self.followerListApi(searchName: "", pageNumber: 1, onComplete: { (responce, error, url) in
            self.tblFriends.reloadData()
        })
        
        self.txtSearch.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.font: UIFontConst.ROBOTO_LIGHT ?? UIFont.boldSystemFont(ofSize: 14.0)])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
        self.setupNoDataLabel()
        self.setToPublic()
    }
    
    @IBAction func btnClearPrivateSelectionTapped(_ sender: UIButton) {
 
        for follower in self.arrFollower {
            if self.arrSelectedFollower.contains(follower._id) {
                let index = self.arrSelectedFollower.index(of: follower._id)
                if index != nil {
                    self.arrSelectedFollower.remove(at: index!)
                }
            }
            UserDefaultHelper.setArrPREF(self.arrSelectedFollower, key: "pref_selection")
            
            if follower.isselected == true {
               follower.isselected = false
            }
        }
        
        self.tblFriends.reloadData()
        setSelectedText()
    }
    
    func setupNoDataLabel() {
        self.lblNoDataFound = UILabel(frame: CGRect(x: (self.view.frame.origin.x / 2), y: (self.view.frame.origin.y / 2) - 64, width: self.view.frame.width, height: 100))
        
        self.lblNoDataFound.text = AppMessage.publicText.rawValue
        self.lblNoDataFound.textColor = UIColor(red: 23.0/255.0, green: 23.0/255.0, blue: 23.0/255.0, alpha: 1)
        self.lblNoDataFound.center = self.view.center
        self.lblNoDataFound.textAlignment = .center
        self.lblNoDataFound.font = UIFontConst.POPPINS_REGULAR
    }
    
    func setToPublic()  {
        if self.navigationItem.titleView != nil {
            self.navigationItem.titleView = nil
            self.navigationItem.rightBarButtonItem = nil
        }
        self.navigationItem.leftBarButtonItem = btnBackBarButton
        self.switchPublicPrivate.isOn = true
        lblSelected.text = "Public"
         self.strAboutStrory.isEmpty ? (self.lblStory.text =  "No caption") : (self.lblStory.text = strAboutStrory)
        self.lblPublicPrivate.text = "My Story"
        self.lblSelectFriend.isHidden = true
        self.btnClearPrivateSelection.isHidden = true
        self.navigationItem.rightBarButtonItem = nil
        self.tblFriends.isHidden = true
        self.view.addSubview(self.lblNoDataFound)
    }
    
    func setToFriend()  {
        
        self.navigationItem.rightBarButtonItem = self.btnSearchBarButton
        self.switchPublicPrivate.setOn(false, animated: true)
        self.lblPublicPrivate.text = "Private"
        self.tblFriends.isHidden = false
        self.lblSelectFriend.isHidden = false
        lblSelected.text = "Selected 0"
        self.lblNoDataFound.removeFromSuperview()
        if self.arrFollower.count > 0 {
            for itemFollower in self.arrFollower {
                for item in self.arrSelectedFollower {
                    if itemFollower._id == item {
                        itemFollower.isselected = true
                    }
                }
            }
            if arrSelectedFollower.count > 0 {
                self.btnClearPrivateSelection.isHidden = false
            } else {
                self.btnClearPrivateSelection.isHidden = true
            }
            tblFriends.reloadData()
        } else {
            self.followerListApi(searchName: "", pageNumber: 1, onComplete: { (responce, error, url) in
                
                self.tblFriends.reloadData()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureUI() {
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.isHidden = false
        self.title = ViewControllerTitle.sendTo.rawValue
        
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        
        btnBackBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnBackBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = btnBackBarButton
        
        btnSearchBarButton = UIBarButtonItem(image: UIImage(named: "img_search"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnSearchBarButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = btnSearchBarButton
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        statusBar.tintColor = .white
    }
    
    //MARK:- follower List
    func followerListApi(searchName: String, pageNumber: Int, onComplete: @escaping ServiceResponse)  {
        Helper.showProgressBar()
        var url = ""
        if self.isSearch == true {
            url = WebserverPath.followerList+"?q=\(searchName)&page="+"\(pageNumber)"
        } else {
            url = WebserverPath.followerList+"?page="+"\(pageNumber)"
        }
        ApiManager.Instance.sendHttpGetWithHeader(path: url, onComplete: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if (((json.dictionaryObject!["followers"] as! [String: Any])["docs"]!) as AnyObject).count > 0 {
                        self.arrFollower = FollowList.Populate(list: ((json.dictionaryObject!["followers"] as! [String: Any])["docs"]! as! NSArray))
                        
                        if let totalPages = ((json.dictionaryObject!["followers"] as! [String: Any])["pages"]! as? Int)  {
                            self.totalCount = totalPages
                            if let pageNumber = ((json.dictionaryObject!["followers"] as! [String: Any])["page"]! as? Int) {
                                self.pageNumber =  pageNumber
                            }
                        }
                        onComplete(JSON.null,nil,nil)
                    } else {
                        if self.isSearch == true {
                            self.arrFollower = []
                            onComplete(JSON.null,nil,nil)
                        }
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
    
    @objc func btnBackBarButtonTapped(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc func btnSearchBarButtonTapped(_ sender: UIBarButtonItem) {
        self.navigationItem.hidesBackButton = true
        self.navigationItem.titleView = self.vwSearch
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = nil
        self.isSearch = true
        self.txtSearch.delegate = self
        self.txtSearch.becomeFirstResponder()
    }
    
    @IBAction func btnCloseTapped(_ sender: UIButton) {
        self.navigationItem.titleView = nil
        self.txtSearch.delegate = nil
        self.isSearch = false
        self.navigationItem.rightBarButtonItem = self.btnSearchBarButton
        self.navigationItem.leftBarButtonItem = self.btnBackBarButton
        self.followerListApi(searchName: "", pageNumber: 1, onComplete: { (_, _, _) in
            self.txtSearch.text = ""
            self.tblFriends.reloadData()
        })
    }
    
    @IBAction func btnSwitchTapped(_ sender: UISwitch) {
        if sender.isOn {
            self.setToFriend()
        } else {
            self.setToPublic()
        }
        tblFriends.reloadData()
    }
    @IBAction func btnSendTapped(_ sender: UIButton) {
        self.navigationItem.titleView = nil
        let selectedUsers = self.arrFollower.filter({$0.isselected == true})
        
        if self.switchPublicPrivate.isOn {
            self.ShareStory()
        } else {
            if selectedUsers.count > 0  {
                ShareStory()
            } else {
                Helper.showAlertDialog(APP_NAME, message: ValidationMessage.selectUser.rawValue, clickAction: {})
            }
        }
        
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    func ShareStory() {
        Helper.showProgressBar()
        let selectedUsers = self.arrFollower.filter({$0.isselected == true})
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.aboutStory: self.strAboutStrory, WebserviceRequestParmeterKey.feedType: mediaType!,WebserviceRequestParmeterKey.privacyLevel :(switchPublicPrivate.isOn ? "Public":"Private"),WebserviceRequestParmeterKey.sharedWith:selectedUsers.map({$0.follower._id}).joined(separator: ",")]
        var mediaData = Data()
        if mediaType == "StoryImage" {
            mediaData = UIImageJPEGRepresentation(shardImage, 1)!
                //UIImagePNGRepresentation(shardImage)!
        } else{
            //do {
            guard let _ = NSData(contentsOf: sharedVideo as URL) else {
                return
            }
            
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mp4"/*.m4v"*/)
            compressVideo(inputURL: sharedVideo as URL, outputURL: compressedURL) { (exportSession) in
                guard let session = exportSession else {
                    return
                }
                
                switch session.status {
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    guard let compressedData = NSData(contentsOf: compressedURL) else {
                        return
                    }
                    mediaData = compressedData as Data
                    
                    ApiManager.Instance.sendMultiPart(path: WebserverPath.CreateStory, formData: parameter as! [String : String], imgData:  mediaData,  isVideo: (self.mediaType == "StoryImage" ? false : true) , onComplete: { (json, error, reponsereponse) in
                        Helper.hideProgressBar()
                        if error == nil {
                            if (reponsereponse as! HTTPURLResponse).statusCode == 200  {
                                Helper.showAlertDialog(APP_NAME, message: "Your story has been shared successfully.", clickAction: {
                                    if self.switchPublicPrivate.isOn {
                                        self.navigateToFeedViewController()
                                    } else {
                                        self.dismiss(animated: false, completion: nil)
                                    }
                                })
                            }
                        }
                    }) { (error, response) in
                        Helper.hideProgressBar()
                        print(error ?? "error")
                        if error?.code == Helper.networkNotAvailableCode {
                            Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
                        }
                    }
                    
                case .failed:
                    break
                case .cancelled:
                    break
                }
            }
 
        }
        if mediaType == "StoryImage" {
            ApiManager.Instance.sendMultiPart(path: WebserverPath.CreateStory, formData: parameter as! [String : String], imgData:  mediaData,  isVideo: (mediaType == "StoryImage" ? false : true) , onComplete: { (json, error, reponsereponse) in
                Helper.hideProgressBar()
                if error == nil {
                    if (reponsereponse as! HTTPURLResponse).statusCode == 200  {
                        Helper.showAlertDialog(APP_NAME, message: "Your story has been shared successfully.", clickAction: {
                            if self.switchPublicPrivate.isOn {
                                self.navigateToFeedViewController()
                            } else {
                                self.dismiss(animated: false, completion: nil)
                            }
                        })
                    }
                }
            }) { (error, response) in
                Helper.hideProgressBar()
                print(error ?? "error")
                if error?.code == Helper.networkNotAvailableCode {
                    Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
                }
            }
        }
        //        let selectedUsers = self.arrFollower.filter({$0.isFollowed == true})
        //        for item in selectedUsers {
        //
        //        }
    }
    
    func navigateToFeedViewController()  {
        var isFeedVC:Bool = false
        var arrNavigationController = self.navigationController?.viewControllers
        for controller in arrNavigationController! {
            if controller.isKind(of: FeedViewController.self) {
                let indexOfReg = arrNavigationController?.index(of: controller)
                arrNavigationController?.remove(at: indexOfReg!)
                self.navigationController?.viewControllers = arrNavigationController!
                isFeedVC = true
                let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
            }
        }
        if !isFeedVC {
            let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
            Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
        }
        
    }
    
    @objc func btnCheckUncheckTapped(_ sender : UIButton) {
        self.arrFollower[sender.tag].isselected =  !self.arrFollower[sender.tag].isselected
        if !self.arrSelectedFollower.contains(self.arrFollower[sender.tag]._id) {
            self.arrSelectedFollower.append(self.arrFollower[sender.tag]._id)
        } else {
            let index = self.arrSelectedFollower.index(of: self.arrFollower[sender.tag]._id)
            if index != nil {
                self.arrSelectedFollower.remove(at: index!)
            }
         }
        UserDefaultHelper.setArrPREF(self.arrSelectedFollower, key: "pref_selection")
        self.tblFriends.reloadData()
        setSelectedText()
    }
    
    func setSelectedText()  {
        let selectedUsers = self.arrFollower.filter({$0.isselected == true})
        lblSelected.text = "Selected \(selectedUsers.count)"
        if selectedUsers.count > 0 {
            self.btnClearPrivateSelection.isHidden = false
        } else {
            self.btnClearPrivateSelection.isHidden = true
        }
    }
}

extension SendToViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.followerListApi(searchName: textField.text!, pageNumber: 1) { (json, error, response) in
            for item in self.arrFollower  {
                item.isselected = false
            }
            if self.arrFollower.count <= 0 {
                Helper.showAlertDialog(APP_NAME, message: "No search found", clickAction: {})
            } else {
                self.tblFriends.reloadData()
            }
            textField.resignFirstResponder()
        }
        return true
    }
}

extension SendToViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrFollower.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = arrFollower[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.sendToCell.rawValue, for: indexPath) as! SendToCell
        if  data.follower.fullName != "" {
            cell.lblName.text = data.follower.fullName
        }
        if let url = URL(string: data.follower.profilePic) {
            cell.imgProfilePicture.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        } else{
            cell.imgProfilePicture.image = #imageLiteral(resourceName: "img_profile")
        }
        
        cell.imgProfilePicture.layer.cornerRadius = 8.0
        
        cell.btnCheckUncheck.tag = indexPath.row
        cell.btnCheckUncheck.addTarget(self, action: #selector(btnCheckUncheckTapped(_:)), for: UIControlEvents.touchUpInside)
        
        cell.btnCheckUncheck.isSelected = arrFollower[indexPath.row].isselected
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if pageNumber < totalCount && indexPath.row == (arrFollower.count - 5) {
            self.pageNumber += 1
            self.followerListApi(searchName: "", pageNumber: pageNumber, onComplete: { (responce, error, url) in
            })
            tableView.reloadData()
        }
    }
}
