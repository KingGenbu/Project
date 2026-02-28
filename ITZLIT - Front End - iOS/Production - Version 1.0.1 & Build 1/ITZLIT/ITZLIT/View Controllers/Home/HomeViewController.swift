//
//  HomeViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 25/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet var btnLive: UIButton!
    @IBOutlet var btnStroy: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.btnLive.layer.cornerRadius = self.btnLive.frame.height / 10
        self.btnStroy.layer.cornerRadius = self.btnStroy.frame.height / 10
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// Function used to navigate to feed view controller
    func navigateToFeedViewController()  {
        var isFeedVC:Bool = false
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
    }
    
    /// Action method for ITZLIT icon
    @IBAction func btnIzlitTapped(_ sender: UIButton) {
        
        if (UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil) && (UserDefaultHelper.getBoolPREF(AppUserDefaults.pref_user_verified) == true) {
            self.navigateToFeedViewController()
        } else {
            Helper.showAlertDialogWith2Button(onVC: self, title: APP_NAME, message: AppMessage.verifyLoginMessage.rawValue, button1Title: "Cancel", button1ActionStyle: .cancel, button2Title: "Login", onButton1Click: {
            }, onButton2Click: {
                Helper.navigateToLogin(navigation: self.navigationController!)
            })
        }
    }
    
    
    /// Action method live button
    @IBAction func btnLiveTapped(_ sender: UIButton) {
        let liveStreamingConfig = Helper.settingFeedStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.liveStreamingConfigurationVC.rawValue) as! LiveStreamingConfigurationVC
        Helper.Push_Pop_to_ViewController(destinationVC: liveStreamingConfig, isAnimated: true, navigationController: self.navigationController!)
    }
    
    /// Action method for Story Switch
    @IBAction func btnStoryTapped(_ sender: UIButton) {
        let storyInterfaceVC = Helper.storyShareStoryBoard.instantiateViewController(withIdentifier: StoryboardIdentefier.story.rawValue) as! StoryCapture
        Helper.Push_Pop_to_ViewController(destinationVC: storyInterfaceVC, isAnimated: true, navigationController: self.navigationController!)
    }
    
    /// Setup Navigationbar
    func setupNavigationBar() {
        
        let rightBarSettingButton = UIBarButtonItem(image: UIImage(named: "img_setting"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(rightBarSettingButton(_:)))
        self.navigationItem.rightBarButtonItem = rightBarSettingButton
        
        
        let leftBarNotificationButton = UIBarButtonItem(image: UIImage(named: "img_notification"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarNotificationButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarNotificationButton
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_splash")!)
        
        guard let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else { return }
        statusBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_splash")!)
        statusBar.tintColor = .white
    }
    
    /// Navigaitn bar setting button icon action method
    @objc func rightBarSettingButton(_ sender:UIBarButtonItem)  {
        self.present(Helper.getActionSheetForMenu(navigation: self.navigationController!), animated: true, completion: nil)
    }
    
    /// Navigation bar notification icon action method
    @objc func leftBarNotificationButton(_ sender:UIBarButtonItem)  {
        
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
}
