//
//  FollowList.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 09/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Foundation

class Followee
{
    var _id:String = ""
    var fullName:String = ""
    var profilePic:String = ""
    
    
    var titleFirstLetter: String {
        return String(self.fullName[self.fullName.startIndex]).uppercased()
    }
    func Populate(dictionary:NSDictionary) {
        
        _id = dictionary["_id"] as! String
        fullName = dictionary["fullName"] as! String
        profilePic = dictionary["profilePic"] as? String ?? ""
        
    }
    class func PopulateArray(dict:NSDictionary) -> Followee
    {
        let result = Followee()
        result.Populate(dictionary: dict )
        
        return result
    }
    
}


class Follower
{
    
    
    
    var _id:String = ""
    var fullName:String = ""
    var profilePic:String = ""
   
    var titleFirstLetter: String {
        return String(self.fullName[self.fullName.startIndex]).uppercased()
    }
    
    func Populate(dictionary:NSDictionary) {
        
        _id = dictionary["_id"] as! String
        fullName = dictionary["fullName"] as! String
        profilePic = dictionary["profilePic"] as? String ?? ""
        
    }
    
    class func PopulateArray(dict:NSDictionary) -> Follower
    {
        let result = Follower()
        result.Populate(dictionary: dict )
        
        return result
    }
    
}



class FollowList
{
    var _id:String = ""
    var followee = Followee ()
    var follower = Follower ()
    var isFollowed : Bool = false
    var connecttionId = ""
     var isselected : Bool = false
    func Populate(dictionary:NSDictionary) {
        
        _id = dictionary["_id"] as! String
        followee = Followee.PopulateArray(dict: dictionary["followee"] as! NSDictionary)
        follower = Follower.PopulateArray(dict: dictionary["follower"] as! NSDictionary)
        isFollowed = dictionary["isFollowed"] != nil ? dictionary["isFollowed"] as! Bool : false
        connecttionId =  dictionary["connecttionId"] != nil ? dictionary["connecttionId"] as! String : ""
    }
    
    
    class func Populate(list:NSArray) -> [FollowList]
    {
        var FinalList = [FollowList]()
        for item in list {
            let result = FollowList()
            result.Populate(dictionary: item as! NSDictionary)
            
            FinalList.append(result)
        }
        
        return FinalList
        
        
        
    }
    
}
