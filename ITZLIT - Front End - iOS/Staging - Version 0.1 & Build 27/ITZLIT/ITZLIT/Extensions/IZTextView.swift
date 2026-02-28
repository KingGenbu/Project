//
//  IZTextView.swift
//  ITZLIT
//
//  Created by Devang Bhatt on 06/03/18.
//  Copyright © 2018 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class IZTextView: UITextView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
    
}
