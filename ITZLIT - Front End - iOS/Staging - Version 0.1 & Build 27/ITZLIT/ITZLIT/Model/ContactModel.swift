//
//  ContactModel.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 09/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Foundation




class ContactLIst
{
    var number:String = ""
    var deviceContactId:String = ""
    var connection = Connections()
    var image : UIImage?
    func Populate(dictionary:NSDictionary) {
        number = dictionary["number"] as! String
        deviceContactId = dictionary["deviceContactId"] as! String
        if dictionary["connection"] != nil {
            connection = Connections.PopulateArray(dict: dictionary["connection"] as! NSDictionary)
        }
        
    }
    class func Populate(list:NSArray) -> [ContactLIst]
    {
        
        var FinalList = [ContactLIst]()
        for item in list {
            let result = ContactLIst()
            result.Populate(dictionary: item as! NSDictionary)
            
            FinalList.append(result)
        }
        
        return FinalList
    }
    
}
class Connections
{
    var _id:String = ""
    var fullName:String = ""
    var email:String = ""
    var phoneNumber:String = ""
    var isFollowed:Bool = false
    var profilePic:String = ""
    var connecttionId:String = ""
    func Populate(dictionary:NSDictionary) {
        _id = dictionary["_id"] as! String
        fullName = dictionary["fullName"] as! String
        email = dictionary["email"] as! String
        phoneNumber = dictionary["phoneNumber"] as! String
        isFollowed = dictionary["isFollowed"] as! Bool
        connecttionId = dictionary["connecttionId"] != nil ? dictionary["connecttionId"] as! String : ""
        profilePic = dictionary["profilePic"] == nil ? "" : (dictionary["profilePic"] as? String)!
    }
    
    
    
    class func PopulateArray(dict:NSDictionary) -> Connections
    {
        let result = Connections()
        result.Populate(dictionary:dict)
        return result
    }
    
}
