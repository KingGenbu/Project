//
//  ViewLiveVideoViewController.swift
//  ITZLIT
//
//  Created by Devang Bhatt on 15/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewLiveVideoViewController: UIViewController {
    
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnViews: UIButton!
    
    var videoURL: URL?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var playerController : AVPlayerViewController?
    var playerItem : AVPlayerItem?
    var arrFeedDetail : [FeedDetail]!
    var isFromNotificationList:Bool = false
    var mediaPathURL:String = ""
    var strFullName:String = ""
    var strFeedId:String = ""
    var strCaption:String = ""
    var strProfilePic:String = ""
    var iViewers:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupFeedData()
        self.configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
        if player != nil {
            player?.pause()
        }
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    func initSoket(feedid:String)  {
        let params = [WebserviceRequestParmeterKey.feedId : feedid]
        ILSocketManager.shared.establishConnection(withParams: params)
        ILSocketManager.shared.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureUI() {
        navigationController?.navigationBar.isHidden = true
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        
        statusBar.backgroundColor = .clear
        statusBar.tintColor = .white
        self.imgProfile.layer.cornerRadius = self.imgProfile.frame.height / 2.0
        self.imgProfile.clipsToBounds = true
    }
    
    @IBAction func btnCloseTapped(_ sender: UIButton) {
        self.dismiss(animated: false) {
             self.deinitItsoket()
        }
    }
    
    func deinitItsoket()  {
         ILSocketManager.shared.emitEvent(.onFeedUnjoin, items: [:])
    }
    
    func setupAVPlayer() {
        guard let _ = videoURL else {return}
        
        playerItem = AVPlayerItem(url: videoURL!)
         player = AVPlayer(playerItem: playerItem)//AVPlayer(url: videoURL)
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerFailedToPlayToEndTime), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.player!.currentItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemNewErrorLogEntry), name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: self.player!.currentItem)
        
        view.sendSubview(toBack: playerController!.view)
        
        self.player?.play()
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: kCMTimeZero)
            self.player!.play()
        }
    }
    
    @objc fileprivate func playerFailedToPlayToEndTime(_ notification: Notification) {
        print( notification.description)
    }
    
    @objc fileprivate func playerItemNewErrorLogEntry(_ notification: Notification) {
        print( notification.description)
        if player != nil {
            player?.play()
        }
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
    
    func setupFeedData() {
        if self.isFromNotificationList {
            self.videoURL = URL(string: self.mediaPathURL)
            self.lblName.text = self.strFullName
            self.lblDescription.text = self.strCaption
            self.imgProfile.sd_setImage(with: URL(string: self.strProfilePic), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
            self.btnViews.setTitle("\( self.iViewers)", for: .normal)
            
            initSoket(feedid: strFeedId)
        } else {
            for feedItem in self.arrFeedDetail {
//                self.btnViews.setTitle(" \(feedItem.viewers!)", for: .normal)
                self.videoURL = URL(string: (feedItem.mediaDict?.path)!)
                self.lblName.text = feedItem.userFullName
                self.lblDescription.text = feedItem.caption
                self.imgProfile.sd_setImage(with: URL(string: feedItem.userProfilePic ?? ""), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
                if feedItem.feedType == "LiveStream" {
                    initSoket(feedid: feedItem._id!)
                }
                
            }
        }
        self.setupAVPlayer()
    }
}

extension ViewLiveVideoViewController:ILSocketManagerDelegate{
    func updateMyLiveViewerCount(feedID: String, liveFeedCount: String) {
    }
    
    func updateViewerUpdate(liveFeedCount: String) {
          self.btnViews.setTitle("   \(liveFeedCount)", for: .normal)
    }
}


