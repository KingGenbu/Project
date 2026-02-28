//
//  ContactCell.swift
//  ITZLIT
//
//  Created by devang.bhatt on 27/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {

    @IBOutlet var imgContactProfilePicture: UIImageView!
    
    @IBOutlet var lblContactName: UILabel!
    @IBOutlet var lblContactNumber: UILabel!
    
    @IBOutlet var btnContactInvite: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.imgContactProfilePicture.layer.cornerRadius = 2.0 //self.imgContactProfilePicture.frame.height / 2.0
//            self.imgContactProfilePicture.clipsToBounds = true
            self.btnContactInvite.layer.cornerRadius = self.btnContactInvite.frame.height / 2.0
            self.btnContactInvite.layer.masksToBounds = true
            self.btnContactInvite.layer.borderColor = UIColor.gray.cgColor
            
        }
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
