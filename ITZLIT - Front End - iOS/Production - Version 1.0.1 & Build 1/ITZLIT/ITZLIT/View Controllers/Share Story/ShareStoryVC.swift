//
//  ShareStoryVC.swift
//  ITZLIT
//
//  Created by devang.bhatt on 02/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class ShareStoryVC: UIViewController {

    @IBOutlet var imgStory: UIImageView!
    @IBOutlet var btnDownload: UIButton!
    @IBOutlet var btnNext: UIButton!
    @IBOutlet var txtStoryCaption: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.btnDownload.layer.cornerRadius = self.btnDownload.frame.height / 2.0
        self.btnDownload.clipsToBounds = true
        
        self.btnNext.layer.cornerRadius = self.btnNext.frame.height / 2.0
        self.btnNext.clipsToBounds = true
        
        self.setupNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupNavigationBar() {
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
    }
    
    @objc func btnRightBarSettingTapped(_ sender: UIBarButtonItem) {
    }
    
    @objc func btnLeftBarCloseTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func btnDownloadTapped(_ sender: UIButton) {
    }

    @IBAction func btnSendToStoryTapped(_ sender: Any) {
        let sendToVC = self.storyboard?.instantiateViewController(withIdentifier: StoryboardIdentefier.sendTo.rawValue) as! SendToViewController
        self.navigationController?.pushViewController(sendToVC, animated: true)
    }
    

}
