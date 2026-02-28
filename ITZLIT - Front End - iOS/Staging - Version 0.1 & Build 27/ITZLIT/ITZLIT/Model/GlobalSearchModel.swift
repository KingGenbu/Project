//
//  GlobalSearchModel.swift
//  ITZLIT
//
//  Created by devang.bhatt on 13/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation

class GlobalSearch: NSObject {
 
    var _id : String!
    var email: String!
    var fullName: String!
    var isFollowed: Bool!
    var phoneNumber: String!
    var profilePic: String!
    var connecttionId: String!
    
    init(values: [String:Any]) {
        if let _id = values["_id"] as? String {
            self._id = _id
        }
        if let email = values["email"] as? String {
            self.email = email
        }
        if let fullName = values["fullName"] as? String {
            self.fullName = fullName
        }
        if let isFollowed = values["isFollowed"] as? Bool {
            self.isFollowed = isFollowed
        }
        if let phoneNumber = values["phoneNumber"] as? String {
            self.phoneNumber = phoneNumber
        }
        if let profilePic = values["profilePic"] as? String {
            self.profilePic = profilePic
        }
        if let connecttionId = values["connecttionId"] as? String {
            self.connecttionId = connecttionId
        }
    }
}


struct SearchGlobalData {
     var arrGlobalSearch: [GlobalSearch] = []
    
    init(values: [String:Any]) {
        guard let globalSearch = values["docs"] as? [[String:Any]] else{
            return
        }
        
        for searchData in globalSearch {
            let data = GlobalSearch(values: searchData)
            
            self.arrGlobalSearch.append(data)
        }
    }
 }
