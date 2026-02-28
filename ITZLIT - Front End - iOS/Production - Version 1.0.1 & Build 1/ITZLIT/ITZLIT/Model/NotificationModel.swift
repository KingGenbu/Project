//
//  NotificationModel.swift
//  ITZLIT
//
//  Created by devang.bhatt on 20/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation

class NotificationModel: NSObject {
    
    var notification: [NotificationList]?
    
    override init() {
        //initalize all the variable for the model
    }
}

class NotificationList {

    var message : String?
    var _id: String?
    var profilePic : String?
    var createdAt: Date?
    var notificationType: String?
    var thumbID : String?
    var thumbsize: String?
    var thumbpath : String?
    var isNotificationSeen: Bool = false 
    
    init(values: [String: Any]) {
        
        if let _id = values["_id"] as? String {
            self._id = _id
        }
        
        if let message = values["message"] as? String {
            self.message = message
        }
        
        if let createdAt = values["createdAt"] as? String {
            self.createdAt = ItFeedList.DateFromString(dateString: createdAt) as Date
        }
        
        if let follower = values["follower"] as? [String : Any] {
            if let profilePic = follower["profilePic"] as? String {
                self.profilePic = profilePic
            }
        }
        
        if let dictUser = values["user"] as? [String:Any] {
            if let profilePic = dictUser["profilePic"] as? String {
                self.profilePic = profilePic
            }
        }
        
        if let dictUser = values["goLiveReqBy"] as? [String:Any] {
            if let profilePic = dictUser["profilePic"] as? String {
                self.profilePic = profilePic
            }
        }
        
        if let notificationType = values["notificationType"] as? String {
            self.notificationType = notificationType
        }
        
        if let dictMedia = values["media"] as? [String:Any] {
            if let arrThumbs = dictMedia["thumbs"] as? [[String:Any]] {
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
        }
    }
}
