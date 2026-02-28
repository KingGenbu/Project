//
//  ResendOTPVC.swift
//  ITZLIT
//
//  Created by devang.bhatt on 09/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class ResendOTPVC: UIViewController {

    @IBOutlet var btnResendOTP: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.configureUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnResendOTPTapped(_ sender: UIButton) {
        self.WSResendOTPCalled()
    }
    
    func configureUI() {
        self.navigationController?.navigationBar.isHidden = false
        self.btnResendOTP.layer.cornerRadius = self.btnResendOTP.frame.height / 10.0
        let leftBarBackButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(leftBarButtonTapped(_:)))
        leftBarBackButton.tintColor = .black
        self.navigationItem.leftBarButtonItem = leftBarBackButton
        DispatchQueue.main.async {
            self.btnResendOTP.addGradientToBackground()
        }
    }
    
    @objc func leftBarButtonTapped(_ sender: UIBarButtonItem?) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func WSResendOTPCalled() {
        Helper.showProgressBar()
        ApiManager.Instance.sendHttpGetWithHeader(path: WebserverPath.resendOTP, onComplete: { (json, error, response) in
            if error == nil {
                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    if let msg = json.dictionaryObject!["msg"] as? String {
                        Helper.showAlertDialog(APP_NAME, message: msg, clickAction: {
                            self.leftBarButtonTapped(nil)
                        })
                    }
                }
            } else {
                print(error?.localizedDescription ?? "error on calling Resend otp WS")
            }
            Helper.hideProgressBar()
        }) { (error, response) in
            print(error?.localizedDescription ?? "error from alamofire")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        }
    }
}
