//
//  TermsAndPrivacyViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 28/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import WebKit

class TermsAndPrivacyViewController: UIViewController {

    var webView: WKWebView!

    var isFromPrivacyPolicy: Bool = false

    override func loadView() {
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view = UIView()
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureUI()

        let urlString = isFromPrivacyPolicy
            ? ApiManager.baseUrl + WebserverPath.privacyPolicy
            : ApiManager.baseUrl + WebserverPath.termsOfUse

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }

    func configureUI() {
        self.title = isFromPrivacyPolicy ? ViewControllerTitle.privacyPolicy.rawValue : ViewControllerTitle.termOfUse.rawValue
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFontConst.POPPINS_MEDIUM!, NSAttributedString.Key.foregroundColor: UIColor.white]

        let leftBarSearchButton = UIBarButtonItem(image: UIImage(named: "img_back"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(leftBarBackButton(_:)))
        self.navigationItem.leftBarButtonItem = leftBarSearchButton

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain")!)

        webView.layer.borderWidth = 1.0
        webView.layer.borderColor = UIColor.lightGray.cgColor
    }

    @objc func leftBarBackButton(_ sender:UIBarButtonItem)  {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
