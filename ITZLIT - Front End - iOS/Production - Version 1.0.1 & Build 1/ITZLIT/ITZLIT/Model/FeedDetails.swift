//
//  FeedDetails.swift
//  ITZLIT
//
//  Created by Devang Bhatt on 18/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation

class FeedDetailModel: NSObject {
    var arrFeedDetails: [FeedDetail]!
}

class FeedDetail {
    
    var _id: String?
    var userDict: [String:Any]?
    var userID: String?
    var userFullName: String?
    var branchLink: String?
    var userProfilePic: String?
    var mediaDict: MediaFeedDetail?
    var feedType: String?
    var caption: String?
    var privacyDict: [String:Any]?
    var privacyLevel: String? = "Public"
    var sharedWith:[String]?
    var comment: Int?
    var viewers: Int?
    var itzlitCount: Int?
    var isItzlit:Bool?
    var createdAt:NSDate?
    
    init(values: [String: Any]) {
        if let _id = values["_id"] as? String {
            self._id = _id
        }
        if let userDict = values["user"] as? [String:Any] {
            if let _id = userDict["_id"] as? String {
                self.userID = _id
            }
            if let fullName = userDict["fullName"] as? String {
                self.userFullName = fullName
            }
            if let profilePic = values["profilePic"] as? String {
                self.userProfilePic  = profilePic
            }
        }
        
        if let media = values["media"] as? [String:Any] {
            self.mediaDict = MediaFeedDetail.init(values: media)
        }
//        branchLink
        if let branchLink = values["branchLink"] as? String {
            self.branchLink = branchLink
        }
        if let feedType = values["feedType"] as? String {
            self.feedType = feedType
        }
        
        if let caption = values["caption"] as? String {
            self.caption = caption
        }
        
        if let privacy = values["privacy"] as? [String:Any] {
            self.privacyDict = privacy
            if let level = privacy["level"] as? String {
                self.privacyLevel = level
            }
            if let sharedWith = privacy["sharedWith"] as? [String] {
                self.sharedWith = sharedWith
            }
        }
        
        if let comment = values["comment"] as? Int {
            self.comment = comment
        }
        
        if let viewers = values["viewers"] as? Int {
            self.viewers = viewers
        }
        
        if let itzlitCount = values["itzlitCount"] as? Int {
            self.itzlitCount = itzlitCount
        }
        
        
        if let isItzlit = values["isItzlit"] as? Bool {
            self.isItzlit = isItzlit
        }
        
        if let createdAt = values["createdAt"] as? String {
            self.createdAt =  ItFeedList.DateFromString(dateString: createdAt)
        }
    }
    
}


class MediaFeedDetail {
    var _id: String?
    var mimeType: String?
    var path: String?
    var arrThumbs: [[String:Any]]?
    var thumbID : String?
    var thumbsize: String?
    var thumbpath : String?
    var createdAt:NSDate?
    var duration: TimeInterval?
    var streamID: String?
    
    init(values: [String:Any]) {
        if let _id = values["_id"] as? String {
            self._id = _id
        }
        
        if let mimeType = values["mimeType"] as? String {
            self.mimeType = mimeType
        }
        
        if let path = values["path"] as? String {
            self.path = path
        }
        
        if let arrThumbs = values["thumbs"] as? [[String:Any]] {
            for dictThumb in arrThumbs {
                if let thumbID = dictThumb["_id"] as? String {
                    self.thumbID = thumbID
                }
                
                if let thumbPath = dictThumb["path"] as? String {
                    self.thumbpath = thumbPath
                }
                
                if let thumbSize = dictThumb["size"] as? String {
                    self.thumbsize = thumbSize
                }
            }
        }
        
        if let createdAt = values["createdAt"] as? String {
            self.createdAt =  ItFeedList.DateFromString(dateString: createdAt)
        }

        duration = values["duration"] as? TimeInterval ?? 0
        
        if let streamId = values["streamId"] as? String {
            self.streamID = streamId
        }
    }
}

