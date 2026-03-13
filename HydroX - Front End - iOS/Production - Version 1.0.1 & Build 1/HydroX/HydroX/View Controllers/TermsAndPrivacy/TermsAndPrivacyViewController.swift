//
//  TermsAndPrivacyViewController.swift
//  HydroX
//
//  Created by devang.bhatt on 28/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import WebKit

class TermsAndPrivacyViewController: UIViewController {

    var webView: WKWebView!

    var isFromPrivacyPolicy: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.configureUI()

        let urlPath = isFromPrivacyPolicy
            ? ApiManager.baseUrl + WebserverPath.privacyPolicy
            : ApiManager.baseUrl + WebserverPath.termsOfUse
        if let url = URL(string: urlPath) {
            webView.load(URLRequest(url: url))
        }
    }

    func configureUI() {
        self.title = isFromPrivacyPolicy
            ? ViewControllerTitle.privacyPolicy.rawValue
            : ViewControllerTitle.termOfUse.rawValue

        navigationController?.navigationBar.titleTextAttributes = [
            .font: UIFontConst.POPPINS_MEDIUM ?? UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.white
        ]

        let leftBarSearchButton = UIBarButtonItem(
            image: UIImage(named: "img_back"),
            style: .plain,
            target: self,
            action: #selector(leftBarBackButton(_:))
        )
        self.navigationItem.leftBarButtonItem = leftBarSearchButton

        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.view.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = UIColor(patternImage: UIImage(named: "img_bg_plain") ?? UIImage())

        self.webView.layer.borderWidth = 1.0
        self.webView.layer.borderColor = UIColor.lightGray.cgColor
    }

    @objc func leftBarBackButton(_ sender: UIBarButtonItem) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
