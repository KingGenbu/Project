//
//  TermsAndPrivacyViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 28/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class TermsAndPrivacyViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
        
    var isFromPrivacyPolicy: Bool = false
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureUI()
        
        isFromPrivacyPolicy == true ? self.webView.loadRequest(URLRequest(url: URL(string: ApiManager.baseUrl + WebserverPath.privacyPolicy)!)) : self.webView.loadRequest(URLRequest(url: URL(string: ApiManager.baseUrl + WebserverPath.termsOfUse)!))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureUI() {
        self.title = isFromPrivacyPolicy == true ? ViewControllerTitle.privacyPolicy.rawValue : ViewControllerTitle.termOfUse.rawValue
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
        
    //    self.webView.dropShadow(scale: true)
        self.webView.layer.borderWidth = 1.0
        self.webView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
