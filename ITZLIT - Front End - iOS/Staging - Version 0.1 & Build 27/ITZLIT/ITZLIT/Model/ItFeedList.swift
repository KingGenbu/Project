//
//  ItFeedList.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 05/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

import Foundation



class Privacy
{
    var level:String = "Public"

    func Populate(dictionary:Dictionary<String, Any>) {
        level = dictionary["level"] as? String ?? ""
    }
    
    class func PopulateArray(item:Dictionary<String, Any>) -> Privacy {
        
        let newItem = Privacy()
        newItem.Populate(dictionary: item)
        return newItem
    }
}




class feedThumb
{
    var size:String = ""
    var path:String = ""
    var _id:String = ""
    
    var imageURL: URL? {
        return URL(string: path)
    }
    
    func Populate(dictionary:NSDictionary) {
        
        size = dictionary["size"] as! String
        path = dictionary["path"] as! String
        _id = dictionary["_id"] as! String
    }
    
    
    class func PopulateArray(array:NSArray) -> [feedThumb]
    {
        var result:[feedThumb] = []
        for item in array
        {
            let newItem = feedThumb()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}

class FollowingsFeed : Equatable
{
    static func ==(lhs: FollowingsFeed, rhs: FollowingsFeed) -> Bool {
        return lhs.feedId == rhs.feedId
    }
    
    var feedId:String = ""
    var feedType:String = ""
    var storyExpiration:NSDate?  // = ItFeedList.DateFromString(dateString: "2017-12-04T06:20:32.426Z")
    var updatedAt:NSDate?  // = ItFeedList.DateFromString(dateString:  "2017-12-04T06:20:32.426Z")
    var createdAt:NSDate?//= ItFeedList.DateFromString(dateString: "2017-12-04T06:20:32.426Z")
    var privacy:Privacy!
    var media:String = ""
    var mimeType:String = ""
    var path:String = ""
    var thumbs:[feedThumb] = []
    var itzlitCount:Int = 0
    var comments:Int = 0
    var viewers:Int = 0
    var caption:String = ""
    var duration : TimeInterval = 0
    var streamStatus:String = ""
    var streamId: String = ""
    var branchLink: String = ""
    func Populate(dictionary:Dictionary<String,Any>) {
        
        feedId = dictionary["_id"] as? String ?? ""
        feedType = dictionary["feedType"] as? String ?? ""
        storyExpiration =  ItFeedList.DateFromString(dateString: dictionary["storyExpiration"] as? String ?? "")
        updatedAt =  ItFeedList.DateFromString(dateString: dictionary["updatedAt"] as? String ?? "")
        createdAt =  ItFeedList.DateFromString(dateString: dictionary["createdAt"] as? String ?? "")
        privacy = Privacy.PopulateArray(item: dictionary["privacy"] as? Dictionary<String, Any> ?? [:])
        media = (dictionary["media"] as! Dictionary<String,Any>)["_id"] as? String ?? ""
        mimeType = (dictionary["media"] as! Dictionary<String,Any>)["mimeType"] as? String ?? ""
        path = (dictionary["media"] as! Dictionary<String,Any>)["path"] as? String ?? ""
        thumbs = feedThumb.PopulateArray(array: (dictionary["media"] as! Dictionary<String,Any>)["thumbs"]  as! NSArray)
        branchLink = dictionary["branchLink"] as? String ?? ""
        itzlitCount = dictionary["itzlitCount"] as?  Int ?? 0
        comments = dictionary["totalComments"] as?  Int ?? 0
        viewers = dictionary["totalViewers"] as?  Int ?? 0
        caption = dictionary["caption"] as? String ?? ""
        duration = (dictionary["media"] as! Dictionary<String,Any>)["duration"] as? TimeInterval ?? 0
        streamStatus = dictionary["streamStatus"] as? String ?? ""
        streamId = (dictionary["media"] as! Dictionary<String,Any>)["streamId"] as? String ?? ""
    }
    class func PopulateArray(array:Array<Any>) -> [FollowingsFeed]
    {
        var result:[FollowingsFeed] = []
        for item in array
        {
            let newItem = FollowingsFeed()
            newItem.Populate(dictionary: (item as! Dictionary<String,Any>))
//            newItem = item as! FollowingsFeed
            result.append(newItem)
        }
        return result
    }
}

class ItFeedList {
    var expandIndex : Int = 0
    var expanded:Bool = false
    var fullName:String = ""
    var profilePic:String = ""
    var followeeId:String = ""
    var isItzlit: Bool = false
    var followingsFeeds:[FollowingsFeed] = []
    var liveFeeds:[FollowingsFeed] = []
    var isSwipeIndicatorDisplayed = false 
    
    func Populate(dictionary:NSDictionary) {
        if dictionary["user"] != nil{
            fullName = (dictionary["user"] as! Dictionary<String, Any>)["fullName"] as?String ?? ""
            followeeId = (dictionary["user"] as! Dictionary<String, Any>)["_id"] as? String ?? ""
            profilePic = (dictionary["user"] as! Dictionary<String, Any>)["profilePic"] as? String ?? ""
        }
        
        followingsFeeds = FollowingsFeed.PopulateArray(array: dictionary["stories"] as! Array<Any>)
        
        isItzlit = dictionary["isItzlit"] as?  Bool ?? false
        liveFeeds = FollowingsFeed.PopulateArray(array: dictionary["liveStreams"] as! Array<Any>)
    }
    
    class func DateFromString(dateString:String) -> NSDate
    {
        if dateString.count > 0 {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
        return dateFormatter.date(from: dateString)! as NSDate
        }else{
            return NSDate()
        }
    }
    

    class func Populate(list:Array<Any>) -> [ItFeedList]
    {
        
        var FinalList = [ItFeedList]()
        for item in list {
            let result = ItFeedList()
            result.Populate(dictionary: item as! NSDictionary)
            
            FinalList.append(result)
        }
        
        return FinalList
    }
    
}

