//
//  StoryCapture.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 13/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//


import UIKit
import AVFoundation
import AVKit
import Photos
import IQKeyboardManagerSwift

class VideoViewController: UIViewController, UITextFieldDelegate {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    @IBOutlet var txtTellAbout: UITextField!
    @IBOutlet var btnDownload: UIButton!
    @IBOutlet var btnsend: UIButton!
    var videoURL: URL!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var playerController : AVPlayerViewController?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        txtTellAbout.delegate = self
        IQKeyboardManager.sharedManager().enableAutoToolbar = true
        setupNavigationBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if player != nil {
            player?.pause()
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc func applicationBecomeActive() {
        if player != nil {
            player?.play()
        }
    }
    
    @objc func applicationEnterBackground() {
        if player != nil {
            player?.pause()
        }
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
        self.present(Helper.getActionSheetForMenu(navigation: self.navigationController!), animated: true, completion: {})
     }
    
    @objc func btnLeftBarCloseTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = AVPlayer(url: videoURL)
        playerController = AVPlayerViewController()
        playerController?.view.contentMode = UIViewContentMode.scaleAspectFill
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = false
        
        playerController!.player = player!
        playerController!.view.frame = view.frame
        self.addChildViewController(playerController!)
        self.view.addSubview(playerController!.view)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer!.frame = self.view.frame
        self.view.layer.insertSublayer(playerLayer!, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
        DispatchQueue.main.async {
            self.btnDownload.layer.cornerRadius = self.btnDownload.frame.height / 2.0
            self.btnDownload.clipsToBounds = true
            self.btnsend.layer.cornerRadius = self.btnsend.frame.height / 2.0
            self.btnsend.clipsToBounds = true
        }
        view.sendSubview(toBack: playerController!.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.player?.play()
        }
        
    }
    
    @IBAction func btnSendAction(_ sender: Any) {
        self.player?.pause()
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            
             let sendTOVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.sendTo.rawValue) as! SendToViewController
            sendTOVC.strAboutStrory = self.txtTellAbout.text
            sendTOVC.mediaType = "StoryVideo"
            sendTOVC.sharedVideo = videoURL
            self.navigationController?.pushViewController(sendTOVC, animated: true)
 
        } else {
             Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyLoginMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Login", onButton1Click: {
                self.player?.play()
            }, onButton2Click: {
                
                Helper.navigateToLogin(navigation: self.navigationController!)
            })
        }
     }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnDownloadAction(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges({ () -> Void in
            
            let _: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL)!
            //            createAssetRequest.placeholderForCreatedAsset
            
        }) { (success, error) -> Void in
            if success {
                let ac = UIAlertController(title: APP_NAME, message: "Your video has been saved to your gallery.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
            }
            else {
                let ac = UIAlertController(title: APP_NAME, message: "Please allow permission from settings to save video in gallery.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true, completion: nil)
            }
        }
    }
    
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: kCMTimeZero)
            self.player!.play()
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        txtTellAbout.resignFirstResponder()
        return true
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
}
