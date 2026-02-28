//
//  StoryCapture.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 13/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//



import UIKit
import AVFoundation

class StoryCapture: SwiftyCamViewController, SwiftyCamViewControllerDelegate {
    
    @IBOutlet weak var progres: RPCircularProgress!
    @IBOutlet weak var captureButton: SwiftyRecordButton!
    @IBOutlet weak var flashButton: UIButton!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getBuildAndVersionNumber()
        
        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            //            print("App running in Simulator")
        #else
            cameraDelegate = self
            maximumVideoDuration = 10.0
            shouldUseDeviceOrientation = true
            allowAutoRotate = true
            audioEnabled = true
        #endif
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setUpNavigationBar()
    }
    
    func getBuildAndVersionNumber() {
        let strVersionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        UserDefaultHelper.setPREF(strVersionNumber, key: AppUserDefaults.pref_version_number)
        
        let strBuildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        UserDefaultHelper.setPREF(strBuildNumber, key: AppUserDefaults.pref_build_number)
    }
    
    
    func setUpNavigationBar()  {
        self.captureButton.isUserInteractionEnabled = true
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.backgroundColor = UIColor.clear
        
        navigationController?.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        let rightBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "img_camera-flip"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.rightBarButtonAction))
        self.navigationItem.rightBarButtonItem = rightBarButton
        let leftBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "img_setting"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarButtonAction))
        self.navigationItem.leftBarButtonItem = leftBarButton
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
    }
    @objc func rightBarButtonAction(){
        switchCamera()
    }
    @objc func leftBarButtonAction(){
        setupActionSheetData()
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            //            print("App running in Simulator")
        #else
            captureButton.delegate = self
        #endif
        
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        captureButton.delegate = nil
        self.captureButton.isUserInteractionEnabled = false
        let photoVc = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.Photo.rawValue) as! PhotoViewController
        photoVc.backgroundImage = photo
        self.present(UINavigationController(rootViewController: photoVc), animated: false, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        
        progres.updateProgress(1, initialDelay: 0.0, duration: 10)
        captureButton.growButton()
        UIView.animate(withDuration: 0.25, animations: {
            self.flashButton.alpha = 0.0
            //self.flipCameraButton.alpha = 0.0
        })
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        captureButton.delegate = nil
        progres.updateProgress(0.0)
        // stopTimer()
//        captureButton.shrinkButton()
        UIView.animate(withDuration: 0.25, animations: {
            self.flashButton.alpha = 1.0
            //self.flipCameraButton.alpha = 1.0
        })
    }
    func setupActionSheetData() {
        
        self.present(Helper.getActionSheetForMenu(navigation: self.navigationController!), animated: true, completion: nil)
    }
   
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        captureButton.shrinkButton()
        captureButton.delegate = nil
        let asset = AVAsset(url: url)
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        if durationTime >= 3 {
            let videoVc = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.video.rawValue) as! VideoViewController
            videoVc.videoURL = url
            self.present(UINavigationController(rootViewController: videoVc), animated: false, completion: nil)
        } else {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.videoLength.rawValue, clickAction: {
                
                self.progres.updateProgress(0.0)
               
                self.captureButton.delegate = self
            })
        }
        
    }
    
    @IBAction func btnHistoryAction(_ sender: Any) {
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
            feedVC.isFromStoryCapture = true
            Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
        } else {
            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyLoginMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Login", onButton1Click: {
            }, onButton2Click: {
                Helper.navigateToLogin(navigation: self.navigationController!)
            })
        }
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }, completion: { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }, completion: { (success) in
                focusView.removeFromSuperview()
            })
        })
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
    }
    
    @IBAction func btnHomeTapped(_ sender: UIButton) {
        Helper.Push_Pop_to_ViewController(destinationVC: Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.home.rawValue), isAnimated: true, navigationController: self.navigationController!)
    }
    
    @IBAction func btnToggleFlash(_ sender: UIButton) {
        
        flashEnabled = !flashEnabled
        
        if flashEnabled == true {
            flashButton.setImage(#imageLiteral(resourceName: "flash"), for: UIControlState())
        } else {
            flashButton.setImage(#imageLiteral(resourceName: "flashOutline"), for: UIControlState())
        }
    }
    
    @IBAction func btnILHomeTapped(_ sender: UIButton) {
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            let notificationVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.notification.rawValue) as! NotificationViewController
            let navController = UINavigationController(rootViewController: notificationVC)
            self.navigationController?.present(navController, animated: true, completion: nil)
        } else {
            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyLoginMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Login", onButton1Click: {
            }, onButton2Click: {
                Helper.navigateToLogin(navigation: self.navigationController!)
            })
        }
    }
    
    @IBAction func toggleFlashTapped(_ sender: Any) {
        
    }
}

