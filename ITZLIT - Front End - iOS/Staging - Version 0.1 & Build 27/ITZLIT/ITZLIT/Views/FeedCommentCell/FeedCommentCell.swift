//
//  FeedCommentCell.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 01/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

class FeedCommentCell: UITableViewCell {

    @IBOutlet weak var commenterImageView: UIImageView!
    @IBOutlet weak var commenterName: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.commenterImageView.layer.cornerRadius = 3
            self.commenterImageView.clipsToBounds = true
        }
        
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
