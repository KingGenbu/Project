//  FeedViewController.swift
//  ITZLIT
//  Created by devang.bhatt on 01/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.



import SDWebImage
import UIKit
import SimpleImageViewer
import SocketIO

class FeedViewController: UIViewController {
    //MARK:- Outlets & variables
    @IBOutlet var tblFeed: UITableView!
    var arrfeedList:[ItFeedList]!
    @IBOutlet weak var lblRequesrCount: UILabel!
    @IBOutlet var viewForHeader: UIView!
    var arrRecentStories : [ItFeedList]? = []
    var isShowingOwnFeed = false
    @IBOutlet weak var btnShowLive: UIButton!
    @IBOutlet weak var imgProfileLive: UIImageView!
    @IBOutlet weak var btnAddLive: UIButton!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var btnAddStory: UIButton!
    @IBOutlet weak var btnShowMyStory: UIButton!
    var refreshControl : UIRefreshControl = UIRefreshControl()
    var totalCount:Int = 0
    var pageNumber = 0
//    var lblNoDataFound : UILabel!
    var timer : Timer?
    var storedOffsets = [Int: CGFloat]()
    var isFromStoryCapture: Bool = false
    var isTimerExecute:Bool = false
    var isAnimating:Bool = false
    var isMyStory: Bool = false
    var feedInfoView: FeedInfoView?
    var isShowFeedInfoView: Bool {
        return ((self.arrfeedList?.count ?? 0) > 0 || self.isShowingOwnFeed)
    }
    
    //MARK:- cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpBasicdata()
        getFeedList(pageNumber: 1) { (list) in
            self.tblFeed.dataSource = self
            self.tblFeed.delegate = self
            self.tblFeed.reloadData()
            self.getRequestCount(compilation: { (ready) in
                self.getMyStory(compilation: { (ready) in
                    self.refreshOwnLiveFeed()
                    self.setMyDetail()
                })
            })
        }
        ILSocketManager.shared.establishConnection(withParams: [:])
        ILSocketManager.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        configureFeedInfoView()
    }
    
    private func configureFeedInfoView() {
        guard feedInfoView == nil else {
            return
        }
        
        feedInfoView = Helper.loadFromNibNamed("FeedInfoView") as? FeedInfoView
        feedInfoView?.infoLabel.text = AppMessage.noFeedFound.rawValue
        feedInfoView?.infoLabel.textColor = UIColor(red: 23.0/255.0, green: 23.0/255.0, blue: 23.0/255.0, alpha: 1)
        feedInfoView?.infoLabel.center = self.tblFeed.center
        feedInfoView?.infoLabel.textAlignment = .center
        feedInfoView?.infoLabel.font = UIFontConst.POPPINS_REGULAR
        feedInfoView?.backgroundColor = .clear
        feedInfoView?.translatesAutoresizingMaskIntoConstraints = false
        feedInfoView?.isHidden = isShowFeedInfoView
        view.addSubview(feedInfoView!)
        
        feedInfoView?.inviteFriendsButton.addTarget(self, action: #selector(inviteFriendsButtonTap), for: .touchUpInside)
        feedInfoView?.inviteFriendsButton.layer.cornerRadius = 10.0
        feedInfoView?.inviteFriendsButton.layer.borderWidth = 1.5
        feedInfoView?.inviteFriendsButton.layer.borderColor = UIColor(red: 7.0/255.0, green: 20.0/255.0, blue: 46.0/255.0, alpha: 1.0).cgColor
        
        feedInfoView?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15).isActive = true
        feedInfoView?.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15).isActive = true
        feedInfoView?.topAnchor.constraint(equalTo: tblFeed.topAnchor, constant: viewForHeader.frame.height + 50).isActive = true
        feedInfoView?.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    deinit {
        self.deinitItsoket()
    }
    
    //MARK:-Helper methods
    @IBAction func btnNavigateToStoryVC(_ sender: UIButton) {
        
        let storyInterfaceVC = Helper.storyShareStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.story.rawValue) as! StoryCapture
        Helper.Push_Pop_to_ViewController(destinationVC: storyInterfaceVC, isAnimated: true, navigationController: self.navigationController!)
    }
    
    @objc func pullToRefreshHandler() {
        
        self.refreshControl.beginRefreshing()
        getFeedList(pageNumber: 1) { (isSucess) in
            if isSucess {
                self.tblFeed.dataSource = self
                self.tblFeed.delegate = self
                self.tblFeed.reloadData()
                self.getRequestCount(compilation: { (ready) in
                    self.getMyStory(compilation: { (ready) in
                        self.refreshOwnLiveFeed()
                        self.setMyDetail()
                        self.refreshControl.endRefreshing()
                    })
                })
            }
        }
    }
    
    func refreshOwnLiveFeed() {
        if self.arrRecentStories!.count == 0 {
            self.btnAddStory.isHidden = false
            self.btnShowMyStory.isHidden = true
            self.btnAddLive.isHidden = false
            self.btnShowLive.isHidden = true
            return
        }
        
        if self.arrRecentStories![0].followingsFeeds.count != 0 {
            self.btnAddStory.isHidden = true
            self.btnShowMyStory.isHidden = false
        } else {
            self.btnAddStory.isHidden = false
            self.btnShowMyStory.isHidden = true
        }
        
        if self.arrRecentStories![0].liveFeeds.count != 0 {
            //Prepare own post data
            let dictProfile = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
            let profileData = Profile(dictionary: dictProfile)
            var profileImage : String = ""
            if let profilePic = profileData.profilePic {
                profileImage = profilePic
            }
            self.arrRecentStories![0].expanded = true
            self.arrRecentStories![0].fullName = profileData.fullName!
            self.arrRecentStories![0].profilePic = profileImage
            self.btnAddLive.isHidden = true
            self.btnShowLive.isHidden = false
            
            var imgThumb300ForLiveStream : String = ""
            let feed = self.arrRecentStories![0]
            if feed.liveFeeds.count > 0 {
                if feed.liveFeeds[0].feedType == "LiveStreamVideo" {
                    for path in feed.liveFeeds[0].thumbs {
                        if  path.size == ThumbSize.thumb_300x300.rawValue {
                            imgThumb300ForLiveStream = path.path
                        }
                    }
                } else {
                    imgThumb300ForLiveStream = "http://18.220.124.147:8086/thumbnail?application=live&streamname=\(feed.liveFeeds[0].streamId)&size=300x300&fitmode=crop"
                }
            } else {
                imgThumb300ForLiveStream = profileImage
            }
            self.imgProfileLive.sd_setImage(with: URL(string: imgThumb300ForLiveStream), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        } else {
            self.btnAddLive.isHidden = false
            self.btnShowLive.isHidden = true
            let dictProfile = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
            let profileData = Profile(dictionary: dictProfile)
            var profileImage : String = ""
            if let profilePic = profileData.profilePic {
                profileImage = profilePic
            }
            self.imgProfileLive.sd_setImage(with: URL(string: profileImage), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        }
    }
    
    func setUpBasicdata()  {
        self.btnAddStory.isHidden = true
        self.btnShowMyStory.isHidden = true
        self.btnAddLive.isHidden = true
        self.btnShowLive.isHidden = true
        lblRequesrCount.isUserInteractionEnabled = true
        lblRequesrCount.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(lbltappedView(_:))))
        self.tblFeed.rowHeight = UITableViewAutomaticDimension
        self.tblFeed.estimatedRowHeight = 255
        self.tblFeed.refreshControl = self.refreshControl
        self.refreshControl.addTarget(self, action: #selector(self.pullToRefreshHandler), for: .valueChanged)
        //self.timer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(self.refreshFeedListOnceAfter15Ssecond), userInfo: nil, repeats: false)
    }
    
    @objc private func refreshFeedListOnceAfter15Ssecond() {
        self.isTimerExecute = true
        getFeedList(pageNumber: 1) { (isSucess) in
            if isSucess {
                self.tblFeed.dataSource = self
                self.tblFeed.delegate = self
                self.tblFeed.reloadData()
                self.getRequestCount(compilation: { (ready) in
                    self.getMyStory(compilation: { (ready) in
                        self.refreshOwnLiveFeed()
                        if self.timer != nil {
                            self.timer?.invalidate()
                            self.timer = nil
                            print("timer nil")
                        }
                    })
                })
            }
        }
    }
    
    func configureUI() {
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        statusBar.tintColor = .white
        
        self.title = ViewControllerTitle.feed.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton
    }
    
    func setMyDetail() {
        let dictProfile = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
        let profileData = Profile(dictionary: dictProfile)
        var profileImage : String = ""
        if let profilePic = profileData.profilePic {
            profileImage = profilePic
        }
        if self.arrRecentStories!.count > 0 {
            let feed = self.arrRecentStories![0]
            var imgThumb300ForStories : String = ""
            var imgThumb300ForLiveStream : String = ""
            if feed.followingsFeeds.count > 0 {
                for path in feed.followingsFeeds[0].thumbs {
                    if  path.size == ThumbSize.thumb_300x300.rawValue {
                        imgThumb300ForStories = path.path
                    }
                }
            } else {
                imgThumb300ForStories = profileImage
            }
            self.imgProfile.sd_setShowActivityIndicatorView(true)
            self.imgProfile.sd_setIndicatorStyle(.gray)
            self.imgProfile.sd_setImage(with: URL(string: imgThumb300ForStories), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
            
            if feed.liveFeeds.count > 0 {
                if feed.liveFeeds[0].feedType == "LiveStreamVideo" {
                    for path in feed.liveFeeds[0].thumbs {
                        if  path.size == ThumbSize.thumb_300x300.rawValue {
                            imgThumb300ForLiveStream = path.path
                        }
                    }
                } else {
                    imgThumb300ForLiveStream = "http://18.220.124.147:8086/thumbnail?application=live&streamname=\(feed.liveFeeds[0].streamId)&size=300x300&fitmode=crop"
                }
                
            } else {
                imgThumb300ForLiveStream = profileImage
            }
            self.imgProfileLive.sd_setShowActivityIndicatorView(true)
            self.imgProfileLive.sd_setIndicatorStyle(.gray)
            self.imgProfileLive.sd_setImage(with: URL(string: imgThumb300ForLiveStream), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        } else {
            self.imgProfileLive.sd_setImage(with: URL(string: profileImage), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
            self.imgProfile.sd_setImage(with: URL(string: profileImage), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        }
    }
    
    //MARK:- owner Profile Buttoms
    @IBAction func btnNavigateToCameraStory(_ sender: UIButton) {
        let storyInterfaceVC = Helper.storyShareStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.story.rawValue) as! StoryCapture
        Helper.Push_Pop_to_ViewController(destinationVC: storyInterfaceVC, isAnimated: true, navigationController: self.navigationController!)
    }
    
    @IBAction func btnShowMyStoryAction(_ sender: Any) {
        self.isMyStory = true
        let dictProfile = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
        let profileData = Profile(dictionary: dictProfile)
        var profileImage : String = ""
        if let profilePic = profileData.profilePic {
            profileImage = profilePic
        }
        
        let ownerDetails = owner(name: profileData.fullName!, image: #imageLiteral(resourceName: "img_placeholder"), originalImage: profileImage)
        var arrFeeds = [feed]()
        let feedCon = feedContant { (feeds) in
            for item in 0..<self.arrRecentStories![0].followingsFeeds.count {
                let selectedStory = self.arrRecentStories![0].followingsFeeds[item]
                var imgThumb750 : String = ""
                for path in selectedStory.thumbs {
                    if path.size == ThumbSize.thumb_750x1334.rawValue {
                        imgThumb750 = path.path
                    }
                }
                
                let createdDate = Date().getDifferanceFromCurrentTime(serverDate: selectedStory.createdAt! as Date)
                let storyMedia = feed(seenStoryId: "", thumbId: "", thumb: "", orignalMedia: (selectedStory.feedType == StoryType.storyImage.rawValue ? imgThumb750 : selectedStory.path ), feedId: selectedStory.feedId, time: createdDate, discription: selectedStory.caption, lits: "", comments: "", mediaType: (selectedStory.feedType == StoryType.storyImage.rawValue ? mediaType.image : mediaType.video ), owner: ownerDetails, type: .activateStory, duration: selectedStory.duration, viewers: selectedStory.viewers, branchLink: "", masterIndex: 0, index: nil, individualFeedType: individualFeedType.init(rawValue: selectedStory.feedType)!, privacyLevel: privacyLevel(rawValue: selectedStory.privacy.level)!)
                
                arrFeeds.append(storyMedia)
            }
            feeds.feedList = arrFeeds
            feeds.bottomtype =  .eye
            feeds.feedType = .story
            feeds.owner = ownerDetails
            feeds.turnSoket =  false
        }
        let configuration = ImageViewerConfiguration { config in
            config.imageView =  imgProfile
            config.actiondelegate = self
        }
        DispatchQueue.main.async {
            self.present(ImageViewerController(configuration: configuration, contant: feedCon), animated: true, completion: nil)
        }
    }
    @IBAction func btnItzlitITapped(_ sender: UIButton) {
        Helper.navigateToHomeScren(navigation: self.navigationController!)
    }
    
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        if self.isFromStoryCapture {
            _ = self.navigationController?.popViewController(animated: true)
        } else {
            let homeVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.home.rawValue) as! HomeViewController
            Helper.Push_Pop_to_ViewController(destinationVC: homeVC, isAnimated: true, navigationController: self.navigationController!)
        }
    }
    
    @objc func lbltappedView(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .recognized {
            let list = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.requestList.rawValue) as! RequestListViewController
            list.listType = "request"
            Helper.Push_Pop_to_ViewController(destinationVC: list, isAnimated: true, navigationController: self.navigationController!)
        }
    }
    
    @IBAction func btnAddLiveAction(_ sender: Any) {
        
        var isLiveStreamingVC: Bool = false
        var arrNavigationController = self.navigationController?.viewControllers
        for controller in arrNavigationController! {
            if controller.isKind(of: LiveStreamingConfigurationVC.self) {
                isLiveStreamingVC = true
                let indexOfReg = arrNavigationController?.index(of: controller)
                arrNavigationController?.remove(at: indexOfReg!)
                self.navigationController?.viewControllers = arrNavigationController!
                let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
                Helper.Push_Pop_to_ViewController(destinationVC: liveStreamingConfig, isAnimated: false, navigationController: self.navigationController!)
            }
        }
        
        if !isLiveStreamingVC {
            let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
            Helper.Push_Pop_to_ViewController(destinationVC: liveStreamingConfig, isAnimated: false, navigationController: self.navigationController!)
        }
        
    }
    
    func animatePulseView(){
        
        let feed = self.tblFeed.cellForRow(at: IndexPath(row: 0, section: 0))  as? FeedCell
        let feedCollectionCell = feed?.collectionLive.cellForItem(at: IndexPath(row: 0, section: 0)) as? FeedCollectionViewCell
        
        UIView.animate(withDuration: 2.0, animations: {
            self.isAnimating = true
            feedCollectionCell?.imgSwipe.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            feedCollectionCell?.imgSwipe.transform = .identity
        }) { (success) in
            if self.isAnimating {
                self.isAnimating = false
                self.animatePulseView()
            }
        }
    }
    
    @IBAction func btnShowLiveACtion(_ sender: Any) {
        if isShowingOwnFeed{
            hideMyFeed()
        } else {
            ShowMyFeed()
        }
    }
    
    func ShowMyFeed()  {
        isShowingOwnFeed = true
        
        if self.arrfeedList == nil {
            self.arrfeedList = []
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.tblFeed.reloadData()
        }
        
        self.tblFeed.beginUpdates()
        self.arrfeedList.insert(arrRecentStories![0], at: 0)
        self.tblFeed.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        //        self.tblFeed.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        self.tblFeed.endUpdates()
        
        CATransaction.commit()
        
        self.arrfeedList[0].expandIndex = 0
        self.arrfeedList[0].isSwipeIndicatorDisplayed = false
        feedInfoView?.isHidden = isShowFeedInfoView
    }
    
    func hideMyFeed()  {
        isShowingOwnFeed = false
 
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.tblFeed.reloadData()
        }
        self.tblFeed.beginUpdates()
        self.arrfeedList.remove(at: 0)
        self.tblFeed.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        self.tblFeed.endUpdates()
        
        CATransaction.commit()
        if self.arrfeedList.count > 0 {
            self.arrfeedList[0].isSwipeIndicatorDisplayed = true
        }
        
        feedInfoView?.isHidden = isShowFeedInfoView
    }
    
    //MARK:- APIs, Feed seen API calls
    func markFeedAsViewed(feedId:String!)  {
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.feedId: feedId]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.markAsViewd, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if !self.isMyStory {
                        DBManager.shared.insertStorySeenDataToDB(storyId: feedId, onCompletion: { (isSucess) in
                            if isSucess {
                                print("seen story data inserted successfully...!", feedId)
                            }
                        })
                    }
                }
            }
        }, onError: { (error, response) in
            print(error ?? "error")
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    
    /// Get Request Count API call
    func getRequestCount(compilation:@escaping ContactHandler)  {
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.liverequestCount, onComplete: { (json, error, response) in
            if error == nil {
                if let dict = json.dictionaryObject as Dictionary? {
                    if dict["doc"] != nil{
                        let requestcount = ((dict["doc"] as! Array<Any>)[0] as! Dictionary<String,Any>)["totalcount"] as! Int
                        self.lblRequesrCount.text = requestcount == 0 ? "" : "\(requestcount) Live \((requestcount > 1 ? "Requests" : "Request"))"
                    }
                }
            }
            Helper.hideProgressBar()
            compilation(true)
        }) { (error, response) in
            print(error ?? "error alamofire")
            Helper.hideProgressBar()
            
            compilation(true)
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    /// Get My-Stories API Call
    func getMyStory(compilation:@escaping ContactHandler)  {
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.getMyStories, onComplete: { (json, error, response) in
            if error == nil {
                if let dictStories = json.dictionaryObject as Dictionary? {
                    if dictStories["docs"] != nil{
                        self.arrRecentStories =  ItFeedList.Populate(list: ((dictStories )["docs"]! as? Array<Any>)!)
                        compilation(true)
                    }
                }
            }
            Helper.hideProgressBar()
            compilation(true)
        }) { (error, response) in
            print(error ?? "error alamofire")
            Helper.hideProgressBar()
            
            compilation(true)
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
    
    /* TODO: Remove Code after testing
    func setupNoDataLabel() {
        
        if lblNoDataFound == nil {
            self.lblNoDataFound = UILabel()
        }
        let lblNoDataFoundFrame = CGRect(x: (self.view.frame.origin.x / 2)-10, y: (self.view.frame.origin.y/2)-64, width: self.tblFeed.frame.width, height: 300)
        self.lblNoDataFound.frame = lblNoDataFoundFrame
        self.lblNoDataFound.tag = 10000
        self.lblNoDataFound.text = AppMessage.noFeedFound.rawValue
        self.lblNoDataFound.lineBreakMode = .byWordWrapping
        self.lblNoDataFound.numberOfLines = 0
        
        self.lblNoDataFound.textColor = UIColor(red: 23.0/255.0, green: 23.0/255.0, blue: 23.0/255.0, alpha: 1)
        
        self.lblNoDataFound.center = self.tblFeed.center
        self.lblNoDataFound.textAlignment = .center
        self.lblNoDataFound.font = UIFontConst.POPPINS_REGULAR
    } */
    
    /// Get Feed List API calls
    func getFeedList(pageNumber: Int, compilation:@escaping ContactHandler) {
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.feedStories + "?page=" + "\(pageNumber)", onComplete: { (json, error, response) in
            if error == nil {
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    if let dictFeeds = json.dictionaryObject as Dictionary? {
                        if dictFeeds["followingsFeeds"] != nil{
                            //self.arrfeedList = ItFeedList.Populate(list: (dictFeeds["followingsFeeds"] as! Dictionary<String,Any>)["docs"]! as! Array<Any>)
                            if let dictFollowingFeed = dictFeeds["followingsFeeds"] as? [String:Any] {
                                if let totalPages = dictFollowingFeed["pages"] as? Int {
                                    self.totalCount = totalPages
                                    
                                    if let pageNumber = dictFollowingFeed["page"] as? String {
                                        self.pageNumber = Int(pageNumber)!
                                    }
                                }
                            }
                            
                            if  self.refreshControl.isRefreshing {
                                self.arrfeedList = []
                            }
                            if  self.arrfeedList == nil {
                                self.arrfeedList = []
                            }
                            //                            if  self.isTimerExecute {
                            //                                self.arrfeedList = []
                            //                             }
                            for data in ItFeedList.Populate(list: ((dictFeeds["followingsFeeds"] as! Dictionary<String,Any>)["docs"]! as? Array<Any>)!) {
                                self.arrfeedList.append(data)
                            }
                            if  self.refreshControl.isRefreshing {
                                if self.isShowingOwnFeed {
                                    if self.arrRecentStories!.count > 0{
                                        self.arrfeedList.insert(self.arrRecentStories![0], at: 0)
                                    }
                                }
                            }
                        }
                        
                        self.feedInfoView?.isHidden = self.isShowFeedInfoView
                    }
                    compilation(true)
                    
                    //                    let arrPaths = self.arrfeedList.flatMap({ $0.followingsFeeds.flatMap({ $0.thumbs.filter({ $0.size == ThumbSize.thumb_750x1334.rawValue }).flatMap({ $0.imageURL }) }) })
                    //
                    //                    print(arrPaths)
                    //
                    //                    SDWebImagePrefetcher.shared().prefetchURLs(arrPaths, progress: { (x,y) in
                    //                        print(x,y)
                    //                    }, completed: { (a, b) in
                    //                        print(a,b)
                    //                    })
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
    
    
    //MARK:- API calls & Action Handlers
    func sendGoLiveRequestTo(masterIndex:Int? = nil, index:Int, isFromStoryDetail:Bool? = false)  {
        let user = self.arrfeedList[masterIndex!]
        
        Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.goLiveUser: user.followeeId]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.goliverequest, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    user.isItzlit = true
                    self.tblFeed.reloadRows(at: [IndexPath(row: masterIndex!, section: 0)], with: .none)
                    if isFromStoryDetail! {
                        if masterIndex != nil {
                            let storyId = self.arrfeedList[masterIndex!].followingsFeeds[index].feedId
                            DBManager.shared.insertStoryDetailToDB(userId: user.followeeId, storyId: storyId, onCompletion: { (isSucess) in
                                if isSucess {
                                    print("Data inserted Successfully...! in story detail table", storyId)
                                    let prefDate = Date().getCurrentUTCDateTime()
                                    UserDefaults.standard.set(prefDate, forKey: "pref_date_golive")
                                    
                                    let feedData: [String: Any]! = [WebserviceRequestParmeterKey.goLiveUser: storyId, "type":actionType.golive]
                                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCounters"), object:feedData)
                                    //,"isItzlit":user.isItzlit
                                }
                            })
                        }
                    } else {
                        
                    }
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
    
    func wsCallReportFeed(feedID: String) {
        Helper.showProgressBar()
        let dicParameter = [WebserviceRequestParmeterKey.feedId: feedID]
        ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.reportFeed, parameter: dicParameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    let dicResponse = json.dictionaryObject
                    if let responseMessage = dicResponse?["msg"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: responseMessage, clickAction: {})
                    }
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
    
    /// Delete Feed API called.
    func deleteFeed(masterIndex:Int,index:Int?,feedId:String)  {
        Helper.showProgressBar()
        let parameter: [String: Any]!
        if index != nil {//live
            let feedToUpdate = self.arrfeedList[masterIndex].liveFeeds[index!]
            parameter = [WebserviceRequestParmeterKey.feedId: feedToUpdate.feedId]
        } else {//own feed
            parameter = [WebserviceRequestParmeterKey.feedId: feedId]
        }
        
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.deleteFeed, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                
                if (response as! HTTPURLResponse).statusCode == 200  {
                    
                    if index == nil {
                        self.getMyStory(compilation: { (ready) in
                            self.refreshOwnLiveFeed()
                            self.setMyDetail()
                        })
                        self.dismiss(animated: true, completion: nil)
                        
                        return
                    }
                    self.arrfeedList[masterIndex].liveFeeds.remove(at: index!)
                    if (self.isShowingOwnFeed == true && masterIndex == 0) {//own
                        if self.arrfeedList[masterIndex].liveFeeds.count == 0 {
                            self.hideMyFeed()
                            self.getMyStory(compilation: { (ready) in
                                self.refreshOwnLiveFeed()
                            })
                        }else {
                            self.refreshOwnLiveFeed()
                            self.tblFeed.reloadData()
                        }
                    }
                    
                    let feedData: [String: Any]! = [WebserviceRequestParmeterKey.feedId:parameter[WebserviceRequestParmeterKey.feedId]!,"type":actionType.init(rawValue: 3)!]
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCounters"), object:feedData )
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
    
    /// Hide feed api call
    func hideFeed(masterIndex:Int,index:Int?,feedId:String,baseFeedType:feedType) {
        Helper.showProgressBar()
        let parameter: [String: Any]!
        if index != nil {//Other user feed
            let feedToUpdate = baseFeedType == .story ? self.arrfeedList[masterIndex].followingsFeeds[index!] : self.arrfeedList[masterIndex].liveFeeds[index!]
            parameter = [WebserviceRequestParmeterKey.feedId: feedToUpdate.feedId]
        } else {//own feed
            parameter = [WebserviceRequestParmeterKey.feedId: feedId]
        }
        
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.hideFeed, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                
                if (response as! HTTPURLResponse).statusCode == 200  {
                    if index == nil {//own story
                        
                        self.getMyStory(compilation: { (ready) in
                            self.refreshOwnLiveFeed()
                        })
                        self.dismiss(animated: true, completion: nil)
                        return
                    }
                    if baseFeedType != .story{
                        self.arrfeedList[masterIndex].liveFeeds.remove(at: index!)
                        if (self.isShowingOwnFeed == true && masterIndex == 0) {//own live
                            if self.arrfeedList[masterIndex].liveFeeds.count == 0  {
                                self.hideMyFeed()
                                self.refreshOwnLiveFeed()
                            }else {
                                self.tblFeed.reloadData()
                            }
                        }else { // other live
                            if self.arrfeedList[masterIndex].liveFeeds.count == 0 && self.arrfeedList[masterIndex].followingsFeeds.count == 0 {
                                
                                if #available(iOS 11.0, *) {
                                    self.tblFeed.performBatchUpdates({
                                        self.arrfeedList.remove(at: masterIndex)
                                        self.tblFeed.deleteRows(at: [IndexPath(row: masterIndex, section: 0)], with: .automatic)
                                    }) { (ok) in
                                        self.tblFeed.reloadData()
                                    }
                                } else {
                                    self.tblFeed.beginUpdates()
                                    self.arrfeedList.remove(at: masterIndex)
                                    self.tblFeed.deleteRows(at: [IndexPath(item: masterIndex, section: 0)], with: .automatic)
                                    self.tblFeed.endUpdates()
                                    self.tblFeed.reloadData()
                                }
                                //
                            }else if self.arrfeedList[masterIndex].liveFeeds.count == 0 && self.arrfeedList[masterIndex].followingsFeeds.count != 0 {
                                self.arrfeedList[masterIndex].expanded = false
                                self.tblFeed.reloadData()
                            } else {
                                let cell = self.tblFeed.cellForRow(at: IndexPath(row: masterIndex, section: 0)) as! FeedCell
                                cell.collectionLive.reloadData()
                            }
                        }
                    } else { //other story
                        self.arrfeedList[masterIndex].followingsFeeds.remove(at: index!)
                        if self.arrfeedList[masterIndex].liveFeeds.count == 0 && self.arrfeedList[masterIndex].followingsFeeds.count == 0 {
                            self.tblFeed.beginUpdates()
                            self.tblFeed.deleteRows(at: [IndexPath(item: masterIndex, section: 0)], with: .automatic)
                            self.arrfeedList.remove(at: masterIndex)
                            self.tblFeed.endUpdates()
                            self.tblFeed.reloadData()
                        }
                    }
                    
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
    
    /// Lits Up API Called
    func litsUp(masterIndex:Int,index:Int)  {
        let feedToUpdate = self.arrfeedList[masterIndex].liveFeeds[index]
        
        let parameter: [String: Any]! = [WebserviceRequestParmeterKey.feedId: feedToUpdate.feedId]
        
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.litsUp, parameter: parameter, onCompletion: { (json, error, response) in
            // Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    let outPut = json.dictionaryObject
                    feedToUpdate.itzlitCount = (outPut!["count"] == nil ? 1 : outPut!["count"] as! Int)
                    
                    let cell = self.tblFeed.cellForRow(at: IndexPath(row: masterIndex, section: 0)) as! FeedCell
                    cell.collectionLive.reloadItems(at: [IndexPath(item: index, section: 0)])
                    
                    //Update same in Lib
                    let feedData: [String: Any]! = [WebserviceRequestParmeterKey.feedId:parameter[WebserviceRequestParmeterKey.feedId]!,"type":actionType.init(rawValue: 0)!,"lits":(outPut!["count"] == nil ? 1 : outPut!["count"] as! Int)]
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
    
    func commentUpdater(masterIndex:Int,index:Int,base:UIViewController)  {
        let feedToUpdate = self.arrfeedList[masterIndex].liveFeeds[index]
        let list = Helper.feedActionStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.comment.rawValue) as! FeedCommentViewController
        list.feedId = feedToUpdate.feedId
        
        list.dismissCompletion { (feedid) in
            if feedid.count > 0 {
                self.arrfeedList[masterIndex].liveFeeds[index].comments += 1
                
                let cell = self.tblFeed.cellForRow(at: IndexPath(row: masterIndex, section: 0)) as! FeedCell
                cell.collectionLive.reloadItems(at: [IndexPath(item: index, section: 0)])
                
                let feedData: [String: Any]! = [WebserviceRequestParmeterKey.feedId:feedid,"type":actionType.init(rawValue: 1)!,"count":self.arrfeedList[masterIndex].liveFeeds[index].comments]
                NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCounters"), object:feedData )
                
            }
        }
        base.present(UINavigationController(rootViewController: list), animated: true, completion: {
        })
    }
    func shareHandler(masterIndex:Int,index:Int,base:UIViewController) {
        let feedToUpdate = self.arrfeedList[masterIndex].liveFeeds[index]
        if feedToUpdate.branchLink.count > 0 {
            let activityVC = UIActivityViewController(activityItems: [URL(string:feedToUpdate.branchLink)!], applicationActivities: nil)
            base.present(activityVC, animated: true, completion: nil)
        }
    }
    
    //MARK:- Helper
    func getFolowingFeedCreatedDateTime(strCreated: String) -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let strDate = dateFormatter.string(from: date)
        
        let currDate = Helper.convertDateFormat(serverDateFormate: "yyyy-MM-dd HH:mm:ss Z", newDateFormate: "yyyy-MM-dd HH:mm a", date: strDate)
        
        let serverDate = Helper.convertDateFormat(serverDateFormate: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z", newDateFormate: "yyyy-MM-dd HH:mm a", date: strCreated)
        
        if currDate.compare(serverDate) == .orderedSame {
            dateFormatter.dateFormat = " HH:mm a"
            return "Today " + dateFormatter.string(from: serverDate)
        } else {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm a"
            return dateFormatter.string(from: serverDate)
        }
    }
    
    //open action sheet to hide/delete feed of users
    func openActionSheet(masterIndex:Int,index:Int?,feedId:String,base:UIViewController,baseFeedType:feedType?)  {
        let asMenuOption: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        asMenuOption.view.tintColor = UIColor.black.withAlphaComponent(0.5)
        asMenuOption.title = nil
        asMenuOption.message = nil
        let hideActionButton: UIAlertAction = UIAlertAction(title: "Hide", style: .default) { action -> Void in
            self.hideFeed(masterIndex: masterIndex, index: index, feedId: feedId, baseFeedType: baseFeedType!)
        }
        
        
        hideActionButton.setValue(#imageLiteral(resourceName: "hide"), forKey: "image")
        asMenuOption.addAction(hideActionButton)
        let cancelActionButton: UIAlertAction =  UIAlertAction(title: MenuTitle.cancel.rawValue, style: .cancel, handler: nil)
        asMenuOption.addAction(cancelActionButton)
        if (self.isShowingOwnFeed == true && masterIndex == 0) || index == nil{
            let deletActionButton: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { action -> Void in
                self.deleteFeed(masterIndex: masterIndex, index: index, feedId: feedId)
            }
            
            deletActionButton.setValue(#imageLiteral(resourceName: "img_delete"), forKey: "image")
            asMenuOption.addAction(deletActionButton)
        } else {
            //Display flag option if user is not tapped on their own post
            let flagActionButton: UIAlertAction = UIAlertAction(title: "Flag", style: .default) { action -> Void in
                self.wsCallReportFeed(feedID: feedId)
            }
            
            flagActionButton.setValue(#imageLiteral(resourceName: "img_flag"), forKey: "image")
            asMenuOption.addAction(flagActionButton)
        }
        
        base.present(asMenuOption, animated: true, completion: {
            
        })
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate Methods
extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.view.frame.size.width*0.8875*0.46
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        self.viewForHeader.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width*0.8875, height: self.view.frame.size.width*0.8875*0.46)
        
        DispatchQueue.main.async {
            self.imgProfile.layer.cornerRadius = self.imgProfile.frame.width/2
            self.imgProfile.clipsToBounds = true
            self.imgProfileLive.layer.cornerRadius = self.imgProfile.frame.width/2
            self.imgProfileLive.clipsToBounds = true
        }
        return self.viewForHeader
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrfeedList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let feedCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.feedCell.rawValue, for: indexPath) as? FeedCell{
            
            feedCell.collectionLive.dataSource = feedCell
            feedCell.collectionLive.delegate = feedCell
            feedCell.setFeedFor(feed: self.arrfeedList[indexPath.row], index:indexPath.row, itsMe: (self.isShowingOwnFeed == true && indexPath.row == 0) ? true : false)
            feedCell.collectionClickDelegate = self
            feedCell.btnGoLive.tag = indexPath.row
            feedCell.btnGoLive.addTarget(self, action: #selector(self.btnGoLiveAction(sender:)), for: .touchUpInside)
            feedCell.btnTogleLiveFeed.tag = indexPath.row
            feedCell.btnTogleLiveFeed.addTarget(self, action: #selector(self.btnTogleLiveFeedAction(sender:)), for: .touchUpInside)
            return feedCell
        }else{
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if pageNumber < totalCount && indexPath.row == (arrfeedList.count - 5) {
            self.pageNumber += 1
            self.getFeedList(pageNumber: pageNumber, compilation: { (isSucess) in
                if isSucess {
                    self.tblFeed.reloadData()
                }
            })
        }
        guard let tableViewCell = cell as? FeedCell else { return }
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? FeedCell else { return }
        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
        print(indexPath.row,tableViewCell.collectionViewOffset)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedFeed = self.arrfeedList[indexPath.row]
        let feedOwner = owner.init(name: selectedFeed.fullName, image: #imageLiteral(resourceName: "img_profile"), originalImage: selectedFeed.profilePic)
        if selectedFeed.followingsFeeds.count == 0 {
            return
        }
        let  feedq = feedContant { feeds in
            var storys = [feed]()
            var arrGoLiveID = [String]()
            self.isMyStory = false
            for storyIndex in 0..<selectedFeed.followingsFeeds.count {
                let  story = selectedFeed.followingsFeeds[storyIndex]
                var imgThumb750 : String = ""
                var imgThumb300 : String = ""
                var thumbId     : String = ""
                
                for path in story.thumbs {
                    if path.size == ThumbSize.thumb_750x1334.rawValue {
                        imgThumb750 = path.path
                        if let pathId = path._id as String? {
                            thumbId = pathId
                        }
                    } else if  path.size == ThumbSize.thumb_300x300.rawValue {
                        imgThumb300 = path.path
                    }
                }
                let createdDate = Date().getDifferanceFromCurrentTime(serverDate: story.createdAt! as Date)
                let seenStoryId = DBManager.shared.fetchStoryDetailData(storyid: story.feedId, onCompletion: { (isSucess) in
                    if isSucess {
                        print("Sucesssss...!!! fetchStoryDetailData from Stroy Detail table.")
                    }
                })
                arrGoLiveID.append(seenStoryId)
                let storyMedia = feed.init(seenStoryId: seenStoryId, thumbId: thumbId, thumb: imgThumb300, orignalMedia:(story.feedType ==  "StoryImage" ? imgThumb750 : story.path) , feedId: story.feedId, time: createdDate, discription: story.caption, lits: "\(story.itzlitCount)", comments: "\(story.comments)", mediaType: story.feedType ==  "StoryImage" ? .image : .video, owner: feedOwner, type: .feed,duration: story.duration, viewers: story.viewers, branchLink: story.branchLink, masterIndex: indexPath.row, index: storyIndex, individualFeedType: individualFeedType.init(rawValue: story.feedType)!, privacyLevel: privacyLevel.init(rawValue: story.privacy.level)!)
                
                storys.append(storyMedia)
            }
            
            feeds.feedList = storys
            feeds.bottomtype =  .none
            feeds.feedType =  .story
            feeds.owner = feedOwner
            feeds.turnSoket =  false
            feeds.arrGoLiveID = arrGoLiveID
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! FeedCell
        let configuration = ImageViewerConfiguration { config in
            config.imageView = cell.imgProfile
            config.actiondelegate = self
            
        }
        DispatchQueue.main.async {
            self.present(ImageViewerController(configuration: configuration, contant: feedq), animated: true, completion: nil)
        }
    }
    
    //MARK:- Button Action
    @IBAction func btnNavigateToLiveStreaminVC(_ sender: UIButton) {
        var isLiveStreamingVC: Bool = false
        var arrNavigationController = self.navigationController?.viewControllers
        for controller in arrNavigationController! {
            if controller.isKind(of: LiveStreamingConfigurationVC.self) {
                isLiveStreamingVC = true
                let indexOfReg = arrNavigationController?.index(of: controller)
                arrNavigationController?.remove(at: indexOfReg!)
                self.navigationController?.viewControllers = arrNavigationController!
                let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
                self.navigationController?.pushViewController(liveStreamingConfig, animated: false)
            }
        }
        
        if !isLiveStreamingVC {
            let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
            Helper.Push_Pop_to_ViewController(destinationVC: liveStreamingConfig, isAnimated: false, navigationController: self.navigationController!)
        }
    }
    
    /// Table cell Golive button selector method.
    @objc func btnGoLiveAction(sender:UIButton)  {
        if sender.currentTitle == "Go Live!" {
            self.sendGoLiveRequestTo(masterIndex: sender.tag, index: sender.tag)
        } else if sender.currentImage == #imageLiteral(resourceName: "img_itslit") {
            
        } else {
            
        }
    }
    
    /// Table cell Button Toggle Live Feed selector method.
    @objc func btnTogleLiveFeedAction(sender:UIButton) {
        self.arrfeedList[sender.tag].expanded = !self.arrfeedList[sender.tag].expanded
        self.arrfeedList[sender.tag].expandIndex = sender.tag
        self.arrfeedList[sender.tag].isSwipeIndicatorDisplayed = !self.arrfeedList[sender.tag].expanded
        let _ = self.tblFeed.cellForRow(at: IndexPath(row: sender.tag, section: 0))  as? FeedCell
        //        feed?.animate(explore:  self.arrfeedList[sender.tag].expanded)
        self.tblFeed.reloadRows(at: [IndexPath(row: sender.tag, section: 0)], with: .automatic)
    }
    
    func initSoket(feedid:String)  {
        let params = [WebserviceRequestParmeterKey.feedId : feedid]
        ILSocketManager.shared.joinLiveStream(withParams: params)//establishConnection(withParams: params)
//        ILSocketManager.shared.delegate = self
    }
   
    func deinitItsoket()  {
        ILSocketManager.shared.emitEvent(.onFeedUnjoin, items: [:])
    }
}

// MARK:- Socket Manager Delegate Methods
extension FeedViewController: ILSocketManagerDelegate {
    func updateMyLiveViewerCount(feedID: String, liveFeedCount: String) {
        
    }
    
    func updateViewerUpdate(liveFeedCount: String) {
        let feedData: [String: Any]! = [WebserviceRequestParmeterKey.feedId:"","type":actionType.init(rawValue: 5)!,"users": liveFeedCount]
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateCounters"), object:feedData )
    }
}

//MARK:- Library Action delegate methods.
extension FeedViewController:ActionDelegate {
    
    func actionTrigered(action: actionType, masterIndex: Int?, index: Int?, feedId: String, mediaUrl: String, base: UIViewController, baseFeedType: feedType) {
        
        if action == .viewerList {
            if self.isShowingOwnFeed == true && masterIndex == 0 || self.isMyStory == true {
                let list = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.requestList.rawValue) as! RequestListViewController
                list.listType = ""
                list.feedId = feedId
                base.present(UINavigationController(rootViewController: list), animated: true, completion: {
                })
            }
        } else if action == .comment {
            commentUpdater(masterIndex: masterIndex!, index: index!, base: base)
            
        } else if action == .like {
            self.litsUp(masterIndex: masterIndex!, index: index!)
            
        }else if action == .share {
            shareHandler(masterIndex: masterIndex!, index: index!, base: base)
            
        } else if action == .more {
            self.openActionSheet(masterIndex: masterIndex!, index: index, feedId: feedId, base: base,baseFeedType: baseFeedType)
        } else if action == .golive {
            self.sendGoLiveRequestTo(masterIndex: masterIndex!, index: index!, isFromStoryDetail: true)
        }
    }
    
    func startListen(action: actionType, feedId: String) {
        if feedId.count > 0 {
            initSoket(feedid: feedId)
        } else {
            deinitItsoket()
        }
    }
    
    func markAsViewed(feedId: String) {
        self.markFeedAsViewed(feedId: feedId)
    }
    
    func shouldMakeIt(active: Bool, feedId: String) {
        print(active)
    }
    
    func sendGoLiveRequest(index: Int) {
        print("Button action go live tapped...!")
    }
    
    func markAsStroySeenAt(masterIndex: Int, index: Int) {
        
        let indexPath = IndexPath(item: masterIndex, section: 0)
        
        if let visibleIndexPaths = self.tblFeed.indexPathsForVisibleRows?.index(of: indexPath as IndexPath) {
            if visibleIndexPaths != NSNotFound {
                self.tblFeed.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}

// MARK:- Collection View action delegate method
extension FeedViewController:feedColectionActionProtocol {
    func collectionViewsStartListen(masterIndex: Int, feedId: String) {
        if feedId.count > 0 {
            print("feedId::::--->>>",feedId)
//            ILSocketManager.shared.delegate = self
            ILSocketManager.shared.joinLiveStream(withParams: [WebserviceRequestParmeterKey.feedId : feedId])
        } else {
//            deinitItsoket()
        }
    }
    
    func collectionActionClicked(action: actionType?, masterIndex: Int, index: Int, feed: ItFeedList) {
        if action == .like {
            self.litsUp(masterIndex: masterIndex, index: index)
        } else if action == .comment {
            commentUpdater(masterIndex: masterIndex, index: index, base: self)
        } else if action == .share{
            shareHandler(masterIndex: masterIndex, index: index, base: self)
        } else if action == .more {
            self.openActionSheet(masterIndex: masterIndex, index: index, feedId: "", base: self, baseFeedType: .live)
        } else if action == .viewerList {
            if self.isShowingOwnFeed == true && masterIndex == 0 {
                let list = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.requestList.rawValue) as! RequestListViewController
                list.listType = ""
                list.feedId = self.arrRecentStories![masterIndex].liveFeeds[index].feedId
                self.present(UINavigationController(rootViewController: list), animated: true, completion: {
                })
            }
        }
    }
    
    func collectionWillDisplayCell(masterIndex: Int, index: Int, contentOffset: CGFloat) {
        
    }
    
    func collectionDidSelectiAt(masterIndex: Int, index: Int, feedForDisplay: ItFeedList) {
        let selectedLiveFeed = feedForDisplay.liveFeeds[index]
        
        let feedOwner = owner.init(name: feedForDisplay.fullName, image: #imageLiteral(resourceName: "img_profile"), originalImage: feedForDisplay.profilePic)
        
        let  feedq = feedContant{ feeds in
            self.isMyStory = false
            var storys = [feed]()
            
            var imgThumb300 : String = ""
            for path in selectedLiveFeed.thumbs {
                if  path.size == ThumbSize.thumb_300x300.rawValue {
                    imgThumb300 = path.path
                }
            }
            
            let createdDate = Date().getDifferanceFromCurrentTime(serverDate: selectedLiveFeed.createdAt! as Date)
            
            let storyMedia = feed.init(seenStoryId: "", thumbId: "", thumb: imgThumb300, orignalMedia: selectedLiveFeed.path , feedId: selectedLiveFeed.feedId, time: createdDate, discription: selectedLiveFeed.caption, lits: "\(selectedLiveFeed.itzlitCount)", comments: "\(selectedLiveFeed.comments)", mediaType: .video, owner: feedOwner, type: .feed,duration: selectedLiveFeed.duration, viewers: selectedLiveFeed.viewers, branchLink: selectedLiveFeed.branchLink, masterIndex: masterIndex, index: index, individualFeedType: individualFeedType.init(rawValue: selectedLiveFeed.feedType)!, privacyLevel: privacyLevel(rawValue: selectedLiveFeed.privacy.level)!)
            
            storys.append(storyMedia)
            
            feeds.feedList = storys
            feeds.bottomtype =  .feed
            feeds.feedType = .live
            feeds.owner = feedOwner
            feeds.turnSoket = (selectedLiveFeed.feedType == "LiveStream" ? true : false)
        }
        
        let cell = tblFeed.cellForRow(at: IndexPath(row: masterIndex, section: 0)) as! FeedCell
        let configuration = ImageViewerConfiguration { config in
            DispatchQueue.main.async {
                config.imageView = cell.imgProfile
                config.actiondelegate = self
            }
        }
        DispatchQueue.main.async {
            self.present(ImageViewerController(configuration: configuration, contant: feedq), animated: true, completion: nil)
        }
    }
}

//MARK: View Controller Selector Methods
extension FeedViewController {
    
    @objc func inviteFriendsButtonTap() {
        guard navigationController != nil else {
            return
        }
        Helper.navigateToInviteFriends(navigation: navigationController!)
    }
}
