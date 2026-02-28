//
//  RequesterList.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 06/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//
import UIKit
import Foundation


class commentList
{
    var _id:String = ""
    var commentText:String = ""
    var createdAt:NSDate?
    var fullName:String = ""
    var profilePic:String = ""
    func Populate(dictionary:Dictionary<String,Any>) {
        _id = dictionary["_id"] as! String
        commentText = (dictionary["comments"] as! Dictionary<String,Any>)["commentText"] as! String
        createdAt =  ItFeedList.DateFromString(dateString: (dictionary["comments"] as! Dictionary<String,Any>)["createdAt"] as! String)
        fullName = (dictionary["users"] as! Dictionary<String,Any>)["fullName"] as? String ?? ""
        profilePic = (dictionary["users"] as! Dictionary<String,Any>)["profilePic"] as? String ?? ""
    }
    
    
    
    class func Populate(list:Array<Any>) -> [commentList]
    {
        var FinalList = [commentList]()
        for item in list {
            let result = commentList()
            result.Populate(dictionary: item as! Dictionary<String, Any>)
            
            FinalList.append(result)
        }
        
        return FinalList
    }
    
}
