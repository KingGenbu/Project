//
//  NotificationViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 27/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import SimpleImageViewer

class NotificationViewController : UIViewController {
    
    @IBOutlet var tblNotificationList: UITableView!
    @IBOutlet var vwNoificationHeader: UIView!
    @IBOutlet weak var lblNotificationCount: UILabel!
    
    var arrSeenNotification = [String]()
    var arrNotificationList = NotificationModel()
    var arrFeedDetail = FeedDetailModel()
    var lblNoDataFound : UILabel!
    var iTotalCount: Int = 0
    var totalCount:Int = 0
    var pageNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblNotificationList.isHidden = true
        self.WSNotificationListCalled(pageNumber: 1)
        self.WSGetLiveRequestCount()
//        self.arrSeenNotification = UserDefaultHelper.getArrPREF("pref_notification_seen") ?? [String]()
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
        
        tblNotificationList.layer.cornerRadius = 2.0
        tblNotificationList.layer.borderWidth = 0.25
        tblNotificationList.layer.borderColor = UIColor.lightGray.cgColor
        
        self.navigationController?.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.isHidden = false
        self.title = ViewControllerTitle.notification.rawValue
        
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        
        let btnBackBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnBackBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = btnBackBarButton
        
        self.tblNotificationList.estimatedRowHeight = 80.0
        self.tblNotificationList.estimatedSectionHeaderHeight = 60.0
    }
    
    /// Navigation left bar back button
    @objc func btnBackBarButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Set Label text if no data available
    func setupNoDataLabel() {
        self.lblNoDataFound = UILabel(frame: CGRect(x: (self.view.frame.origin.x / 2), y: (self.view.frame.origin.y / 2) - 64, width: self.view.frame.width, height: 100))
        
        self.lblNoDataFound.text = AppMessage.notNotificationFound.rawValue
        
        self.lblNoDataFound.textColor = UIColor(red: 23.0/255.0, green: 23.0/255.0, blue: 23.0/255.0, alpha: 1)
        
        self.lblNoDataFound.center = self.view.center
        self.lblNoDataFound.textAlignment = .center
        self.lblNoDataFound.font = UIFontConst.POPPINS_REGULAR
        
    }
    
    /// WS called to get notification list
    func WSNotificationListCalled(pageNumber: Int) {
       
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.notificationList + "?page=" + "\(pageNumber)", onComplete: { (json, error, reponse) in
            if error == nil {
                if (reponse as! HTTPURLResponse).statusCode == 200 {
                    if let dict = json.dictionaryObject {
                        if let dictNotificationList = dict["notificationsList"] as? [String:Any] {
                            
                            if let page = dictNotificationList["page"] as? String {
                                self.pageNumber = Int(page)!
                            }
                            if let totalPages = dictNotificationList["pages"] as? Int {
                                self.totalCount = totalPages
                            }
                            if let arrNoti = dictNotificationList["docs"] as? [[String: Any]] {
                                
                                if self.arrFeedDetail.arrFeedDetails == nil {
                                    self.arrFeedDetail.arrFeedDetails = []
                                }
                                
                                var feedDetail = FeedDetail(values: [:])
                                
                                for item in arrNoti {
                                    feedDetail = FeedDetail(values: item)
                                    self.arrFeedDetail.arrFeedDetails.append(feedDetail)
                                }
                                
                                if self.arrNotificationList.notification == nil {
                                    self.arrNotificationList.notification = []
                                }
                                
                                var notification = NotificationList(values: [:])
                                
                                for item in arrNoti {
                                    notification  = NotificationList(values: item)
                                    self.arrNotificationList.notification?.append(notification)
                                }
                                if self.arrNotificationList.notification!.count <= 0 {
                                    self.tblNotificationList.isHidden = true
                                    self.setupNoDataLabel()
                                    self.view.addSubview(self.lblNoDataFound)
                                } else {
                                    self.tblNotificationList.isHidden = false
                                    self.tblNotificationList.reloadData()
                                }
                            }
                        }
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
    
    /// WS Call: Get Live Request Count
    func WSGetLiveRequestCount() {
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.liverequestCount, onComplete: { (json, error, response) in
            if error == nil{
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let arrDoc = json.dictionaryObject!["doc"] as? [[String: Any]] {
                        
                        for item in arrDoc {
                            if let totalCount = item["totalcount"] as? Int {
                                self.iTotalCount = totalCount
                            }
                        }
                        self.lblNotificationCount.isUserInteractionEnabled = true
                        self.lblNotificationCount.text = "\(self.iTotalCount) Live Request"
                        self.lblNotificationCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.navigateToCommentList(_:))))
                    }
                    
                } else {
                    print(error?.localizedDescription ?? "error")
                }
            } else {
                print(error?.localizedDescription ?? "error")
            }
        }) { (error, response) in
            print(error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
        }
    }
    
    /// Navigate to Live Request VC if there is live request notification
    @objc func navigateToCommentList(_ sender: UITapGestureRecognizer) {
        let requestListVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.requestList.rawValue) as! RequestListViewController
        requestListVC.listType = "request"
        Helper.Push_Pop_to_ViewController(destinationVC: requestListVC, isAnimated: true, navigationController: self.navigationController!)
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate methods
extension NotificationViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.iTotalCount == 0 {
            return 0.0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        self.vwNoificationHeader.frame = CGRect(x: 0, y: 0, width: self.tblNotificationList.frame.width, height: self.vwNoificationHeader.frame.height)
        
        return self.vwNoificationHeader
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let notification = self.arrNotificationList.notification else {
            return 0
        }
        return notification.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notificationData = self.arrNotificationList.notification![indexPath.row]
        let feedDetail = self.arrFeedDetail.arrFeedDetails[indexPath.row]
        let notificationCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.notificationCell.rawValue, for: indexPath) as! NotificationCell
        
        DispatchQueue.main.async {
            notificationCell.imgProfilePic.layer.cornerRadius = notificationCell.imgProfilePic.frame.height / 2.0
            notificationCell.imgProfilePic.layer.masksToBounds = true
        }
        if let url = notificationData.profilePic {
            notificationCell.imgProfilePic.sd_setImage(with: URL(string: url), completed: nil)
        } else {
             notificationCell.imgProfilePic.image = UIImage(named: "img_profile")
        }
        
        if let message = notificationData.message {
            notificationCell.lblNotificationData.text = message
        }
        
        if let createdAt = notificationData.createdAt {
            notificationCell.lblNotificationTime.text = Date().getDifferanceFromCurrentTime(serverDate: createdAt)
        }
        
//        if self.arrSeenNotification.count > 0 {
//            for seenNotification in arrSeenNotification {
//                if seenNotification.count > 0 {
//                    if notificationData._id == seenNotification {
//                        notificationData.isNotificationSeen = true
//                        notificationCell.imgReplay.isHidden = notificationData.isNotificationSeen
//                    }
//                }
//            }
//        }
        
        if notificationData.notificationType == NotificationType.itzlitDone.rawValue {
            notificationCell.imgProfilePic.sd_setShowActivityIndicatorView(true)
            notificationCell.imgProfilePic.sd_setIndicatorStyle(.gray)

            if feedDetail.feedType == "LiveStreamVideo" {
                var thumbSize300 : String = ""
                if let thumSize = notificationData.thumbsize {
                    if thumSize == ThumbSize.thumb_300x300.rawValue {
                        thumbSize300 = thumSize
                    }
                }
                var path: String = ""
                if thumbSize300 == ThumbSize.thumb_300x300.rawValue {
                    if let path300 = notificationData.thumbpath{
                        path = path300
                    }
                }
                
                notificationCell.imgProfilePic.sd_setImage(with: URL(string: path), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
            } else {
                notificationCell.imgProfilePic.sd_setImage(with: URL(string: "http://18.220.124.147:8086/thumbnail?application=live&streamname=\(feedDetail.mediaDict?.streamID ?? "")&size=300x300&fitmode=crop"), completed: nil)
            }
        } else if notificationData.notificationType == NotificationType.typeStory.rawValue {
            var thumbSize300 : String = ""
            if let thumSize = notificationData.thumbsize {
                if thumSize == ThumbSize.thumb_300x300.rawValue {
                    thumbSize300 = thumSize
                }
            }
            var path: String = ""
            if thumbSize300 == ThumbSize.thumb_300x300.rawValue {
                if let path300 = notificationData.thumbpath{
                    path = path300
                }
            }
            notificationCell.imgProfilePic.sd_setImage(with: URL(string: path),placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        }
        
        return notificationCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notificationData = self.arrNotificationList.notification![indexPath.row]
//        notificationData.isNotificationSeen = !notificationData.isNotificationSeen
//        print(notificationData.isNotificationSeen)
//
//        if !self.arrSeenNotification.contains(notificationData._id!) {
//            self.arrSeenNotification.append(notificationData._id!)
//        }
//        print(notificationData.isNotificationSeen)
//        UserDefaultHelper.setArrPREF(self.arrSeenNotification, key: "pref_notification_seen")
        let feedDetail = self.arrFeedDetail.arrFeedDetails[indexPath.row]
        if notificationData.notificationType == NotificationType.typeIsLive.rawValue {
            
            let viewliveVideoVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.viewLiveVideoVC.rawValue) as! ViewLiveVideoViewController
            viewliveVideoVC.isFromNotificationList = true
            guard let mediaPathURL = feedDetail.mediaDict?.path else {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.liveStreamRemoved.rawValue, clickAction: {})
                return
            }
            viewliveVideoVC.mediaPathURL = mediaPathURL
             if let strFullName = feedDetail.userFullName {
                viewliveVideoVC.strFullName = strFullName
            }
            if let strProfilePic = notificationData.profilePic {
                viewliveVideoVC.strProfilePic = strProfilePic
            }
            if let strCaption = feedDetail.caption {
                viewliveVideoVC.strProfilePic = strCaption
            }
            if let iViewers = feedDetail.viewers {
                viewliveVideoVC.iViewers = iViewers
            }
            
            self.navigationController?.present(UINavigationController(rootViewController: viewliveVideoVC), animated: true, completion: nil)
         
        } else if notificationData.notificationType == NotificationType.typeFollow.rawValue {
            let removeItzlitFriindVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.removeItzlitFriend.rawValue) as! RemoveIZLITFreindsVC
            removeItzlitFriindVC.isFromNotification = true
            Helper.Push_Pop_to_ViewController(destinationVC: removeItzlitFriindVC, isAnimated: true, navigationController: self.navigationController!)
        } else if notificationData.notificationType == NotificationType.typeStory.rawValue {
            guard let _ = feedDetail.userFullName  else {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.storyRemoved.rawValue, clickAction: {})
                return
            }
            let ownerDetails = owner(name: feedDetail.userFullName!, image: #imageLiteral(resourceName: "img_profile"), originalImage: feedDetail.userProfilePic ?? "")
            var arrFeeds = [feed]()
            let feedCon = feedContant { (feeds) in 
                guard let mediaPathURL = feedDetail.mediaDict?.path else {return}
                let createdDate = Date().getDifferanceFromCurrentTime(serverDate: (feedDetail.mediaDict?.createdAt as Date?)!)
 
                let storyMedia = feed(seenStoryId: "", thumbId: "", thumb: "", orignalMedia: mediaPathURL, feedId: "", time: createdDate, discription: "", lits: "", comments: "", mediaType: (feedDetail.feedType! == StoryType.storyImage.rawValue ? mediaType.image : mediaType.video ), owner: ownerDetails, type: .none,duration: (feedDetail.mediaDict?.duration)!, viewers: 0, branchLink: feedDetail.branchLink ?? "", masterIndex: nil, index: nil, individualFeedType: individualFeedType.init(rawValue: feedDetail.feedType!)!, privacyLevel: privacyLevel(rawValue: feedDetail.privacyLevel!)!)
 
                arrFeeds.append(storyMedia)
                
                feeds.feedList = arrFeeds
                feeds.bottomtype = .none
                feeds.feedType = .story
                feeds.owner = ownerDetails
                feeds.turnSoket =  false
                feeds.isFromNotification = true
            }
            let notificationCell = tableView.cellForRow(at: indexPath)as! NotificationCell
            
            let configuration = ImageViewerConfiguration { config in
                config.imageView = notificationCell.imgProfilePic
            }
            
            DispatchQueue.main.async {
                self.navigationController?.present(ImageViewerController(configuration: configuration, contant: feedCon), animated: true, completion: nil)
            }
        } else if notificationData.notificationType == NotificationType.goLiveReq.rawValue {
            let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
            Helper.Push_Pop_to_ViewController(destinationVC: liveStreamingConfig, isAnimated: true, navigationController: self.navigationController!)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if pageNumber < totalCount && indexPath.row == (arrNotificationList.notification!.count - 2) {
            self.pageNumber += 1
            self.WSNotificationListCalled(pageNumber: self.pageNumber)
        }
    }
}
