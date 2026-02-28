//
//  RequesterList.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 06/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Foundation

class User
{
    var _id:String = ""
    var fullName:String = ""
    var profilePic:String = ""
    
    func Populate(dictionary:Dictionary<String, Any>) {
        
        _id = dictionary["_id"] as! String
        fullName = dictionary["fullName"] as! String
        profilePic = dictionary["profilePic"] as? String ?? ""
    }
    class func PopulateArray(user:Dictionary<String,Any>) -> User
    {
        let result = User()
        result.Populate(dictionary: user )
        return result
    }
    
}

class requesterList
{
    var _id:String = ""
    var user:User!
    
    func Populate(dictionary:NSDictionary) {
        
        _id = dictionary["_id"] as! String
        user = User.PopulateArray(user: dictionary["user"] as! Dictionary<String,Any>)
    }
    
   
    
    class func Populate(list:Array<Any>) -> [requesterList]
    {
        var FinalList = [requesterList]()
        for item in list {
            let result = requesterList()
            result.Populate(dictionary: item as! NSDictionary)
            
            FinalList.append(result)
        }
        
        return FinalList
    }
    
}


