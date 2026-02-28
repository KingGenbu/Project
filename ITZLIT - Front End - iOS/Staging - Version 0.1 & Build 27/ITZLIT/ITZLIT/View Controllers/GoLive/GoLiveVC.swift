//
//  GoLiveVC.swift
//  ITZLIT
//
//  Created by Devang Bhatt on 11/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import WowzaGoCoderSDK
import Alamofire

class GoLiveVC: UIViewController, WZStatusCallback, WZVideoSink, WZAudioSink {
    
    @IBOutlet weak var lblCaption: UILabel!
    @IBOutlet weak var btnBroadCast: UIButton!
    @IBOutlet weak var btnFlash: UIButton!
    @IBOutlet weak var lblGoliveCaption: UILabel!
    
    @IBOutlet weak var imgIL: UIImageView!
    @IBOutlet weak var imgYT: UIImageView!
    @IBOutlet weak var imgFB: UIImageView!
    
    @IBOutlet weak var btnViewer: UIButton!
    @IBOutlet weak var imgILCheckUncheck: UIImageView!
    @IBOutlet weak var imgYTCheckUncheck: UIImageView!
    @IBOutlet weak var imgFBCheckUncheck: UIImageView!
    
    @IBOutlet weak var imgILheight: NSLayoutConstraint!
    @IBOutlet weak var imgYTheight: NSLayoutConstraint!
    @IBOutlet weak var imgFBheight: NSLayoutConstraint!
    
    @IBOutlet weak var imgILCheckHeight: NSLayoutConstraint!
    @IBOutlet weak var imgYTCheckHeight: NSLayoutConstraint!
    @IBOutlet weak var imgFBCheckHeight: NSLayoutConstraint!
    var rightBarCameraButton: UIBarButtonItem = UIBarButtonItem()
    //    var rightBarMicButton: UIBarButtonItem = UIBarButtonItem()
    
    let SDKSampleSavedConfigKey = "SDKSampleSavedConfigKey"
    let SDKSampleAppLicenseKey = ApiManager.wowzaKey
    let BlackAndWhiteEffectKey = "BlackAndWhiteKey"
    var goCoder:WowzaGoCoder?
    var goCoderConfig:WowzaConfig!
    
    var receivedGoCoderEventCodes = Array<WZEvent>()
    var blackAndWhiteVideoEffect = false
    var goCoderRegistrationChecked = false
    
    var isStreamingWSCalled:Bool = true
    var isFeedVC: Bool = false
    var isItzlitOn: Bool = false
    var isYoutubeOn: Bool = false
    var isFBOn: Bool = false
    var strCaption: String = ""
    var ingestionAddress: String = ""
    var streamName: String = ""
    
    var timer:Timer?
    var sec: Int = 0
    var newTorchState = Bool()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.WowzaSetup()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        goCoder?.cameraPreview?.previewLayer?.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func videoFrameWasCaptured(_ imageBuffer: CVImageBuffer, framePresentationTime: CMTime, frameDuration: CMTime) {
        
        if goCoder != nil && goCoder!.isStreaming && blackAndWhiteVideoEffect {
            // convert frame to b/w using CoreImage tonal filter
            var frameImage = CIImage(cvImageBuffer: imageBuffer)
            if let grayFilter = CIFilter(name: "CIPhotoEffectTonal") {
                grayFilter.setValue(frameImage, forKeyPath: "inputImage")
                if let outImage = grayFilter.outputImage {
                    frameImage = outImage
                    
                    let context = CIContext(options: nil)
                    context.render(frameImage, to: imageBuffer)
                }
            }
        }
    }
    
    func onWZEvent(_ status: WZStatus!) {
        // If an event is reported by the GoCoder SDK, display an alert dialog describing the event,
        // but only if we haven't already shown an alert for this event
        DispatchQueue.main.async { () -> Void in
            if !self.receivedGoCoderEventCodes.contains(status.event) {
                self.receivedGoCoderEventCodes.append(status.event)
               // Helper.showAlertDialog(APP_NAME, message: "\(status)", clickAction: {})
            }
            self.updateUIControls()
        }
    }
 
    func initSoket(feedid:String)  {
        let params = [WebserviceRequestParmeterKey.feedId : feedid]
        ILSocketManager.shared.establishConnection(withParams: params)
        ILSocketManager.shared.delegate = self
    }
    
    
    
    /// Get Wowza Status on streaming
    func onWZStatus(_ status: WZStatus!) {
        
        switch status.state {
        case .idle:
            DispatchQueue.main.async { () -> Void in
                self.updateUIControls()
            }
            break
        case .running:
            print("====running=====")
            self.WSStartAndStopPublishing(completionHandler: { (isSucess) in
                if isSucess {
                    DispatchQueue.main.async { () -> Void in
                        self.btnBroadCast.isEnabled = true
                        self.initSoket(feedid: UserDefaultHelper.getPREF(AppUserDefaults.pref_liveStreaming_feedId)!)
                        if self.isItzlitOn == true {
                            self.imgIL.isHidden = false
                            self.imgILCheckUncheck.isHighlighted = true
                        }
                        if self.isFBOn == true {
                            self.imgFB.isHidden = false
                            self.imgFBCheckUncheck.isHighlighted = true
                        }
                        if self.timer == nil {
                            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
                        }
                        self.lblGoliveCaption.text = "I' M  D O N E"
                        self.btnBroadCast.setImage(#imageLiteral(resourceName: "img_stop_button"), for: .normal)
                        self.updateUIControls()
                        if self.isYoutubeOn == true {
                            self.WSCreateBroadcastForYouTube(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!, callback: { (isSucess) in
                                if isSucess {
                                    self.WSBindBroadcastForYouTube(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!, id: UserDefaultHelper.getPREF(AppUserDefaults.pref_broadcast_id)!, streamId: UserDefaultHelper.getPREF("pref_CreateStream_id")!, callback: { (isSuccess) in
                                        if isSuccess{
                                            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0, execute: {
                                                self.WSBrodcastTransition(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!, id: UserDefaultHelper.getPREF(AppUserDefaults.pref_broadcast_id)!, broadcastStatus: "testing", callback: { (isSucess) in
                                                    if isSucess {
                                                        self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.continuousCheckForLiveStreaming), userInfo: nil, repeats: true)
                                                    }
                                                })
                                            })
                                        }
                                    })
                                }
                            })
                        }
                    }
                }
            }, isStartPublishing: true)
            break
        case .starting:
            print("===Starting===")
            break
        case .stopping:
             print("===Stoping===")
            DispatchQueue.main.async { () -> Void in
                if self.sec < 30 {
                    self.WSGoliveSendPushNotification()
                }
                if self.timer != nil{
                    self.timer?.invalidate()
                    self.timer = nil
                }
                self.timer = nil
                self.goCoder?.cameraPreview?.stop()
                
                self.goCoder?.unregisterAudioSink(self as WZAudioSink)
                self.goCoder?.unregisterVideoSink(self as WZVideoSink)
                self.goCoder = nil
                if self.isYoutubeOn == true {
                    self.WSBrodcastTransition(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken) ?? "", id: UserDefaultHelper.getPREF(AppUserDefaults.pref_broadcast_id) ?? "", broadcastStatus: "complete", callback: { (isSucess) in
                        if isSucess {
                            if self.isItzlitOn {
                                var arrNavigationController = self.navigationController?.viewControllers
                                for controller in arrNavigationController! {
                                    if controller.isKind(of: FeedViewController.self) {
                                        let indexOfReg = arrNavigationController?.index(of: controller)
                                        arrNavigationController?.remove(at: indexOfReg!)
                                        self.navigationController?.viewControllers = arrNavigationController!
                                        self.isFeedVC = true
                                        let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                                        Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
                                    }
                                }
                                if !self.isFeedVC {
                                    let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                                    Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
                                }
                            } else {
                                let homeVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.home.rawValue) as! HomeViewController
                                Helper.Push_Pop_to_ViewController(destinationVC: homeVC, isAnimated: true, navigationController: self.navigationController!)
                            }
                        } else {
                            if self.isItzlitOn {
                                
                                var arrNavigationController = self.navigationController?.viewControllers
                                for controller in arrNavigationController! {
                                    if controller.isKind(of: FeedViewController.self) {
                                        let indexOfReg = arrNavigationController?.index(of: controller)
                                        arrNavigationController?.remove(at: indexOfReg!)
                                        self.navigationController?.viewControllers = arrNavigationController!
                                        self.isFeedVC = true
                                        let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                                        Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
                                    }
                                }
                                if !self.isFeedVC {
                                    let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                                    Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
                                }
                            } else {
                                let homeVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.home.rawValue) as! HomeViewController
                                Helper.Push_Pop_to_ViewController(destinationVC: homeVC, isAnimated: true, navigationController: self.navigationController!)
                            }
                        }
                    })
                } else {
                    
                    if self.isItzlitOn {
                        var isFeedVC: Bool = false
                        var arrNavigationController = self.navigationController?.viewControllers
                        for controller in arrNavigationController! {
                            if controller.isKind(of: FeedViewController.self) {
                                let indexOfReg = arrNavigationController?.index(of: controller)
                                arrNavigationController?.remove(at: indexOfReg!)
                                self.navigationController?.viewControllers = arrNavigationController!
                                isFeedVC = true
                                let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                                Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
                            }
                        }
                        if !isFeedVC {
                            let feedVC = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.feedVC.rawValue) as! FeedViewController
                            Helper.Push_Pop_to_ViewController(destinationVC: feedVC, isAnimated: true, navigationController: self.navigationController!)
                        }
                    } else {
                        let homeVC = Helper.mainStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.home.rawValue) as! HomeViewController
                        Helper.Push_Pop_to_ViewController(destinationVC: homeVC, isAnimated: true, navigationController: self.navigationController!)
                    }
                }
            }
 
            break
            
        case .buffering:
            break
        default:
            break
        }
    }
    
    /// Get Wowza Errors
    func onWZError(_ status: WZStatus!) {
        DispatchQueue.main.async { () -> Void in
//            Helper.showAlertDialog(APP_NAME + "Live Streaming Error", message: "\(status)", clickAction:             })
            self.updateUIControls()
        }
    }
}

// MARK: - Custom and Selector Methods
extension GoLiveVC {
    /// Wowza Configuration
    func WowzaSetup() {
        self.goCoder?.unregisterAudioSink(self as WZAudioSink)
        self.goCoder?.unregisterVideoSink(self as WZVideoSink)
        self.goCoder = nil

        blackAndWhiteVideoEffect = UserDefaults.standard.bool(forKey: BlackAndWhiteEffectKey)
        WowzaGoCoder.setLogLevel(.verbose)
        WowzaGoCoder.setLogLevel(.default)
        if let savedConfig:Data = UserDefaults.standard.object(forKey: SDKSampleSavedConfigKey) as? Data {
            if let wowzaConfig = NSKeyedUnarchiver.unarchiveObject(with: savedConfig) as? WowzaConfig {
                goCoderConfig = wowzaConfig
            }
            else {
                goCoderConfig = WowzaConfig()
            }
        }
        else {
            goCoderConfig = WowzaConfig()
        }
        
        // Log version and platform info
//        print("WowzaGoCoderSDK version =\n major: \(WZVersionInfo.majorVersion())\n minor: \(WZVersionInfo.minorVersion())\n revision: \(WZVersionInfo.revision())\n build: \(WZVersionInfo.buildNumber())\n string: \(WZVersionInfo.string())\n verbose string: \(WZVersionInfo.verboseString())")
        
//        print("Platform Info:\n\(WZPlatformInfo.string())")
        
        if let goCoderLicensingError = WowzaGoCoder.registerLicenseKey(SDKSampleAppLicenseKey) {
            Helper.showAlertDialog(APP_NAME + "\n" + "GoCoder SDK Licensing Error" , message: goCoderLicensingError.localizedDescription, clickAction: {})
        }
        
        let savedConfigData = NSKeyedArchiver.archivedData(withRootObject: goCoderConfig)
        UserDefaults.standard.set(savedConfigData, forKey: SDKSampleSavedConfigKey)
        UserDefaults.standard.synchronize()
        
        // Update the configuration settings in the GoCoder SDK
        if (goCoder != nil) {
            goCoder?.config = goCoderConfig
            blackAndWhiteVideoEffect = UserDefaults.standard.bool(forKey: BlackAndWhiteEffectKey)
        }
        
        if !goCoderRegistrationChecked {
            goCoderRegistrationChecked = true
            if let goCoderLicensingError = WowzaGoCoder.registerLicenseKey(SDKSampleAppLicenseKey) {
                
                Helper.showAlertDialog(APP_NAME + "\n" + "GoCoder SDK Licensing Error" , message: goCoderLicensingError.localizedDescription, clickAction: {})
            }
            else {
                // Initialize the GoCoder SDK
                if let goCoder = WowzaGoCoder.sharedInstance() {
                    self.goCoder = goCoder
                    
                    // Request camera and microphone permissions
                    WowzaGoCoder.requestPermission(for: .camera, response: { (permission) in
                        print("Camera permission is: \(permission == .authorized ? "authorized" : "denied")")
                    })
                    
                    WowzaGoCoder.requestPermission(for: .microphone, response: { (permission) in
                        print("Microphone permission is: \(permission == .authorized ? "authorized" : "denied")")
                        if permission == .denied {
                            self.goCoderConfig.audioEnabled = false
                            self.goCoder?.isAudioMuted = true
                        } else {
                            self.goCoderConfig.audioEnabled = true
                            self.goCoder?.isAudioMuted = false
                        }
                    })
                    
                    self.goCoder?.register(self as WZAudioSink)
                    self.goCoder?.register(self as WZVideoSink)
                    
                    self.goCoder?.config = self.goCoderConfig
                    self.goCoder?.config.load(.preset1280x720)
                    self.goCoder?.config.videoBitrate = 1100000
//                    self.goCoder?.config.videoFrameRate = 30

                    // Specify the view in which to display the camera preview
                    self.goCoder?.cameraView = self.view
                    self.goCoder?.status.resetStatus()
                    // Start the camera preview
                    self.goCoder?.cameraPreview?.start()
                }
                self.updateUIControls()
            }
        }
    }
    
    /// Update UI when live streaming state changes.
    func updateUIControls() {
        if self.goCoder?.status.state != .idle && self.goCoder?.status.state != .running {
            
            self.btnBroadCast.isEnabled = true // broadcast
            self.rightBarCameraButton.isEnabled = false // switchcamera
            //            self.rightBarMicButton.isEnabled = false // mic
            self.btnFlash.isEnabled = false // tourch
        } else {
            self.btnBroadCast.isEnabled = true
            self.rightBarCameraButton.isEnabled = ((self.goCoder?.cameraPreview?.cameras?.count) ?? 0) > 1
            self.btnFlash.isEnabled = self.goCoder?.cameraPreview?.camera?.hasTorch ?? false
            //            let isStreaming = self.goCoder?.isStreaming ?? false
            //            self.rightBarMicButton.isEnabled = isStreaming && self.goCoderConfig.audioEnabled
            //            self.rightBarMicButton.isEnabled = !self.rightBarMicButton.isEnabled
        }
        
        if self.isItzlitOn == true {
            self.imgIL.isHidden = false
            self.imgILCheckUncheck.isHidden = false
        } else {
            self.imgILheight.constant = 0.0
            self.imgILCheckHeight.constant = 0.0
        }
        if self.isYoutubeOn == true {
            self.imgYT.isHidden = false
            self.imgYTCheckUncheck.isHidden = false
        } else {
            self.imgYTheight.constant = 0.0
            self.imgYTCheckHeight.constant = 0.0
        }
        if self.isFBOn == true {
            self.imgFB.isHidden = false
            self.imgFBCheckUncheck.isHidden = false
        } else {
            self.imgFBheight.constant = 0.0
            self.imgFBCheckHeight.constant = 0.0
        }
    }
    
    /// Start Live Streaming
    func startLiveStreamingSettings()  {
        goCoder?.config.hostAddress = "18.220.124.147"//"52.37.2.203"
        goCoder?.config.portNumber = 1935
        goCoder?.config.applicationName = "live"//"itzlit-test"
        if let streamID = UserDefaultHelper.getPREF(AppUserDefaults.pref_liveStreaming_streamId) {
            goCoder?.config.streamName = streamID
        }
        goCoder?.config.username = "itzlit"//"itzlit-test"
        goCoder?.config.password = "aNs-EDp-bEN-2wA"//"itzlit"
        
        if let configError = goCoder?.config.validateForBroadcast() {
            Helper.showAlertDialog(APP_NAME + "\n Incomplete Streaming Settings", message: configError.localizedDescription, clickAction: {})
        }
        else {
            // Disable the U/I controls
            self.btnBroadCast.isEnabled    = true
            self.btnFlash.isEnabled        = true
            self.rightBarCameraButton.isEnabled = false
            let audioMuted = goCoder?.isAudioMuted ?? false
            if self.goCoder?.isAudioMuted != nil {
                if (!(self.goCoder?.isAudioMuted)!) {
                    self.goCoder?.isAudioMuted = audioMuted
                }
            }
            
            
            if goCoder?.status.state == .running && (self.goCoder?.isStreaming)! {
                goCoder?.endStreaming(self)
            }
            else {
                receivedGoCoderEventCodes.removeAll()
                if self.goCoder!.isStreaming  {
                    Helper.showAlertDialog(APP_NAME, message: (self.goCoder?.config.validateForBroadcast()?.localizedDescription)!, clickAction: {})
                } else {
                    if !self.goCoder!.isStreaming {
                        goCoder?.startStreaming(self)
                    }
                }
                //                let audioMuted = goCoder?.isAudioMuted ?? false
                //self.rightBarMicButton.setImage(audioMuted ? #imageLiteral(resourceName: "mic_off_button") : #imageLiteral(resourceName: "mic_on_button"), for: .normal, barMetrics: .default)
            }
        }
    }
    
    /// Setup UI
    func configureUI() {
        UIApplication.shared.isIdleTimerDisabled = true
        self.title = ViewControllerTitle.live.rawValue
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton
        
        //        rightBarMicButton = UIBarButtonItem(image: UIImage(named: "mic_on_button"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(rightBarMicButton(_:)))
        
        rightBarCameraButton = UIBarButtonItem(image: UIImage(named: "img_camera-flip"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(rightBarCameraButton(_:)))
        self.navigationItem.rightBarButtonItem = rightBarCameraButton
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
        self.lblCaption.sizeToFit()
        self.lblCaption.text = strCaption
        self.lblGoliveCaption.text = "Start live video"
    }
    
    /// Left UIBarButton selector method
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        if self.goCoder != nil && self.goCoder?.status.state != .idle && goCoder?.status.state == .running {
            
            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: "Are you sure to end your live streaming?", button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "I'm done!", onButton1Click: nil, onButton2Click: {
                if self.timer != nil{
                    self.timer?.invalidate()
                    self.timer = nil
                }
                self.goCoder?.cameraPreview?.stop()
                if self.goCoder != nil && self.goCoder?.status.state != .idle && self.goCoder?.status.state == .running {
                    self.goCoder?.endStreaming(self)
                }
                self.goCoder?.unregisterAudioSink(self as WZAudioSink)
                self.goCoder?.unregisterVideoSink(self as WZVideoSink)
                self.goCoder = nil
            })
        } else {
            if self.timer != nil{
                self.timer?.invalidate()
                self.timer = nil
            }
            self.goCoder?.cameraPreview?.stop()
            self.goCoder?.unregisterAudioSink(self as WZAudioSink)
            self.goCoder?.unregisterVideoSink(self as WZVideoSink)
            self.goCoder = nil
            _ = self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @objc func rightBarMicButton(_ sender:UIBarButtonItem) {
        var newMutedState = self.goCoder?.isAudioMuted ?? true
        newMutedState = !newMutedState
        goCoder?.isAudioMuted = newMutedState
        //self.rightBarMicButton.setBackgroundImage(newMutedState ? #imageLiteral(resourceName: "mic_off_button") : #imageLiteral(resourceName: "mic_on_button"), for: .normal, barMetrics: .default)
    }
    
    /// Right bar camera flip button
    @objc func rightBarCameraButton(_ sender: UIBarButtonItem) {
        if let otherCamera = goCoder?.cameraPreview?.otherCamera() {
            if !otherCamera.supportsWidth(goCoderConfig.videoWidth) {
                goCoderConfig.load(otherCamera.supportedPresetConfigs.last!.toPreset())
                goCoder?.config = goCoderConfig
            }
            
            goCoder?.cameraPreview?.switchCamera()
            if otherCamera.isFront() {
                if newTorchState == true {
                    newTorchState = true
                    goCoder?.cameraPreview?.camera?.isTorchOn = false
                    self.btnFlash.setImage(#imageLiteral(resourceName: "flashOutline"), for: .normal)
                  }
            }
            self.updateUIControls()
        }
    }
    
    /// Update Timer when go live
    @objc func updateTimer() {
        self.sec += 1
        self.title = ViewControllerTitle.live.rawValue + "  " + self.secondsToHoursMinutesSeconds(seconds: self.sec)
        
        if self.sec == 30 {
            self.WSGoliveSendPushNotification()
        }
    }
    
    /// Convert Seconds to Hours, Minutes and Seconds
    func secondsToHoursMinutesSeconds(seconds : Int) -> String  {
        return String(format:"%02i:%02i:%02i", Int(seconds) / 3600, Int(seconds) / 60 % 60, Int(seconds) % 60)
    }
    
    /// Continous check for YT Live Streaming status for YT.
    @objc func continuousCheckForLiveStreaming() {
        self.WSCheckPermissionForLiveStreaming(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!, id: UserDefaultHelper.getPREF(AppUserDefaults.pref_broadcast_id)!, callback: { (isSucess, response) in
            if isSucess{
                print("WSCheckPermissionForLiveStreaming: \n", response ?? "no response")
                if let jsonDict = response?.result.value as? [String:Any] {
                    if let arrItemsDict = jsonDict["items"] as? [[String:Any]] {
                        for item in arrItemsDict {
                            if let statusDict = item["status"] as? [String:Any] {
                                if let lifeCycleStatus = statusDict["lifeCycleStatus"] as? String {
                                    if lifeCycleStatus == "testing" {
                                        self.timer?.invalidate()
                                        self.timer = nil
                                        self.WSBrodcastTransition(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!, id: UserDefaultHelper.getPREF(AppUserDefaults.pref_broadcast_id)!, broadcastStatus: "live", callback: { (isSucess) in
                                            if isSucess {
                                                print("sucess live YT")
                                                if self.isYoutubeOn == true {
                                                    self.imgYT.isHidden = false
                                                    self.imgYTCheckUncheck.isHighlighted = true
                                                }
                                            }
                                        })
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
        })
    }
}

// MARK: - Action Methods
extension GoLiveVC {
    @IBAction func btnFlashTapped(_ sender: UIButton) {
        newTorchState = goCoder?.cameraPreview?.camera?.isTorchOn ?? true
        newTorchState = !newTorchState
        goCoder?.cameraPreview?.camera?.isTorchOn = newTorchState
        self.btnFlash.setImage(newTorchState ? #imageLiteral(resourceName: "flash") : #imageLiteral(resourceName: "flashOutline"), for: .normal)
    }
    
    @IBAction func btnBroadcastTapped(_ sender: UIButton) {
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            self.btnBroadCast.isEnabled = false
            if goCoder?.status.state == .running {
                if  self.sec > 4 {
                    self.WSStartAndStopPublishing(completionHandler: { (isSucess) in
                        if isSucess {
                            self.title = ViewControllerTitle.live.rawValue + ": " + "Ended"
                            self.isStreamingWSCalled = true
                            
                            self.lblGoliveCaption.text = "Start live video"
                            self.btnBroadCast.setImage(#imageLiteral(resourceName: "img_go-live"), for: .normal)
                            self.updateUIControls()
                            
                            if self.goCoder != nil && self.goCoder?.status.state != .idle && self.goCoder?.status.state == .running {
                                self.goCoder?.endStreaming(self)
                            }
                        }
                    }, isStartPublishing: false)
                } else {
                    Helper.showAlertDialog(APP_NAME, message: ValidationMessage.liveVideoLength.rawValue, clickAction: {})
                }
            } else {
                if self.isStreamingWSCalled == true {
                    if self.isYoutubeOn == true {
                        self.WSCreateStreamOfYouTube(token: UserDefaultHelper.getPREF(AppUserDefaults.pref_google_accessToken)!, callback: { (isSucess) in
                            if isSucess {
                                self.WSGetStreamID { (isSucess) in
                                    if isSucess {
                                        self.startLiveStreamingSettings()
                                    }
                                }
                            }
                        })
                    } else {
                        self.WSGetStreamID { (isSucess) in
                            if isSucess {
                                self.startLiveStreamingSettings()
                            }
                        }
                    }
                }
            }
        } else {
            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyLoginMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Login", onButton1Click: {
            }, onButton2Click: {
                Helper.navigateToLogin(navigation: self.navigationController!)
            })
        }
    }
}

// MARK: - Web service methods
extension GoLiveVC {
    /// WS to get streaming id for Wowza GoCoder streamName.
    func WSGetStreamID(completionHandler: @escaping (Bool) -> ()) {
        var parameter:[String:Any] = [:]
        
        parameter  = [WebserviceRequestParmeterKey.streamToYt : self.isYoutubeOn,
                      WebserviceRequestParmeterKey.streamToItzlit:self.isItzlitOn,
                      WebserviceRequestParmeterKey.streamToFb:self.isFBOn,
                      WebserviceRequestParmeterKey.caption:self.strCaption]
        
        if self.isFBOn == true {
            parameter = parameter.merging([WebserviceRequestParmeterKey.fb: [WebserviceRequestParmeterKey.streamUrl : UserDefaultHelper.getPREF(AppUserDefaults.pref_stream_url)!]], uniquingKeysWith: { (_, last) in last })
        }
        if self.isYoutubeOn == true {
            parameter = parameter.merging([WebserviceRequestParmeterKey.yt: [WebserviceRequestParmeterKey.ingestionUrl : self.ingestionAddress,
                        WebserviceRequestParmeterKey.streamName:self.streamName]], uniquingKeysWith: { (_, last) in last })
        }
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.getStreamId, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    if let feedID = json.dictionaryObject!["feedId"] as? String {
                        UserDefaultHelper.setPREF(feedID, key: AppUserDefaults.pref_liveStreaming_feedId)
                    }
                    if let streamId = json.dictionaryObject!["streamId"] as? String {
                        UserDefaultHelper.setPREF(streamId, key: AppUserDefaults.pref_liveStreaming_streamId)
                    }
                    self.title = ViewControllerTitle.live.rawValue + ": " + "Starting..."
                    self.isStreamingWSCalled = false
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
                Helper.hideProgressBar()
            }
        }, onError: { (error, response) in
            completionHandler(false)
            print(error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
    
    /// WS called when streaming start and end publishing streaming
    func WSStartAndStopPublishing(completionHandler: @escaping (Bool) -> (), isStartPublishing: Bool) {
        
        let strUrl = isStartPublishing ? WebserverPath.goLiveStartPublishing : WebserverPath.goLiveStopPublishing
        
        let parameter:[String: Any] = [WebserviceRequestParmeterKey.feedId : UserDefaultHelper.getPREF(AppUserDefaults.pref_liveStreaming_feedId)!]
        if isStartPublishing == false {
            self.title = ViewControllerTitle.live.rawValue + ": " + "Ending..."
        }
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithHeader(urlPath: strUrl, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as! HTTPURLResponse).statusCode == 200 {
                    print(json.dictionaryObject ?? "")
                    completionHandler(true)
                }
            } else {
                completionHandler(false)
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            completionHandler(false)
            print(error?.localizedDescription ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {
                    if self.isStreamingWSCalled == false {
                        self.isStreamingWSCalled = true
                    }
                })
            }
        }
    }
    
    /// Webservice calls to send PN to followee users.
    func WSGoliveSendPushNotification() {
        let parameter:[String:Any] = [WebserviceRequestParmeterKey.feedId:UserDefaultHelper.getPREF(AppUserDefaults.pref_liveStreaming_feedId)!]
        ApiManager.Instance.httpPostRequestWithHeader(urlPath: WebserverPath.goLiveSendPN, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    print(json)
                } else {
                    print("error live PN:- ", error?.localizedDescription ?? "error")
                }
            } else {
                print("error live PN:- ", error?.localizedDescription ?? "error")
            }
        }) { (error, response) in
            print("error live PN:- ", error?.localizedDescription ?? "error")
        }
    }
}

// MARK: - Youtube GoLive API Call
extension GoLiveVC {
    
    /// Creating youtube live streaming URL
    func WSCreateStreamOfYouTube(token: String, callback: @escaping (Bool) -> Void){
        // Reference URL:- https://developers.google.com/youtube/v3/live/docs/liveStreams/insert?authuser=2&apix=true
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json", "Content-Type":"application/json"]
        /*
         Parameter Format:
         '{"cdn":{"format":"1080p","ingestionType":"dash"},"snippet":{"title":"demo"}
         */
        let params:[String:Any] = ["snippet":["title": self.strCaption == "" ? "Live via ITZLIT" : self.strCaption], "cdn":["format":"1080p", "ingestionType":"rtmp"]]
        var originalURL = "https://www.googleapis.com/youtube/v3/liveStreams?part=id, snippet, cdn, contentDetails, status"
        
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        Helper.showProgressBar()
        Alamofire.request(originalURL, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    if let jsonDict = response.result.value as? [String:Any] {
                        if let id = jsonDict["id"] as? String {
                            UserDefaultHelper.setPREF(id, key: "pref_CreateStream_id")
                        }
                        
                        if let cdnDict = jsonDict["cdn"] as? [String:Any] {
                            if let ingestionInfoDict = cdnDict["ingestionInfo"] as? [String:Any] {
                                self.ingestionAddress = ingestionInfoDict["ingestionAddress"] as! String
                                self.streamName = ingestionInfoDict["streamName"] as! String
                            }
                        }
                    }
                    callback(true)
                } else {
                    callback(false)
                }
                Helper.hideProgressBar()
                return
            case .failure(let failureErr):
                callback(false)
                print(failureErr.localizedDescription)
                Helper.hideProgressBar()
                return
            }
        }
    }
    
    /// WS to Create Broadcast for youtube to get broadcast id
    func WSCreateBroadcastForYouTube(token: String, callback: @escaping (Bool) -> Void) {

        let dateFormate = DateFormatter()
        dateFormate.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
        let strBroadcastDate = dateFormate.string(from: Date())
        print("Broadcast date -->>",strBroadcastDate)
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json", "Content-Type":"application/json"]
        
        let params:[String:Any] = ["snippet":["scheduledStartTime":strBroadcastDate,"title":self.strCaption == "" ? "Live via ITZLIT" : self.strCaption ], "status":["privacyStatus": "public"]]
        var originalURL = "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id, snippet, contentDetails, status"
        
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        
        Helper.showProgressBar()
        Alamofire.request(originalURL, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    if let jsonDict = response.result.value as? [String:Any] {
                        if let id = jsonDict["id"] as? String {
                            UserDefaultHelper.setPREF(id, key: AppUserDefaults.pref_broadcast_id)
                        }
                    }
                    callback(true)
                } else {
                    callback(false)
                }
                Helper.hideProgressBar()
                return
            case .failure(let failureErr):
                callback(false)
                print(failureErr.localizedDescription)
                Helper.hideProgressBar()
                return
            }
        }
    }
    
    /// WS to bind broadcast id and stream id to request to go live with youtube
    func WSBindBroadcastForYouTube(token: String, id: String, streamId: String, callback: @escaping (Bool) -> Void) {
        
        // https://www.googleapis.com/youtube/v3/liveBroadcasts/bind?id=OCZRfIz7-kY&part=id%2Csnippet%2CcontentDetails%2Cstatus
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json", "Content-Type":"application/json"]
        
        var originalURL = "https://www.googleapis.com/youtube/v3/liveBroadcasts/bind?id=\(id)&part=id, snippet, contentDetails, status&streamId=\(streamId)"
        
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        
        Helper.showProgressBar()
        Alamofire.request(originalURL, method: .post, parameters: [:], encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    callback(true)
                } else {
                    callback(false)
                }
                Helper.hideProgressBar()
                return
            case .failure(let failureErr):
                callback(false)
                print(failureErr.localizedDescription)
                Helper.hideProgressBar()
                return
            }
        }
    }
    
    /// WS to go live in youtube
    func WSBrodcastTransition(token: String, id: String, broadcastStatus: String, callback: @escaping (Bool) -> Void) {
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json", "Content-Type":"application/json"]
        /*
         'https://www.googleapis.com/youtube/v3/liveBroadcasts/transition?broadcastStatus=testing&id=3sZ55MhZj_Q&part=id%2C%20snippet%2C%20contentDetails%2C%20status' \
         
         https://www.googleapis.com/youtube/v3/liveBroadcasts/transition?broadcastStatus=live&id=Jy33MduRWwo&part=id%2C%20status
         */
        
        var originalURL = "https://www.googleapis.com/youtube/v3/liveBroadcasts/transition?broadcastStatus=\(broadcastStatus)&id=\(id)&part=id, snippet, contentDetails, status"
        
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        
        Helper.showProgressBar()
        Alamofire.request(originalURL, method: .post, parameters: [:], encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    callback(true)
                } else {
                    callback(false)
                }
                Helper.hideProgressBar()
                return
            case .failure(let failureErr):
                callback(false)
                print(failureErr.localizedDescription)
                Helper.hideProgressBar()
                return
            }
        }
    }
    
    /// WS to check permission that live streaming is enabled or not
    func WSCheckPermissionForLiveStreaming(token: String, id: String, callback: @escaping (Bool, DataResponse<Any>?) -> Void) {
        // https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id%2Cstatus&id=Jy33MduRWwo&maxResults=1
        let headers = ["Authorization": "Bearer \(token)", "Accept": "application/json"]
        var originalURL = "https://www.googleapis.com/youtube/v3/liveBroadcasts?part=id,status&id=\(id)"
        if let encodedURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            originalURL = encodedURL
        }
        Helper.showProgressBar()
        Alamofire.request(originalURL, method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            print(response)
            switch response.result {
            case .success(_):
                if response.response?.statusCode == 200 {
                    callback(true, response)
                } else {
                    callback(false, response)
                }
                Helper.hideProgressBar()
                return
            case .failure(let failureErr):
                callback(false, nil)
                print(failureErr.localizedDescription)
                Helper.hideProgressBar()
                return
            }
        }
    }
}

/// MARK:- ILSocketManagerDelegate Method
extension GoLiveVC: ILSocketManagerDelegate{
    func updateMyLiveViewerCount(feedID: String, liveFeedCount: String) {
        
    }
    
    func updateViewerUpdate(liveFeedCount: String) {
        self.btnViewer.setTitle("   \(liveFeedCount)", for: .normal)
    }
}
