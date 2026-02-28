//
//  SearchItzlitFriendsVC.swift
//  ITZLIT
//
//  Created by devang.bhatt on 13/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class SearchItzlitFriendsVC: UIViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tblGlobalData: UITableView!
    
    var arrGlobalSearchData : [GlobalSearch] = []
    var syncedContacts:[ContactLIst]!
    
    var totalCount:Int = 0
    var pageNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureUI() {
        self.title = ViewControllerTitle.searchGlobal.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let leftBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: .plain, target: self, action: #selector(btnBackTapped(_:)))
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
    }
    
    @objc func btnBackTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func unFollowApi(index : Int )  {
        Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.connectionId: self.arrGlobalSearchData[index].connecttionId]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.unFollow, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    self.arrGlobalSearchData[index].isFollowed = false
                    self.tblGlobalData.reloadData()
                }
            }
        }, onError: { (error, response) in
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
            Helper.hideProgressBar()
            print(error ?? "error")
        })
    }
    //MARK:-  Follow APi
    func followApi(index : Int )  {
        Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.followee: self.arrGlobalSearchData[index]._id]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.follow, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    self.arrGlobalSearchData[index].isFollowed = true
                    self.arrGlobalSearchData[index].connecttionId = json.dictionaryObject!["connectionId"] as? String //connecttionId
                    self.tblGlobalData.reloadData()
                }
            }
        }, onError: { (error, response) in
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
            print(error ?? "error")
        })
    }
    
    @objc func btnFollowAction(_ sender: UIButton) {
        if sender.currentTitle == "Follow" {
            followApi(index: sender.tag)
        } else if sender.currentTitle == "Unfollow" {
            unFollowApi(index: sender.tag)
        } else {
            
        }
        
    }
    
    func WSGlobalSearchCalled(searchName:String, pageNumber: Int) {
 
        var originalURL = WebserverPath.globalSearch+searchName+"&page="+"\(pageNumber)"
        
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        //
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: originalURL, onComplete: { (json, error, response) in
            if error == nil {
                 if (response as! HTTPURLResponse).statusCode == 200 {
                    
                    var globalSearchData = GlobalSearch(values: [:])
                    if let resultData = json.dictionaryObject!["results"]  as? [String:Any] {
                        
                        if let totalPages = resultData["pages"] as? Int {
                            self.totalCount = totalPages
                            
                            if let pageNumber = resultData["page"] as? String {
                                self.pageNumber = Int(pageNumber)!
                            }
                        }
                        
                        if let arrData = resultData["docs"] as? [[String:Any]] {
                            for data in arrData {
                                globalSearchData = GlobalSearch(values: data)
                                self.arrGlobalSearchData.append(globalSearchData)
                            }
                            self.tblGlobalData.reloadData()
                        }
                    }
                } else {
                    print((response as! HTTPURLResponse).statusCode)
                }
             } else {
                print("error: ", error?.localizedDescription ?? "error in global search")
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
}

extension SearchItzlitFriendsVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrGlobalSearchData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = arrGlobalSearchData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.globalSearchCell.rawValue, for: indexPath) as! ContactCell
        if let fullName = data.fullName {
            cell.lblContactName.text = fullName
        }
        if let phoneNumber = data.phoneNumber {
            cell.lblContactNumber.text = phoneNumber
        }
        if let url = data.profilePic {
            cell.imgContactProfilePicture.sd_setShowActivityIndicatorView(true)
            cell.imgContactProfilePicture.sd_setIndicatorStyle(.gray)
            cell.imgContactProfilePicture.sd_setImage(with: URL(string: url), completed: nil)
        } else {
            cell.imgContactProfilePicture.image = #imageLiteral(resourceName: "img_placeholder")
        }
//        cell.imgContactProfilePicture.layer.masksToBounds = true
        cell.btnContactInvite.layer.borderColor = UIColor.gray.cgColor
        cell.btnContactInvite.layer.borderWidth = 1.0
        
        cell.btnContactInvite.addTarget(self, action: #selector(btnFollowAction(_:)), for: .touchUpInside)
        cell.btnContactInvite.tag = indexPath.row
        if data.isFollowed == false {
            cell.btnContactInvite.setTitle("Follow", for: .normal)
//            cell.btnContactInvite.layer.cornerRadius = cell.btnContactInvite.frame.width / 4.0
        } else {
            cell.btnContactInvite.setTitle("Unfollow", for: .normal)
//            cell.btnContactInvite.layer.cornerRadius = cell.btnContactInvite.frame.width / 5.0
        }
        cell.btnContactInvite.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if pageNumber < totalCount && indexPath.row == (arrGlobalSearchData.count - 1) {
            self.pageNumber += 1
            self.WSGlobalSearchCalled(searchName: searchBar.text!, pageNumber: pageNumber)
            tblGlobalData.reloadData()
        }
    }
}

extension SearchItzlitFriendsVC: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.arrGlobalSearchData = []
        self.WSGlobalSearchCalled(searchName: searchBar.text!, pageNumber: 1)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == "" {
            self.arrGlobalSearchData = []
            self.WSGlobalSearchCalled(searchName: searchBar.text!, pageNumber: 1)
        }
    }
}
