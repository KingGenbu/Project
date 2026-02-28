//
//  FeedCell.swift
//  ITZLIT
//  Created by devang.bhatt on 01/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
import UIKit
class FeedCellOld: UITableViewCell {
    var feed : ItFeedList!
    @IBOutlet weak var btnGoLive: UIButton!
    @IBOutlet weak var viewForLive: UIView!
    @IBOutlet weak var hightForLive: NSLayoutConstraint!
    @IBOutlet weak var feedImageHight: NSLayoutConstraint!
    @IBOutlet weak var litHight: NSLayoutConstraint!
    @IBOutlet weak var litMeter: Meter!
    @IBOutlet weak var imgFeed: UIImageView!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnCmt: UIButton!
    @IBOutlet weak var btnLits: UIButton!
    @IBOutlet weak var lblLits: UILabel!
    @IBOutlet weak var lblFeedOwnername: UILabel!
    @IBOutlet weak var lblcmt: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
 
    override func prepareForReuse() {
        self.litMeter.lits = 0.0
    }
   
    func updateUI()  {
        if self.feed != nil{
            if self.feed.followingsFeeds[0].feedType == "StoryImage" || self.feed.followingsFeeds[0].feedType == "StoryVideo"{
                self.hightForLive.constant = 0
            }else {
                self.hightForLive.constant = 0.788 * self.viewForLive.frame.size.width
            }
        }
    }
    
    
    
    func setFeedFor(feed:ItFeedList)  {
        
        self.feed = feed
        
        let dictProfile = UserDefaultHelper.getDicPREF(AppUserDefaults.pref_dictProfile)
        let profileData = Profile(dictionary: dictProfile)
        if profileData._id == feed.followeeId {
            self.btnGoLive.isHidden = true
        } else {
            self.btnGoLive.isHidden = false
        }
    
        
        
        
        DispatchQueue.main.async {
            self.imgProfile.layer.cornerRadius = self.imgProfile.frame.height / 2.0
            self.imgProfile.layer.masksToBounds = true
        }
        self.lblFeedOwnername.text = feed.fullName
        if feed.profilePic.count > 0 {
            self.imgProfile.sd_setShowActivityIndicatorView(true)
            self.imgProfile.sd_setIndicatorStyle(.gray)
            self.imgProfile.sd_setImage(with: URL(string: feed.profilePic), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        }else {
            self.imgProfile.image = #imageLiteral(resourceName: "img_profile")
        }
        if feed.followingsFeeds[0].feedType == "StoryImage" || feed.followingsFeeds[0].feedType == "StoryVideo"{
            setRediusWith(color: UIColor.darkGray)
            self.btnGoLive.setTitle("Go Live!", for: .normal)
            self.hightForLive.constant = 0
            self.viewForLive.isHidden = true
            if feed.isItzlit == true {
                setRediusWith(color: UIColor.clear)
                self.btnGoLive.setTitle("", for: .normal)
                self.btnGoLive.setImage(UIImage(named: "itzlit-title"), for: .normal)
            }else {
                setRediusWith(color: UIColor.darkGray)
                self.btnGoLive.setTitle("Go Live!", for: .normal)
                self.btnGoLive.setImage(nil, for: .normal)
            }
        } else {
            setRediusWith(color: UIColor.red)
            self.btnGoLive.setTitle(feed.followingsFeeds[0].feedType == "LiveStreamVideo" ? "Was Live!" : "Now Live!", for: .normal)
            
            //            DispatchQueue.main.async {
            self.hightForLive.constant = 0.788 * self.viewForLive.frame.size.width
            //            }
            self.viewForLive.isHidden = false
            self.imgFeed.sd_setShowActivityIndicatorView(true)
            self.imgFeed.sd_setIndicatorStyle(.gray)
            var imgThumb300 : String = ""
            for path in feed.followingsFeeds[0].thumbs {
                if path.size == ThumbSize.thumb_300x300.rawValue {
                    imgThumb300 = path.path
                }
            }
            self.btnGoLive.setImage(nil, for: .normal)
            if feed.followingsFeeds[0].feedType == "LiveStreamVideo" {
                self.imgFeed.sd_setImage(with: URL(string: imgThumb300), completed: nil)
            } else {
                self.imgFeed.sd_setImage(with: URL(string: "http://18.220.124.147:8086/thumbnail?application=live&streamname=\(feed.followingsFeeds[0].streamId)&size=300x300&fitmode=crop"), completed: nil)
            }
            DispatchQueue.main.async {
            self.litMeter.lits = CGFloat(feed.followingsFeeds[0].itzlitCount)
            }
            self.lblLits.text = "\(feed.followingsFeeds[0].itzlitCount) Lits"
            self.lblcmt.text = "\(feed.followingsFeeds[0].comments) Comments"
        }
        
    }
    
    func setRediusWith(color:UIColor)  {
        self.btnGoLive.layer.borderWidth = 0.5
        DispatchQueue.main.async {
            self.btnGoLive.layer.cornerRadius = (color == UIColor.clear ? 0 : self.btnGoLive.frame.size.height/2)
        }
        
        self.btnGoLive.layer.borderColor = color.cgColor
        self.btnGoLive.clipsToBounds = true
        self.btnGoLive.setTitleColor(color, for: .normal)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
