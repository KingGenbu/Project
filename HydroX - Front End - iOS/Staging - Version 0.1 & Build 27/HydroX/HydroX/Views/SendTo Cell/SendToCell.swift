//
//  SendToCell.swift
//  HydroX
//
//  Created by devang.bhatt on 30/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class SendToCell: UITableViewCell {

    @IBOutlet var imgProfilePicture: UIImageView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var btnCheckUncheck: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
