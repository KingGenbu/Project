//
//  BaseViewController.swift
//  ITZLIT
//
//  Created by devang.bhatt on 27/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {

    @IBOutlet var vwBase: UIView!
    @IBOutlet var txtTitle: UILabel!
    @IBOutlet var btnBack: UIButton! // Left Button
    @IBOutlet var btnSearch: UIButton! // Right Button
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Bundle.main.loadNibNamed("BaseViewController", owner: self, options: nil)
        vwBase.backgroundColor = .clear
        self.view.translatesAutoresizingMaskIntoConstraints = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupHeaderView(withTitle title:String = "", showBackButton showBack:Bool = true, showSearchButton showSearch:Bool = true ,viewCntrl:UIViewController) {
        
        if viewCntrl is NotificationViewController {
            self.btnBack.isHidden = showBack
            self.btnSearch.isHidden = showSearch
            self.txtTitle.text = title
            self.btnBack.addTarget(self, action: #selector(btnBackTapped(button:)), for: UIControlEvents.touchUpInside)
        }
//        if viewCntrl is ContactViewController {
//            self.btnBack.isHidden = showBack
//            self.btnSearch.isHidden = showSearch
//            self.txtTitle.text = title
//            self.btnBack.addTarget(self, action: #selector(btnBackTapped(button:)), for: UIControlEvents.touchUpInside)
//        }
        if viewCntrl is SendToViewController {
            self.btnBack.isHidden = showBack
            self.btnSearch.isHidden = showSearch
            self.txtTitle.text = title
            self.btnBack.addTarget(self, action: #selector(btnBackTapped(button:)), for: UIControlEvents.touchUpInside)
        }
    }
    
    @objc func btnBackTapped(button:UIButton)  {
    }
}
