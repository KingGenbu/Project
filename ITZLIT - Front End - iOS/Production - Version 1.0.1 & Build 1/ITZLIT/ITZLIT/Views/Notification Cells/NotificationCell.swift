//
//  NotificationCell.swift
//  ITZLIT
//
//  Created by devang.bhatt on 27/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {

    @IBOutlet var imgProfilePic: UIImageView!
    @IBOutlet var lblNotificationData: UILabel!
    @IBOutlet var lblNotificationTime: UILabel!
    @IBOutlet weak var imgReplay: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.async {
             self.imgReplay.layer.cornerRadius =  self.imgReplay.frame.height / 2.0
             self.imgReplay.layer.masksToBounds = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
