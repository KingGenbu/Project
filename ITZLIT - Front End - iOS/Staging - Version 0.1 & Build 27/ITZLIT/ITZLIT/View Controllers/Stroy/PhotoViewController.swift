//
//  StoryCapture.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 13/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//


import UIKit
import IQKeyboardManagerSwift

class PhotoViewController: UIViewController, UITextFieldDelegate{
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet weak var txtTellAbout: UITextField!
    var backgroundImage: UIImage!
    @IBOutlet var btnDownload: UIButton!
    @IBOutlet var btnsend: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IQKeyboardManager.sharedManager().enableAutoToolbar = true
        self.view.backgroundColor = UIColor.gray
        let backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIViewContentMode.scaleAspectFill
        backgroundImageView.image = backgroundImage
        view.addSubview(backgroundImageView)
        view.sendSubview(toBack: backgroundImageView)
        self.txtTellAbout.delegate = self
        DispatchQueue.main.async {
            self.btnDownload.layer.cornerRadius = self.btnDownload.frame.height / 2.0
            self.btnDownload.clipsToBounds = true
            self.btnsend.layer.cornerRadius = self.btnsend.frame.height / 2.0
            self.btnsend.clipsToBounds = true
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    func setupNavigationBar() {
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.backgroundColor = UIColor.clear
        navigationController?.view.backgroundColor = UIColor.clear
        navigationController?.navigationBar.tintColor = UIColor.white
        
        let rightBarSettingButton = UIBarButtonItem(image: UIImage(named: "img_setting"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnRightBarSettingTapped(_:)))
        self.navigationItem.rightBarButtonItem = rightBarSettingButton
        
        let leftBarCloseButton = UIBarButtonItem(image: UIImage(named: "img_close"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(btnLeftBarCloseTapped(_:)))
        self.navigationItem.leftBarButtonItem = leftBarCloseButton
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
    }
    
    @objc func btnRightBarSettingTapped(_ sender: UIBarButtonItem) {
        self.present(Helper.getActionSheetForMenu(navigation: self.navigationController!), animated: true, completion: nil)
    }
    
    @objc func btnLeftBarCloseTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func btnSendAction(_ sender: Any) {
        
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            
            let sendTOVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.sendTo.rawValue) as! SendToViewController
            sendTOVC.strAboutStrory = txtTellAbout.text!
            sendTOVC.mediaType = "StoryImage"
            sendTOVC.shardImage = backgroundImage
            self.navigationController?.pushViewController(sendTOVC, animated: true)
            
        } else {
            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyLoginMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Login", onButton1Click: {
            }, onButton2Click: {
                Helper.navigateToLogin(navigation: self.navigationController!)
            })
        }
    }
    
    @IBAction func btnDownloadAtion(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(backgroundImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let _ = error {
            // we got back an error!
            
            let ac = UIAlertController(title: APP_NAME, message: "Please allow permission from settings to save photo in gallery", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: APP_NAME, message: "Your image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.txtTellAbout {
            
            let newString = NSString(string: self.txtTellAbout.text!).replacingCharacters(in: range, with: string)
            let newLength = newString.count
            if newLength == 100 {
                return newLength <= 100
            }  else {
                return newLength <= 100
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        txtTellAbout.resignFirstResponder()
        return true
    }
}
