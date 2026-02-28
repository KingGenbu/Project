//
//  RecentStoryModel.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 14/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation

class RecentStoryPrivacy
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

class Thumb
{
    var size:String = ""
    var path:String = ""
    var _id:String = ""
    
    func Populate(dictionary:NSDictionary) {
        
        size = dictionary["size"] as! String
        path = dictionary["path"] as! String
        _id = dictionary["_id"] as! String
    }
    class func PopulateArray(array:NSArray) -> [Thumb]
    {
        var result:[Thumb] = []
        for item in array
        {
            let newItem = Thumb()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}

class Media
{
    var mimeType:String = ""
    var path:String = ""
    var thumbs:[Thumb] = []
    var duration: TimeInterval = 0
      func Populate(dictionary:NSDictionary) {
        
        mimeType = dictionary["mimeType"] as! String
        path = dictionary["path"] as! String
        thumbs = Thumb.PopulateArray(array: dictionary["thumbs"] as! [NSArray] as NSArray)
        duration = dictionary["duration"] as? TimeInterval ?? 0
    }

    
    //    class func PopulateArray(array:NSArray) -> [Media]
//    {
//        var result:[Media] = []
//        for item in array
//        {
//            let newItem = Media()

    
    //            newItem.Populate(dictionary: item as! NSDictionary)
//            result.append(newItem)
//        }
//        return result
//    }
    
    class func PopulateArray(dict:NSDictionary) -> Media
    {
        let result = Media()
        result.Populate(dictionary: dict )
        
        return result
    }
    
}

class RecentStory
{
    var _id:String = ""
    var user:String = ""
    var media:Media = Media()
    var feedType:String = ""
    var createdAt:NSDate?
    var viewers:Int = 0
    var caption:String = ""
    var privacy:Privacy!
    func Populate(dictionary:NSDictionary) {
        
        _id = dictionary["_id"] as! String
        user = dictionary["user"] as! String
        media = Media.PopulateArray(dict: dictionary["media"] as! NSDictionary)
        feedType = dictionary["feedType"] as! String
        createdAt =  ItFeedList.DateFromString(dateString: dictionary["createdAt"] as! String)
        viewers = dictionary["viewers"] as! Int
        caption = dictionary["caption"] as? String ?? ""
        privacy = RecentStoryPrivacy.PopulateArray(item: dictionary["privacy"] as? Dictionary<String, Any> ?? [:])
    }
 
    class func Populate(list:NSArray) -> [RecentStory]
    {
        var results = [RecentStory]()
        for item in list {
            let result = RecentStory()
            result.Populate(dictionary: item as! NSDictionary)
            
            results.append(result)
        }
        
        return results
     }
    
}
