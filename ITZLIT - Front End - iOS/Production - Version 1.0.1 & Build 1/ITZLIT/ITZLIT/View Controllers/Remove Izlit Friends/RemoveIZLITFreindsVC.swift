//
//  RemoveIZLITFreindsVC.swift
//  ITZLIT
//
//  Created by devang.bhatt on 04/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class RemoveIZLITFreindsVC: UIViewController {
    
    @IBOutlet var tblRemoveIzlitFriends: UITableView!
    
    var arrToDisplay : [FollowList]!
    var arrFollowing : [FollowList]!
    var arrFollower : [FollowList]!
    @IBOutlet weak var btnFolowers: UIButton!
    @IBOutlet weak var btnFollowing: UIButton!
    @IBOutlet weak var viewTab: UIView!
    
    var sortedFirstLetters: [String] = []
    var sections : [[FollowList]] = [[]]
    
    var totalCount:Int = 0
    var pageNumber = 0
    var isFromNotification: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblRemoveIzlitFriends.delegate = nil
        self.tblRemoveIzlitFriends.dataSource = nil
        tblRemoveIzlitFriends.layer.cornerRadius = 2.0
        tblRemoveIzlitFriends.layer.borderWidth = 0.25
        tblRemoveIzlitFriends.layer.borderColor = UIColor.lightGray.cgColor
        DispatchQueue.main.async {
            let path = UIBezierPath(roundedRect:self.viewTab.bounds,
                                    byRoundingCorners:[.topRight, .topLeft],
                                    cornerRadii: CGSize(width: 20, height:  20))
            
            let maskLayer = CAShapeLayer()
            
            maskLayer.path = path.cgPath
            self.viewTab.layer.mask = maskLayer
            self.viewTab.layer.borderColor = UIColor.gray.cgColor
            self.viewTab.layer.borderWidth = 1
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationBar()
        
        self.arrToDisplay = []
        self.arrFollowing = []
        self.arrFollower = []
        self.sections = []
        if self.isFromNotification == true {
            btnFollowing.isSelected = false
            btnFolowers.isSelected = true
            followerListApi(pageNumber: 1)
        } else {
            btnFollowing.isSelected = true
            btnFolowers.isSelected = false
            followingListApi(pageNumber: 1)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNavigationBar() {
        self.navigationController?.navigationItem.hidesBackButton = true
        self.title = ViewControllerTitle.searchGlobal.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let rightBarBackButton = UIBarButtonItem(image: UIImage(named: "img_search"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(rightBarSearchButton(_:)))
        self.navigationItem.rightBarButtonItem = rightBarBackButton
        
        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton
    }
    
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc func rightBarSearchButton(_ sender:UIBarButtonItem)  {
         let searchItzlitFriendsVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.searchItzlitFriendsVC.rawValue) as! SearchItzlitFriendsVC
        let navController = UINavigationController(rootViewController: searchItzlitFriendsVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    func setupTableViewData() {
        
        let firstLetters =  arrToDisplay.map{ (btnFollowing.isSelected ? $0.followee.titleFirstLetter :$0.follower.titleFirstLetter) }
        let uniqueFirstLetters = Array(Set(firstLetters))
        sortedFirstLetters = uniqueFirstLetters.sorted()
        
        sections = sortedFirstLetters.map { firstLetter in
            return arrToDisplay
                .filter { (btnFollowing.isSelected ? $0.followee.titleFirstLetter == firstLetter : $0.follower.titleFirstLetter == firstLetter) }
                .sorted { (btnFollowing.isSelected ? $0.followee.fullName < $1.followee.fullName : $0.follower.fullName < $1.follower.fullName) }
        }
        if sections.count > 0 {
            self.tblRemoveIzlitFriends.reloadData()
            self.tblRemoveIzlitFriends.delegate = self
            self.tblRemoveIzlitFriends.dataSource = self
        }
    }
    
    @IBAction func btnTabAction(_ sender: UIButton) {
        
        if self.arrToDisplay != nil{
            self.arrToDisplay.removeAll()
            self.sections.removeAll()
        }
        self.pageNumber = 0
        self.totalCount = 0
        if sender.tag == 0 {//Following
            btnFollowing.isSelected = true
            btnFolowers.isSelected = false
            followingListApi(pageNumber: 1)
        } else { //followers
            btnFollowing.isSelected = false
            btnFolowers.isSelected = true
            followerListApi(pageNumber: 1)
        }
    }
    
    //MARK:- Folloing List
    func followingListApi(pageNumber: Int)  {
        Helper.showProgressBar()
         self.arrFollowing = []
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.followingList+"?page="+"\(pageNumber)", onComplete: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if (((json.dictionaryObject!["followings"] as! [String: Any])["docs"]!) as AnyObject).count > 0 {
                        if  json.dictionaryObject!["followings"] != nil {
                            if let totalPages = ((json.dictionaryObject!["followings"] as! [String: Any])["pages"]! as? Int)  {
                                self.totalCount = totalPages
                                
                                if let pageNumber = ((json.dictionaryObject!["followings"] as! [String: Any])["page"]! as? Int) {
                                    self.pageNumber =  pageNumber
                                }
                            }
                        }
 
                        if (json.dictionaryObject!["followings"] as! [String: Any])["followings"] as? [ String:Any] != nil {
                            if let dictFollowing  = ((json.dictionaryObject!["followings"] as! [String: Any])["followings"] as? [ String:Any])  {
                                if let totalFollowingsCount = dictFollowing["followingsCount"] as? Int {
                                    self.btnFollowing.setTitle("Following (\(totalFollowingsCount))", for: .normal)
                                }
                            }
                        }
                        
                        if (json.dictionaryObject!["followings"] as! [String: Any])["followers"] as? [ String:Any] != nil {
                            if let dictFollower  = ((json.dictionaryObject!["followings"] as! [String: Any])["followers"] as? [ String:Any]) {
                                if let totalFollowerCount = dictFollower["followersCount"] as? Int {
                                    self.btnFolowers.setTitle("Followers (\(totalFollowerCount))", for: .normal)
                                }
                            }
                        }
                        
                        for data in FollowList.Populate(list: ((json.dictionaryObject!["followings"] as! [String: Any])["docs"]! as! NSArray)) {
                            self.arrFollowing.append(data)
                        }
                        //self.arrFollowing = FollowList.Populate(list: ((json.dictionaryObject!["followings"] as! [String: Any])["docs"]! as! NSArray))
                        
                        self.arrToDisplay = self.arrFollowing
                        self.setupTableViewData()
                    } else {
                        self.btnFollowing.setTitle("Following (0)", for: .normal)
                        self.tblRemoveIzlitFriends.reloadData()
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
    
    //MARK:- follower List
    func followerListApi(pageNumber: Int)  {
        self.arrFollower = []
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.followerList+"?page="+"\(pageNumber)", onComplete: { (json, error, response) in
            if error == nil {
                
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if (((json.dictionaryObject!["followers"] as! [String: Any])["docs"]!) as AnyObject).count > 0 {
                        
                        if let totalPages = ((json.dictionaryObject!["followers"] as! [String: Any])["pages"]! as? Int)  {
                            self.totalCount = totalPages
                            
                            if let pageNumber = ((json.dictionaryObject!["followers"] as! [String: Any])["page"]! as? Int) {
                                self.pageNumber =  pageNumber
                            }
                        }
                        if (json.dictionaryObject!["followers"] as! [String: Any])["followers"] as? [ String:Any] != nil {
                            if let dictFollower  = ((json.dictionaryObject!["followers"] as! [String: Any])["followers"] as? [ String:Any]) {
                                if let totalFollowerCount = dictFollower["followersCount"] as? Int {
                                    self.btnFolowers.setTitle("Followers (\(totalFollowerCount))", for: .normal)
                                }
                            }
                        }
                        
                        if (json.dictionaryObject!["followers"] as! [String: Any])["followings"] as? [ String:Any] != nil {
                        
                            if let dictFollowing  = ((json.dictionaryObject!["followers"] as! [String: Any])["followings"] as? [ String:Any])  {
                                if let totalFollowingsCount = dictFollowing["followingsCount"] as? Int {
                                    self.btnFollowing.setTitle("Following (\(totalFollowingsCount))", for: .normal)
                                }
                            }
                        }
                        
                        
                        for data in FollowList.Populate(list: ((json.dictionaryObject!["followers"] as! [String: Any])["docs"]! as! NSArray)) {
                            self.arrFollower.append(data)
                        }
                       //  self.arrFollower = FollowList.Populate(list: ((json.dictionaryObject!["followers"] as! [String: Any])["docs"]! as! NSArray))
                        
                        self.arrToDisplay = self.arrFollower
                        
                        self.setupTableViewData()
                    } else {
                        self.tblRemoveIzlitFriends.reloadData()
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
}


// MARK: - UITableViewDataSource, UITableViewDelegate methods
extension RemoveIZLITFreindsVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedFirstLetters[section]
    }
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: self.tblRemoveIzlitFriends.frame.width, height: 30))
        returnedView.backgroundColor = UIColor.white
        
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: 30, height: 30))
        label.font = UIFontConst.POPPINS_REGULAR
        label.text = self.sortedFirstLetters[section]
        returnedView.addSubview(label)
        
        return returnedView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sections.count == 0 {return UITableViewCell()}
        let contact = sections[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.cellRemoIzlitFriends.rawValue, for: indexPath) as! ContactCell
        cell.imgContactProfilePicture.layer.cornerRadius = 2.0 //cell.imgContactProfilePicture.frame.height / 2.0
//        cell.imgContactProfilePicture.clipsToBounds = true
        cell.btnContactInvite.layer.borderColor = UIColor.gray.cgColor
        cell.btnContactInvite.layer.borderWidth = 1.0
       
        cell.lblContactName.text = (btnFollowing.isSelected ? contact.followee.fullName : contact.follower.fullName )
        // cell.lblContactNumber.text = contact.followee.
        if let url = URL(string: (btnFollowing.isSelected ? contact.followee.profilePic : contact.follower.profilePic)) {
            cell.imgContactProfilePicture.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "img_placeholder"), completed: nil)
        } else{
            cell.imgContactProfilePicture.image = #imageLiteral(resourceName: "img_placeholder")
        }
        //
        cell.btnContactInvite.setTitle(btnFollowing.isSelected ? "Unfollow" :(contact.isFollowed == true ? "Unfollow" : "Follow") , for: .normal)
        cell.btnContactInvite.tag = indexPath.row
        cell.btnContactInvite.addTarget(self, action: #selector(btnFollowAction(_:)), for: .touchUpInside)
        
        cell.btnContactInvite.accessibilityIdentifier = "\(indexPath.section)"
        
        
        return cell
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if btnFollowing.isSelected {//Following
            if pageNumber < totalCount && offsetY > contentHeight - scrollView.frame.size.height {
                self.pageNumber += 1
                self.followingListApi(pageNumber: pageNumber)
                self.tblRemoveIzlitFriends.reloadData()
            }
        } else {//followers
            if pageNumber < totalCount && offsetY > contentHeight - scrollView.frame.size.height {
                self.pageNumber += 1
                self.followerListApi(pageNumber: pageNumber)
                self.tblRemoveIzlitFriends.reloadData()
            }
        }
     }
    
    @objc func btnFollowAction(_ sender: UIButton) {
        if sender.currentTitle == "Follow" {
            followApi(sectionId: Int(sender.accessibilityIdentifier!)!, rowId: sender.tag)
            
        } else if sender.currentTitle == "Unfollow" {
            unFollowApi(sectionId: Int(sender.accessibilityIdentifier!)!, rowId: sender.tag)
            
        } else {
            
        }
        
    }
    
    func unFollowApi(sectionId : Int , rowId: Int) {
        Helper.showProgressBar()
        let contact = sections[sectionId][rowId]
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.connectionId: contact.connecttionId ]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.unFollow, parameter: parameter, onCompletion: { (json, error, response) in
            
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    contact.isFollowed = false
                    
                    if self.btnFollowing.isSelected == true {
                        ( self.sections[sectionId].remove(at: rowId) )
                        if self.sections[sectionId].count == 0 {
                            self.sections.remove(at: sectionId)
                        }
                    }
                    self.tblRemoveIzlitFriends.reloadData()
                    if self.btnFollowing.isSelected == true {
                        self.followingListApi(pageNumber: 1)
                    } else {
                        self.followerListApi(pageNumber: 1)
                    }
                }
                Helper.hideProgressBar()
            }
        }, onError: { (error, response) in
            Helper.hideProgressBar()
            print(error ?? "error")
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    
    
    //MARK:-  Follow APi
    func followApi(sectionId : Int , rowId: Int)  {
        Helper.showProgressBar()
        let contact = sections[sectionId][rowId]
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.followee: contact.follower._id ]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.follow, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    contact.isFollowed = true
                    self.followerListApi(pageNumber: 1)
                    self.tblRemoveIzlitFriends.reloadData()
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
}
