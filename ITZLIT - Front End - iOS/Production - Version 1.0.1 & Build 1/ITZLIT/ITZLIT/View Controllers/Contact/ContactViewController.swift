//
//  ContactViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 27/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Contacts
import MessageUI
import libPhoneNumber_iOS

class ContactViewController: UIViewController {
    
    @IBOutlet weak var vwRectangleRound: UIView!
    @IBOutlet var tblContactList: UITableView!
    @IBOutlet var vwContactHeader: UIView!
    @IBOutlet var vwSearch: UIView!
    @IBOutlet var btnSearchClose: UIButton!
    @IBOutlet var txtSearch: UITextField!
    
    var contacts: [CNContact]!
    
    var syncedContacts:[ContactLIst]!
    var arrFilteredContact:[ContactLIst]! = []
    var isFilterData:Bool = false
    var arrDbContctList:[DBContactLIst]!
    var arrFilterdDbContctList:[DBContactLIst]!
    var arrToDisplay:[DBContactLIst]!
    var rightBarBackButton = UIBarButtonItem()
    var leftBarSearchButton = UIBarButtonItem()
    var lblNoDataFound : UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        tblContactList.dataSource = nil
        tblContactList.delegate = nil
        vwRectangleRound.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapToNavigateRemoveIzlitFriendVC(_:))))
        vwContactHeader.dropShadow(scale: true)
        self.vwRectangleRound.layer.cornerRadius = 10.0
        self.vwRectangleRound.layer.borderColor = UIColor(red: 7.0/255.0, green: 20.0/255.0, blue: 46.0/255.0, alpha: 1.0).cgColor
        self.vwRectangleRound.layer.borderWidth = 2.0
        tblContactList.layer.cornerRadius = 2.0
        tblContactList.layer.borderWidth = 0.25
        tblContactList.layer.borderColor = UIColor.lightGray.cgColor
        self.txtSearch.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.font: UIFontConst.ROBOTO_LIGHT ?? UIFont.boldSystemFont(ofSize: 14.0)])
        
        txtSearch.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        ContactManager.shared.checkContactsAccess { (sucess) in
            if sucess {
                self.arrDbContctList =  DBManager.shared.getAllContacts()
                NotificationCenter.default.addObserver(self, selector: #selector(ContactViewController.handleStoreDidChangeNotification(_:)), name: NSNotification.Name(rawValue: "handleStoreDidChangeNotification"), object: nil)
                
                if !ContactManager.shared.inProgressSync {
                    if self.arrDbContctList.count == 0 {
                        Helper.showProgressBar()
                    }
                    DispatchQueue.main.async {
                        self.fetchContactList()
                    }
                } else {
                    Helper.showProgressBar()
                }
            } else {
                Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: "Allow access to contact from settings", button1Title: "OK", button1ActionStyle: UIAlertActionStyle.default, button2Title: "Settings", onButton1Click: nil, onButton2Click: {
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: { (success) in
                            if success {
                                //                                print("Settings opened: \(success)") // Prints true
                            }
                        })
                    }
                })
            }
        }
        
    }
    
    func setupNoDataLabel() {
        self.lblNoDataFound = UILabel(frame: CGRect(x: (self.view.frame.origin.x / 2), y: (self.view.frame.origin.y / 2) - 64, width: self.view.frame.width, height: 100))
        
        self.lblNoDataFound.text = AppMessage.noContactFound.rawValue
        
        self.lblNoDataFound.textColor = UIColor(red: 23.0/255.0, green: 23.0/255.0, blue: 23.0/255.0, alpha: 1)
        
        self.lblNoDataFound.center = self.view.center
        self.lblNoDataFound.textAlignment = .center
        self.lblNoDataFound.font = UIFontConst.POPPINS_REGULAR
    }
    
    func fetchContactList()  {
        arrDbContctList =  DBManager.shared.getAllContacts()
        
        if arrDbContctList.count == 0 {
            DBManager.shared.copyDatabaseIfNeeded()
            
            ContactManager.shared.setUpContactToDbWith(Loader: false, onCompletion: {(refres) in
                Helper.hideProgressBar()
                self.arrDbContctList =  DBManager.shared.getAllContacts()
                self.arrToDisplay = self.sorted(List: self.arrDbContctList)
                self.tblContactList.dataSource = self
                self.tblContactList.reloadData()
                self.hideUnhideTableView()
                ContactManager.shared.dbUpadting = nil
            })
        } else {
            
            
            DispatchQueue.main.async {
                Helper.hideProgressBar()
                self.arrDbContctList =  DBManager.shared.getAllContacts()
                self.arrToDisplay = self.sorted(List: self.arrDbContctList)
                self.tblContactList.dataSource = self
                self.tblContactList.reloadData()
                self.hideUnhideTableView()
            }
        }
        
    }
    
    func hideUnhideTableView()  {
        if arrToDisplay.count <= 0 {
            self.tblContactList.isHidden = true
            self.setupNoDataLabel()
            self.view.addSubview(self.lblNoDataFound)
        } else {
            self.tblContactList.isHidden = false
        }
        
    }
    
    func sorted(List:[DBContactLIst]) ->[DBContactLIst]  {
        
        let arrUser = List.filter({$0.app_user == true}).sorted{ $0.name?.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
        let arrOther = List.filter({$0.app_user == false}).sorted{ $0.name?.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
        return  uniqueElementsFrom(array: arrUser + arrOther)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavigationController()
        //  self.fetchContactList()
    }
    
    @objc func handleStoreDidChangeNotification(_ notification: Notification) {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "handleStoreDidChangeNotification"), object: nil)
        if notification.object  == nil {
            DBManager.shared.clearDb()
        }
        if (notification.object as? String) != "Stop" {
            print("stop")
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async() {
                    Helper.showProgressBar()
                }
            }
            DispatchQueue.global(qos: .background).async {
                self.fetchContactList()
            }
            self.tblContactList.isHidden = false
        } else {
            self.tblContactList.isHidden = true
            self.setupNoDataLabel()
            self.view.addSubview(self.lblNoDataFound)
            Helper.hideProgressBar()
        }
        
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ContactViewController.handleStoreDidChangeNotification(_:)), name: NSNotification.Name(rawValue: "handleStoreDidChangeNotification"), object: nil)
    }
    func setupNavigationController()  {
        
        self.title = "ITZLIT FRIENDS"
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        rightBarBackButton = UIBarButtonItem(image: UIImage(named: "img_search"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(rightBarSearchButton(_:)))
        self.navigationItem.rightBarButtonItem = rightBarBackButton
        
        leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton
        
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)
        statusBar.tintColor = .white
    }
    
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @objc func rightBarSearchButton(_ sender:UIBarButtonItem)  {
        self.navigationItem.titleView = self.vwSearch
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = nil
        self.txtSearch.delegate = self
        self.txtSearch.becomeFirstResponder()
    }
    
    @IBAction func btnSearchCloseTapped(_ sender: UIButton) {
        self.navigationItem.titleView = nil
        self.txtSearch.delegate = nil
        self.navigationItem.rightBarButtonItem = self.rightBarBackButton
        self.navigationItem.leftBarButtonItem = self.leftBarSearchButton
        self.txtSearch.text = ""
        self.arrToDisplay = sorted(List: arrDbContctList)
        self.tblContactList.reloadData()
        
        
        DispatchQueue.main.async {
            if self.arrToDisplay.count > 0 {
                self.tblContactList.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
            
        }
        
    }
    
    @objc func tapToNavigateRemoveIzlitFriendVC(_ sender: UITapGestureRecognizer) {
        let removeItzlitFriindVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.removeItzlitFriend.rawValue) as! RemoveIZLITFreindsVC
        self.navigationItem.titleView = nil
        navigationController?.pushViewController(removeItzlitFriindVC, animated: true)
    }
    
    func syncContact() -> NSMutableArray  {
        let finalList = NSMutableArray()
        for contact in contacts {
            var contactToSend = [String:Any]()
            contactToSend["deviceContactId"] = contact.identifier
            var phNumber : String = ""
            for phoneNumber in contact.phoneNumbers {
                phNumber = phoneNumber.value.stringValue
            }
            contactToSend["number"] = phNumber
            finalList.add(contactToSend)
        }
        return finalList
    }
    //MARK:- contact sync
    func contactSyncApi() {
        let regionCode = Locale.current.regionCode
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.regionCode: regionCode!,
                                        WebserviceRequestParmeterKey.contactListTOsyc : self.syncContact()]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.contactsyc, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if json.count > 0 && (response as! HTTPURLResponse).statusCode == 200  {
                    self.syncedContacts = ContactLIst.Populate(list: json.arrayObject! as NSArray)
                    let sortedArray = self.syncedContacts.sorted {
                        $0.connection._id.count > $1.connection._id.count
                    }
                    
                    self.syncedContacts = sortedArray
                    for index in 0...self.syncedContacts.count-1 {
                        if self.syncedContacts[index].connection._id.count == 0 {
                            let filteredContact = self.contacts.filter{$0.identifier == self.syncedContacts[index].deviceContactId}
                            
                            if let givenName = filteredContact[0].givenName as String?, let familyName = filteredContact[0].familyName as String? {
                                self.syncedContacts[index].connection.fullName = givenName + " " + familyName
                            }
                            if let imageData = filteredContact[0].imageData {
                                let userImage = UIImage(data: imageData)
                                self.syncedContacts[index].image = userImage
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.tblContactList.dataSource = self
                        //self.tblContactList.delegate = self
                        self.tblContactList.reloadData()
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
    
    func unFollowApi(index : Int )  {
        Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.connectionId: self.arrToDisplay[index].connection_id! ]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.unFollow, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    self.arrToDisplay[index].following = false
                    let parameter = ContactLIst()
                    parameter.connection.fullName = self.arrToDisplay[index].name!
                    parameter.number = self.arrToDisplay[index].number!
                    parameter.connection.phoneNumber = self.arrToDisplay[index].number!
                    parameter.deviceContactId = self.arrToDisplay[index].identifier!
                    parameter.connection.isFollowed = self.arrToDisplay[index].following!
                    parameter.connection.connecttionId = self.arrToDisplay[index].connection_id!
                    parameter.connection._id = self.arrToDisplay[index].user_id!
                    DBManager.shared.updateContactWith(parameter: parameter)
                    self.tblContactList.reloadData()
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
    //MARK:-  Follow APi
    func followApi(index : Int )  {
        Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.followee: self.arrToDisplay[index].user_id!]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.follow, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    self.arrToDisplay[index].connection_id = json.dictionaryObject!["connectionId"] as? String
                    self.arrToDisplay[index].following = true
                    self.tblContactList.reloadData()
                    let parameter = ContactLIst()
                    parameter.connection.fullName = self.arrToDisplay[index].name!
                    parameter.number = self.arrToDisplay[index].number!
                    parameter.connection.phoneNumber = self.arrToDisplay[index].number!
                    parameter.deviceContactId = self.arrToDisplay[index].identifier!
                    parameter.connection.isFollowed = self.arrToDisplay[index].following!
                    parameter.connection.connecttionId = self.arrToDisplay[index].connection_id!
                    parameter.connection._id = self.arrToDisplay[index].user_id!
                    DBManager.shared.updateContactWith(parameter: parameter)
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
    
    /// Send Invitation Web service method
    func WSSendInvitationCall(index : Int) {
        let countryCode = Locale.current.regionCode
        let phoneUtil = NBPhoneNumberUtil()
        var formattedNumber: String = ""
        var isValidNumber: Bool = false
        do {
            let myNum = try phoneUtil.parse(self.arrToDisplay[index].number!, defaultRegion: countryCode)
            //            print("E164 num: ", try! phoneUtil.format(myNum, numberFormat: NBEPhoneNumberFormat.E164) )
            do {
                isValidNumber = phoneUtil.isPossibleNumber(myNum)
               // print(phoneUtil.isPossibleNumber(myNum), isValidNumber)
                formattedNumber = try phoneUtil.format(myNum, numberFormat: NBEPhoneNumberFormat.E164)
            } catch {
                //                print("number is in not formatted")
            }
            //            print("E164 num : ", phoneUtil.isPossibleNumber(myNum) )
        } catch {
//            print("not valid number")
        }
        if isValidNumber == true {
            let dictParameter: [String:Any] = [WebserviceRequestParmeterKey.phoneNumber : formattedNumber]
            
            ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.sendInvitation, parameter: dictParameter, onCompletion: { (json, error, response) in
                if error == nil {
                    if (response as? HTTPURLResponse)?.statusCode == 200 {
                        if let message = json.dictionaryObject!["message"] as? String {
                            Helper.showAlertDialog(APP_NAME, message: message, clickAction: {})
                        }
                    } else {
                        print(error?.localizedDescription ?? "error")
                    }
                }
            }) { (error, response) in
                print(error?.localizedDescription ?? "error")
            }
        }
    }
}

extension ContactViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        txtSearch.resignFirstResponder()
        return true
    }
    
    
    @objc func textFieldDidChange(_ theTextField: UITextField) {	
        if self.arrDbContctList != nil && self.arrDbContctList.count > 0 {
            self.arrFilterdDbContctList = self.arrDbContctList.filter({ (model) -> Bool in
                return model.name!.lowercased().contains(txtSearch.text!.lowercased())
                
            })
            if txtSearch.text!.count > 0 {
                self.arrToDisplay = sorted(List: self.arrFilterdDbContctList)
            } else {
                self.arrToDisplay = sorted(List: arrDbContctList)
            }
            self.tblContactList.reloadData()
            
            self.tblContactList.scrollsToTop = true
            
        }
    }
    
}


extension ContactViewController: UITableViewDataSource, UIActivityItemSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrToDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.contactCell.rawValue, for: indexPath) as! ContactCell
        
        cell.lblContactName.text = self.arrToDisplay[indexPath.row].name?.replacingOccurrences(of: "''", with: "'")
        cell.lblContactNumber.text = self.arrToDisplay[indexPath.row].number
        cell.btnContactInvite.layer.borderColor = UIColor.gray.cgColor
        cell.btnContactInvite.layer.borderWidth = 1.0
        cell.imgContactProfilePicture.image = #imageLiteral(resourceName: "img_profile")
        cell.btnContactInvite.setTitle((self.arrToDisplay[indexPath.row].app_user == false ? "+ Add" : (self.arrToDisplay[indexPath.row].following == false ? "Follow" : "Unfollow") ), for: .normal)
        cell.btnContactInvite.tag = indexPath.row
        cell.btnContactInvite.addTarget(self, action: #selector(btnFollowAction(_:)), for: .touchUpInside)
        
        if self.arrToDisplay[indexPath.row].profilePic != nil  {
            cell.imgContactProfilePicture.sd_setImage(with: URL(string: self.arrToDisplay[indexPath.row].profilePic! ), placeholderImage: #imageLiteral(resourceName: "img_placeholder"), completed: nil)
        } else {
            cell.imgContactProfilePicture.image = #imageLiteral(resourceName: "img_placeholder")
        }
        
        
        
        //        if self.isFilterData == true {
        //            cell.lblContactName.text = self.arrFilteredContact[indexPath.row].connection.fullName
        //            cell.lblContactNumber.text = self.arrFilteredContact[indexPath.row].number
        //            if let image = self.arrFilteredContact[indexPath.row].image {
        //                cell.imgContactProfilePicture.image = image
        //            } else {
        //                cell.imgContactProfilePicture.image = #imageLiteral(resourceName: "img_profile")
        //            }
        //        } else {
        //            cell.lblContactName.text = self.syncedContacts[indexPath.row].connection.fullName
        //            cell.lblContactNumber.text = self.syncedContacts[indexPath.row].number
        //            if let image = self.syncedContacts[indexPath.row].image {
        //                cell.imgContactProfilePicture.image = image
        //            } else {
        //                cell.imgContactProfilePicture.image = #imageLiteral(resourceName: "img_profile")
        //            }
        //        }
        //        cell.btnContactInvite.setTitle((self.syncedContacts[indexPath.row].connection._id.characters.count == 0 ? "Invite" : (self.syncedContacts[indexPath.row].connection.isFollowed == false ? "Follow" : "Unfollow") ), for: .normal)
        //
        //        cell.btnContactInvite.tag = indexPath.row
        //        cell.lblContactName.text = self.syncedContacts[indexPath.row].connection.fullName
        //        cell.btnContactInvite.addTarget(self, action: #selector(btnFollowAction(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc func btnFollowAction(_ sender: UIButton) {
        if sender.currentTitle == "Follow" {            
            followApi(index: sender.tag)
        } else if sender.currentTitle == "Unfollow" {
            unFollowApi(index: sender.tag)
        } else {
            /// Send Invitation web service called.
            self.WSSendInvitationCall(index: sender.tag)
//            let activityVC = UIActivityViewController(activityItems: [URL(string: Helper.invitationLink)!], applicationActivities: nil)
//            activityVC.popoverPresentationController?.sourceView = sender
//            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    
    /// Activity controller delegate methods
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        return URL.init(string: Helper.invitationLink)!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return Helper.invitationLink
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return nil
    }
}
func uniqueElementsFrom(array: [DBContactLIst]) -> [DBContactLIst] {
    //Create an empty Set to track unique items
    var set = Set<String>()
    let result = array.filter {
        guard !set.contains($0.number!) else {
            //If the set already contains this object, return false
            //so we skip it
            return false
        }
        //Add this item to the set since it will now be in the array
        set.insert($0.number!)
        //Return true so that filtered array will contain this item.
        return true
    }
    return result
}
