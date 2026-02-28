//
//  FeedCommentViewController.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 01/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

class FeedCommentViewController: UIViewController {

    
    
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var commentTableView: UITableView!
    @IBOutlet weak var tableHeaderView: UIView!
    @IBOutlet weak var commentsCountLabel: UILabel!
    @IBOutlet weak var commentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentViewBottomConstraint: NSLayoutConstraint!
    var feedId : String!
    fileprivate let commentPlaceholderText = "Write a comment..."
    fileprivate let commentViewMinHeight: CGFloat = 34.0
    fileprivate let commentViewMaxHeight: CGFloat = 100.0
    var arrCommentList = [commentList]()
    
    
    
    typealias updateCompletionHandler = (String) -> ()
    var completion : updateCompletionHandler = {_ in }
    //MARK:- UIView Controller Life Cycle Methods -

    override func viewDidLoad() {
        super.viewDidLoad()
        getCommentListFor(feedId: feedId) { (list) in
           self.commentsCountLabel.text = "\(self.arrCommentList.count)"
            self.commentTableView.dataSource = self
            self.commentTableView.delegate = self
            self.commentTableView.reloadData()
        }
        commentTableViewConfigurationMethods()
        configureUI()
        configureCommentView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        IQKeyboardManager.sharedManager().enable = false //Disable IQKeyboardManager for current view controller.

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        IQKeyboardManager.sharedManager().enable = true //Again enable IQKeyboardManager for other view
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    //MARK:- View Controller Other Methods -
    func configureUI() {
       
        self.title =  ViewControllerTitle.commentsList.rawValue
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
       
        dismiss(animated: true) {
            self.completion("")
        }
       
        
    }
    func dismissCompletion(completionHandler: @escaping updateCompletionHandler) {
        self.completion = completionHandler
    }
    func commentTableViewConfigurationMethods() {
        commentTableView.estimatedSectionHeaderHeight = 42.0
        commentTableView.sectionHeaderHeight = 42.0
        commentTableView.estimatedRowHeight = 70.0
        commentTableView.rowHeight = UITableViewAutomaticDimension
    }

    func configureCommentView() {
        commentTextView.text = commentPlaceholderText
    }
    
    func getDateTimeFromDate(serverDate: Date) -> String {
        return Date().getDifferanceFromCurrentTime(serverDate: serverDate)
        
    }

    //MARK:- IBAction Methods -

    @IBAction func commentSendTapped(_ sender: UIButton) {
        if commentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines) == "" || commentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines) == commentPlaceholderText {
            Helper.showAlertDialog(APP_NAME, message: AppMessage.enterComment.rawValue, clickAction: {})
        } else {
            sendCommentFor(feedId: feedId, compilation: { (sucsses) in
                
                self.commentTextView.text = self.commentPlaceholderText
                self.commentTextViewHeightConstraint.constant = self.commentViewMinHeight
                self.getCommentListFor(feedId: self.feedId) { (list) in
                    self.commentsCountLabel.text = "\(self.arrCommentList.count)"
                    self.commentTableView.dataSource = self
                    self.commentTableView.delegate = self
                    self.commentTableView.reloadData()
                }
                self.completion(self.feedId)
            })
        }
    }
    
    
    
    
    
    //MARK:- API calls
    func sendCommentFor(feedId:String!,compilation:@escaping ContactHandler)  {
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.feedId: feedId , WebserviceRequestParmeterKey.commentText: commentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)]
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.insertcomment, parameter: parameter, onCompletion: { (json, error, response) in
            self.commentTextView.resignFirstResponder()
            if error == nil {
                 if (response as! HTTPURLResponse).statusCode == 200  {
                    compilation(true)
                }
            }
        }, onError: { (error, response) in
            print(error ?? "error")
             self.commentTextView.resignFirstResponder()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    func getCommentListFor(feedId:String, compilation:@escaping ContactHandler) {
        
        Helper.showProgressBar()
        
        ApiManager.Instance.sendHttpGetWithHeader(path: "\(WebserverPath.commentList)/\(feedId)"   , onComplete: { (json, error, response) in
            
            if error == nil {
                if let dictList = json.dictionaryObject as Dictionary? {
                    if dictList["doc"] != nil{
                        
                self.arrCommentList = commentList.Populate(list: dictList["doc"] as! Array<Any>)
                        
                    }
                    compilation(true)
                    
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
}

//MARK:- UITableView Delegate & Data Source Methods -

extension FeedCommentViewController: UITableViewDelegate, UITableViewDataSource {

    //MARK:- UITableView Data Source Methods -

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCommentList.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableHeaderView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let commentCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.feedCommentCell.rawValue, for: indexPath) as? FeedCommentCell else {
            return UITableViewCell()
        }
        commentCell.commenterName.text = arrCommentList[indexPath.row].fullName
        commentCell.commentLabel.text = arrCommentList[indexPath.row].commentText.trimmingCharacters(in: .whitespacesAndNewlines)
//        let createdDate = Date().getDifferanceFromCurrentTime(serverDate: arrCommentList[indexPath.row].createdAt! as Date)
        
        commentCell.timeLabel.text = self.getDateTimeFromDate(serverDate: arrCommentList[indexPath.row].createdAt! as Date)
        if arrCommentList[indexPath.row].profilePic.count > 0 {
            commentCell.commenterImageView.sd_setImage(with:URL(string:  arrCommentList[indexPath.row].profilePic), placeholderImage: #imageLiteral(resourceName: "img_placeholder"), completed: nil)
        } else{
            commentCell.commenterImageView.image = #imageLiteral(resourceName: "img_placeholder")
        }
        return commentCell
    }


}

//MARK:- UITextView Delegate Methods -

extension FeedCommentViewController: UITextViewDelegate {

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.text = textView.text == commentPlaceholderText ? "" : textView.text
        textView.isScrollEnabled = (textView.contentSize.height > commentViewMaxHeight)
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        let size = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        self.commentTextViewHeightConstraint.constant = size.height.clamped(to: commentViewMinHeight...commentViewMaxHeight)

        if textView.contentSize.height < commentViewMaxHeight {
            textView.setContentOffset(CGPoint.zero, animated: false)
            if textView.isScrollEnabled {
                textView.isScrollEnabled = false
            }
        } else {
            if !textView.isScrollEnabled {
                textView.isScrollEnabled = true
            }
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let isCommentAvaiable = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).count != 0
        textView.text = isCommentAvaiable ? textView.text.trimmingCharacters(in: .whitespacesAndNewlines) : commentPlaceholderText
        if textView.contentSize.height < commentViewMaxHeight {
            commentTextView.setContentOffset(.zero, animated: true)
        }
    }
}

//MARK: UIView Controller Selector Methods -

extension FeedCommentViewController {

    @objc func keyboardWillShow(_ notification: NSNotification) {
        let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        let animationType = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt
        
        self.commentViewBottomConstraint.constant = keyboardSize?.height ?? 0

        UIView.animateKeyframes(withDuration: animationDuration ?? 0.5, delay: 0, options: UIViewKeyframeAnimationOptions(rawValue: animationType ?? 0), animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc func keyboardWillHide(_ notification: NSNotification) {
        commentViewBottomConstraint.constant = 0
    }
}
