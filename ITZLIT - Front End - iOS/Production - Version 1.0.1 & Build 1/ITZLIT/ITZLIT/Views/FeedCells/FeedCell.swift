//
//  FeedCell.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 02/01/18.
//  Copyright © 2018 Solution Analysts Pvt. Ltd. All rights reserved.



import UIKit
import SimpleImageViewer
protocol feedColectionActionProtocol {
    func collectionDidSelectiAt(masterIndex:Int,index:Int,feedForDisplay:ItFeedList)
    func collectionActionClicked(action:actionType?,masterIndex:Int,index:Int,feed:ItFeedList)
    func collectionWillDisplayCell(masterIndex:Int,index:Int, contentOffset:CGFloat)
    func collectionViewsStartListen(masterIndex:Int,feedId:String)
}

class FeedCell: UITableViewCell {
    
//    override func prepareForReuse() {
////        self.collectionLive.collectionViewLayout.invalidateLayout()
//    }
//    var itsMe : Bool = false {
//        didSet{
//          self.hightTop.constant = itsMe ? 0 : 0.19*self.collectionLive.frame.size.width
//        }
//    }
//    var masterIndexForFeed : Int = 0 {
//        didSet{
//            self.masterIndex = masterIndexForFeed
//        }
//
//    }
//    var feedToDisplay : ItFeedList = ItFeedList() {
//        didSet{
//            self.feedForDisplay = feedToDisplay
//            self.setOwnerFor(feed: feedToDisplay)
//            self.setGoLiveButton(feed: feedToDisplay)
//
//             self.hightCollection.constant = feedToDisplay.expanded == true ? self.collectionLive.frame.size.width*0.60: 0
//
//
//
//         //   self.collectionLive.reloadData()
//
//
//
//        }
//
//    }

    @IBOutlet weak var imgReplay: UIImageView!
    @IBOutlet weak var btnGoLive: UIButton!
    @IBOutlet weak var lblFeedOwnername: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var hightCollection: NSLayoutConstraint!
    @IBOutlet weak var collectionLive: UICollectionView!
    @IBOutlet weak var btnTogleLiveFeed: UIButton!
    @IBOutlet weak var hightTop: NSLayoutConstraint!

    var itsMe:Bool = false
    var collectionViewOffset: CGFloat {
        set { collectionLive.contentOffset.x = newValue }
        get { return collectionLive.contentOffset.x }
    }
    var feedForDisplay = ItFeedList()
    var masterIndex : Int!
    var collectionClickDelegate:feedColectionActionProtocol!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ILSocketManager.shared.delegate = self
    }
 
    override func prepareForReuse() {
        super.prepareForReuse()
        feedForDisplay = ItFeedList()
        masterIndex = nil
        collectionLive.reloadData()
        collectionLive.collectionViewLayout.invalidateLayout()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    //MARK:-SetFeed
    func setFeedFor(feed:ItFeedList,index:Int,itsMe:Bool) {
        self.masterIndex = index
        self.feedForDisplay = feed
        self.itsMe = itsMe
        self.setOwnerFor(feed: self.feedForDisplay)
        self.setGoLiveButton(feed: self.feedForDisplay)//
        
        hightCollection.constant = feed.expanded == true ? self.collectionLive.frame.size.width*0.60: 0
        hightTop.constant = itsMe ? 0 : 0.19*self.collectionLive.frame.size.width
        if feed.expanded {
            self.collectionLive.dataSource = self
            self.collectionLive.delegate = self
            self.collectionLive.reloadData()
            
        } else {
            self.collectionLive.dataSource = nil
            self.collectionLive.delegate = nil
        }
    }

    
    func setGoLiveButton(feed:ItFeedList) {
        if feed.liveFeeds.count == 0 {//Story
            btnGoLive.isHidden = false
            btnTogleLiveFeed.isHidden = true
            if feed.isItzlit == true {
                setRediusWith(color: UIColor.clear)
                self.btnGoLive.setTitle("", for: .normal)
                self.btnGoLive.setImage(UIImage(named: "img_itslit"), for: .normal)
            }else {
                setRediusWith(color: UIColor.darkGray)
                self.btnGoLive.setTitle("Go Live!", for: .normal)
                self.btnGoLive.setImage(nil, for: .normal)
            }
        }else {//Story+Stream
            btnGoLive.isHidden = true
            btnTogleLiveFeed.isHidden = false
        }
    }
    
    func setOwnerFor(feed:ItFeedList) {
        DispatchQueue.main.async {
            self.imgProfile.layer.cornerRadius = self.imgProfile.frame.height / 2.0
            self.imgProfile.layer.masksToBounds = true
        }
        self.lblFeedOwnername.text = feed.fullName
        
        var imgThumb300 : String = ""
        if feed.followingsFeeds.count > 0 {
            for path in feed.followingsFeeds[0].thumbs {
                if  path.size == ThumbSize.thumb_300x300.rawValue {
                    imgThumb300 = path.path
                }
            }
        } else {
            if feed.profilePic.count > 0 {
                imgThumb300 = feed.profilePic
            } else {
                self.imgProfile.image = #imageLiteral(resourceName: "img_profile")
            }
        }
        self.imgProfile.sd_setShowActivityIndicatorView(true)
        self.imgProfile.sd_setIndicatorStyle(.gray)
        self.imgProfile.sd_setImage(with: URL(string: imgThumb300), placeholderImage: #imageLiteral(resourceName: "img_profile"), completed: nil)
        
        if !self.itsMe {
            if self.feedForDisplay.followingsFeeds.count > 0 {
                var arrStoryIds : [String] = []
                for storyIndex in 0..<self.feedForDisplay.followingsFeeds.count {
                    let story = self.feedForDisplay.followingsFeeds[storyIndex]
                    arrStoryIds.append(story.feedId)
                }
                let isAllStoriesSeen = DBManager.shared.isContainsAllStories(arrStoryid: arrStoryIds) { (isSucess) in
                    if isSucess {
                        print("Seened all the stories of", self.feedForDisplay.fullName)
                    }
                }
                self.imgReplay.isHidden = isAllStoriesSeen == true ? false : true
            }
        }
    }
   
    //MARK:-Utility
    func setRediusWith(color:UIColor)  {
        self.btnGoLive.layer.borderWidth = 0.5
        DispatchQueue.main.async {
            self.btnGoLive.layer.cornerRadius = (color == UIColor.clear ? 0 : self.btnGoLive.frame.size.height/2)
        }
        
        self.btnGoLive.layer.borderColor = color.cgColor
        self.btnGoLive.clipsToBounds = true
        self.btnGoLive.setTitleColor(color, for: .normal)
    }
    func animate(explore:Bool)  {
        self.hightCollection.constant = explore ? self.collectionLive.frame.size.width*0.60 : 0
    }
    
    func setupCollectionViewAnimation(index:Int) {
        
    }
}

// MARK:- ILSocketManagerDelegate Method
extension FeedCell: ILSocketManagerDelegate {
    func updateMyLiveViewerCount(feedID: String, liveFeedCount: String) {
        if let storyIndex = feedForDisplay.liveFeeds.index(where: { $0.feedId == feedID }) {
            let story = feedForDisplay.liveFeeds[storyIndex]
            story.viewers = Int(liveFeedCount) ?? 0
            let feedCollectionViewCell = collectionLive.cellForItem(at: IndexPath(item: storyIndex, section: 0)) as? FeedCollectionViewCell
//            print("Collection Cell:: -> ",cell ?? "no cell")
            feedCollectionViewCell?.btnViewsOther.setTitle(" \(story.viewers)", for: .normal)
//            print("cell?.btnViewsOther:: ->  ",cell?.btnViewsOther.titleLabel?.text ?? "no text")
           // collectionLive.reloadItems(at: [IndexPath(item: storyIndex, section: 0)])
        }
    }
    
    func updateViewerUpdate(liveFeedCount: String) {
     
    }
}

// MARK:- UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout methods
extension FeedCell:UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //MARK:-Collection
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.feedForDisplay.liveFeeds.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let feedCell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier.feedCollection.rawValue, for: indexPath) as! FeedCollectionViewCell
        feedCell.btnViewsOther.setImage(UIImage(named: "img_view_feed_fee")?.withRenderingMode(.alwaysTemplate), for: .normal)
        feedCell.btnViewsOther.tintColor = .white
        feedCell.imgFeed.sd_setShowActivityIndicatorView(true)
        feedCell.imgFeed.sd_setIndicatorStyle(.gray)
        var imgThumb300 : String = ""
        
        for path in self.feedForDisplay.liveFeeds[indexPath.item].thumbs {
            if path.size == ThumbSize.thumb_300x300.rawValue {
                imgThumb300 = path.path
            }
        }
        
        if self.feedForDisplay.liveFeeds[indexPath.item].feedType == "LiveStreamVideo" {
            feedCell.imgFeed.sd_setImage(with: URL(string: imgThumb300), completed: nil)
            feedCell.btnShare.isHidden = false
            feedCell.lblStatus.text = " Was Live! "
        } else {
            feedCell.imgFeed.sd_setImage(with: URL(string: "http://18.220.124.147:8086/thumbnail?application=live&streamname=\(self.feedForDisplay.liveFeeds[indexPath.item].streamId)&size=300x300&fitmode=crop"), completed: nil)
            feedCell.btnShare.isHidden = true
            feedCell.lblStatus.text = " Live Now! "
        }
        
        DispatchQueue.main.async {
            feedCell.litMeter.lits = CGFloat(self.feedForDisplay.liveFeeds[indexPath.item].itzlitCount)
        }
        //        feedCell.lblLits.text = "\(self.feed.liveFeeds[indexPath.item].viewers) views"
        
        if self.feedForDisplay.liveFeeds[indexPath.item].comments > 0 {
             feedCell.lblcmt.text = "\(self.feedForDisplay.liveFeeds[indexPath.item].comments) Comments"
        } else {
            feedCell.lblcmt.text = ""
        }
        
        if self.itsMe {
            feedCell.btnViewsOther.isHidden = true
            if self.feedForDisplay.liveFeeds[indexPath.item].viewers > 0 {
                feedCell.btnViews.isHidden = false
                feedCell.btnViews.setTitle(" \(self.feedForDisplay.liveFeeds[indexPath.item].viewers) views", for: .normal)
//                if self.feedForDisplay.liveFeeds[indexPath.item].feedType == "LiveStreamVideo" {
//                    feedCell.btnViews.setTitle(" \(self.feedForDisplay.liveFeeds[indexPath.item].viewers) views", for: .normal)
//                }
            } else {
                feedCell.btnViews.isHidden = true
             }
        } else {
            feedCell.btnViews.isHidden = true
            if self.feedForDisplay.liveFeeds[indexPath.item].viewers > 0 {
                feedCell.btnViewsOther.isHidden = false
                feedCell.btnViewsOther.setTitle(" \(self.feedForDisplay.liveFeeds[indexPath.item].viewers)", for: .normal)
            } else {
                feedCell.btnViewsOther.isHidden = true
            }
        }
    
        feedCell.btnLits.tag = indexPath.row
        feedCell.btnLits.addTarget(self, action: #selector(self.btnLitAction(_:)), for: .touchUpInside)
        
        feedCell.btnCmt.tag = indexPath.row
        feedCell.btnCmt.addTarget(self, action: #selector(self.btnCommentAction(_:)), for: .touchUpInside)
        
        feedCell.btnShare.tag = indexPath.row
        feedCell.btnShare.addTarget(self, action: #selector(self.btnShareAction(_:)), for: .touchUpInside)
        
        feedCell.btnMore.tag = indexPath.row
        feedCell.btnMore.addTarget(self, action: #selector(self.btnMoreAction(_:)), for: .touchUpInside)
        
        feedCell.btnViews.tag = indexPath.row
        feedCell.btnViews.addTarget(self, action: #selector(self.btnMyLiveViewsAction(_:)), for: .touchUpInside)
        
        if self.feedForDisplay.liveFeeds.count > 1 && self.masterIndex == self.feedForDisplay.expandIndex && self.feedForDisplay.expanded && !feedForDisplay.isSwipeIndicatorDisplayed {
            if indexPath.item == 0 {
                feedCell.imgSwipe.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    let transformAnim  = CAKeyframeAnimation(keyPath:"transform")
                    transformAnim.values  = [NSValue(caTransform3D: CATransform3DMakeRotation(-0.04 , 0, 0, 1)),NSValue(caTransform3D: CATransform3DMakeRotation(0.15, 0.0, 0.0, 1.0))]
                    transformAnim.autoreverses = false
                    transformAnim.duration  = 0.5
                    transformAnim.repeatCount = 2
                    feedCell.imgSwipe.layer.add(transformAnim, forKey: "transform")
                    transformAnim.isRemovedOnCompletion = true
                    if transformAnim.isRemovedOnCompletion {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                            feedCell.imgSwipe.isHidden = true
                            self.feedForDisplay.isSwipeIndicatorDisplayed = true
                        }
                    }
                }
            }
        } else {
            feedCell.imgSwipe.isHidden = true
        }
        return feedCell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        if collectionClickDelegate != nil{
//            collectionClickDelegate.collectionWillDisplayCell(masterIndex: self.masterIndex, index: indexPath.item, contentOffset: collectionView.contentOffset.x)
//        }
    }
    
    
    @objc func btnLitAction(_ sender: UIButton) {
        if collectionClickDelegate != nil{
            collectionClickDelegate.collectionActionClicked(action: .like , masterIndex: self.masterIndex, index: sender.tag, feed: self.feedForDisplay)
        }
    }
    @objc func btnCommentAction(_ sender: UIButton) {
        if collectionClickDelegate != nil{
            collectionClickDelegate.collectionActionClicked(action: .comment , masterIndex: self.masterIndex, index: sender.tag, feed: self.feedForDisplay)
        }
    }
    @objc func btnShareAction(_ sender: UIButton) {
        if collectionClickDelegate != nil{
            collectionClickDelegate.collectionActionClicked(action: .share , masterIndex: self.masterIndex, index: sender.tag, feed: self.feedForDisplay)
        }
    }
    
    @objc func btnMoreAction(_ sender: UIButton) {
        if collectionClickDelegate != nil{
            collectionClickDelegate.collectionActionClicked(action: .more , masterIndex: self.masterIndex, index: sender.tag, feed: self.feedForDisplay)
        }
    }
    
    @objc func btnMyLiveViewsAction(_ sender: UIButton) {
        if collectionClickDelegate != nil {
            collectionClickDelegate.collectionActionClicked(action: .viewerList , masterIndex: self.masterIndex, index: sender.tag, feed: self.feedForDisplay)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionClickDelegate != nil{
            collectionClickDelegate.collectionDidSelectiAt(masterIndex: self.masterIndex, index: indexPath.item, feedForDisplay: self.feedForDisplay)
            if self.feedForDisplay.liveFeeds[indexPath.item].feedType != "LiveStreamVideo" {
                collectionClickDelegate.collectionViewsStartListen(masterIndex: self.masterIndex, feedId: self.feedForDisplay.liveFeeds[indexPath.item].feedId)
            } else {
                print("Was Live...!")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionLive.frame.size.width , height: self.collectionLive.frame.size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

class FeedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var litMeter: Meter!
    @IBOutlet weak var imgFeed: UIImageView!
    @IBOutlet weak var btnMore: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnCmt: UIButton!
    @IBOutlet weak var btnLits: UIButton!
    @IBOutlet weak var lblcmt: UILabel!
    @IBOutlet weak var lblLits: UILabel!
    @IBOutlet weak var btnViews: UIButton!
    @IBOutlet weak var btnViewsOther: UIButton!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var imgSwipe: UIImageView!

}
