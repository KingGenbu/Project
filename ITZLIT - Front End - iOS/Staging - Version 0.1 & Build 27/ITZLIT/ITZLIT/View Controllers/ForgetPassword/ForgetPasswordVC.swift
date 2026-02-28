//
//  ForgetPasswordVC.swift
//  ITZLIT
//
//  Created by devang.bhatt on 10/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class ForgetPasswordVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var btnForgetPassword: UIButton!
    @IBOutlet var vwForgetPassword: ILCustomViews!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureUI()
        DispatchQueue.main.async {
            self.btnForgetPassword.addGradientToBackground()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnForgetPasswordTapped(_ sender: UIButton?) {
        if self.isValid() {
            self.WSForgetPasswordCalled()
        }
    }
    func configureUI() {
         self.vwForgetPassword.txtName.textColor = .white
        self.vwForgetPassword.txtName.font = UIFontConst.ROBOTO_LIGHT
         let backBarButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: .plain, target: self, action: #selector(self.backBarButtonTapped(_:)))
        self.navigationItem.leftBarButtonItem = backBarButton
    }
    
    @objc func backBarButtonTapped(_ sender: UIBarButtonItem)  {
        self.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.btnForgetPasswordTapped(nil)
        return true
    }
    
    func isValid() -> Bool{
        if (vwForgetPassword.txtName.text?.isEmpty)! {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.emptyEmailAdress.rawValue, clickAction: {
                self.vwForgetPassword.txtName.becomeFirstResponder()
            })
            return false
        } else if (!Helper.isValidEmail(vwForgetPassword.txtName.text!)) {
            Helper.showAlertDialog(APP_NAME, message: ValidationMessage.invalidEmailAddress.rawValue, clickAction: {
                self.vwForgetPassword.txtName.becomeFirstResponder()
            })
            return false
        }
        return true
    }
    
    func WSForgetPasswordCalled() {
        let parameter: [String: Any] = [WebserviceRequestParmeterKey.email : self.vwForgetPassword.txtName.text!]
        Helper.showProgressBar()
        ApiManager.Instance.httpPostRequestWithoutHeader(urlPath: WebserverPath.forgetPassword, parameter: parameter, onCompletion: { (json, error, response) in
            if error == nil {
                if let errorMessage = json.dictionaryObject!["error"] as? String {
                    Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                    return
                }
                if let message = json.dictionaryObject!["msg"] as? String {
                    Helper.showAlertDialog(APP_NAME, message: message, clickAction: {})
                }
            }
            Helper.hideProgressBar()
        }, onError: { (error, response) in
            print(error ?? "error")
            Helper.hideProgressBar()
            if error?.code == Helper.networkNotAvailableCode {
                Helper.showAlertDialog(APP_NAME, message: AppMessage.internetConnectionOffline.rawValue, clickAction: {})
            }
        })
    }
}
