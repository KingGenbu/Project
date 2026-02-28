//
//  RequestListViewController.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 06/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.




import UIKit

class RequestListViewController: UIViewController {
    var listType = ""
    var arrList = [requesterList]()
 
    @IBOutlet weak var lblRequestCount: UILabel!
    @IBOutlet weak var tblList: UITableView!
    @IBOutlet weak var img_Type: UIImageView!
    var feedId:String!
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        self.lblRequestCount.text = ""
        if listType == "request" {
        getList { (list) in
            self.lblRequestCount.text = "\(self.arrList.count)"
            self.tblList.dataSource = self
            self.tblList.reloadData()
         }
    
        } else  {
            getViewerListFor(feedId: feedId, compilation: { (list) in
                self.lblRequestCount.text = "\(self.arrList.count)"
                self.tblList.dataSource = self
                self.tblList.reloadData()
            })
        }
        }
    
   
    func configureUI() {
        self.img_Type.image = listType == "request" ? #imageLiteral(resourceName: "img_notification_black") : #imageLiteral(resourceName: "view")
        self.title = (listType == "request" ? ViewControllerTitle.requestList.rawValue : ViewControllerTitle.viewList.rawValue)
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
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
        if listType == "" {
           dismiss(animated: true, completion: nil)
        }else {
        _ = self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    
    
    func getList(compilation:@escaping ContactHandler) {
        
        Helper.showProgressBar()
        
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.liverequestList, onComplete: { (json, error, response) in
            
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    if let dictList = json.dictionaryObject as Dictionary? {
                        if dictList["doc"] != nil{
                            
                            self.arrList = requesterList.Populate(list: dictList["doc"] as! Array<Any>)
                            
                        }
                        compilation(true)
                        
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
    func getViewerListFor(feedId:String, compilation:@escaping ContactHandler) {
      Helper.showProgressBar()
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.feedId: feedId ]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.viewerList, parameter: parameter, onCompletion: { (json, error, response) in
            Helper.hideProgressBar()
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200  {
                    if let dictList = json.dictionaryObject as Dictionary? {
                        if dictList["doc"] != nil{
                            
                            self.arrList = requesterList.Populate(list: dictList["doc"] as! Array<Any>)
                            
                        }
                        compilation(true)
                        
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
}
extension RequestListViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.listUser.rawValue, for: indexPath) as! ListUser
        cell.lblUserName.text = self.arrList[indexPath.row].user.fullName
        cell.imgUser.layer.cornerRadius = 3
        cell.imgUser.clipsToBounds = true
        if self.arrList[indexPath.row].user.profilePic.count > 0 {
            cell.imgUser.sd_setImage(with:URL(string:  self.arrList[indexPath.row].user.profilePic), placeholderImage: #imageLiteral(resourceName: "img_placeholder"), completed: nil)
        } else{
            cell.imgUser.image = #imageLiteral(resourceName: "img_placeholder")
        }
        return cell
    }
}
class ListUser : UITableViewCell{
    
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
}
