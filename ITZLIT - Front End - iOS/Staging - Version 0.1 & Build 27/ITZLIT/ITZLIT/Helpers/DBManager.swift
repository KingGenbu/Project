//
//  DBManager.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 15/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Contacts
import SQLite

open class Manager: NSObject {
    
}
class DBManager: NSObject {
   
    static let shared = DBManager()
    private var db: Connection?
    let DBName = "ContactList.rdb"
    let DBStories = "Stories.rdb"
    
    let profilePic = Expression<String>("profilePic")
    let png = Expression<String>("png")
    let id = Expression<Int64>("id")
    var name = Expression<String>("name")
    let number = Expression<String>("number")
    let identifier = Expression<String>("identifier")
    let following = Expression<Bool>("following")
    let connection_id = Expression<String>("connection_id")
    let user_id = Expression<String>("user_id")
    let app_user = Expression<Bool>("app_user")
    
    let storyId = Expression<String>("storyId")
    
    func openDatabase() {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        
        do {
            db = try Connection("\(path)/\(DBName)")
        } catch {
            db = nil
            print ("Unable to open database")
        }
        
    }
   
    func copyDatabaseIfNeeded() {
        // Move database file from bundle to documents folder
        
        let fileManager = FileManager.default
        
        let documentsUrl = fileManager.urls(for: .documentDirectory,
                                            in: .userDomainMask)
        
        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }
        
        let finalDatabaseURL = documentsUrl.first!.appendingPathComponent("\(DBName)")
        
        if !( (try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
            
            let documentsURL = Bundle.main.resourceURL?.appendingPathComponent("\(DBName)")
            
            do {
                try fileManager.copyItem(atPath: (documentsURL?.path)!, toPath: finalDatabaseURL.path)
            } catch /*let error*/_ as NSError {
               // print("Couldn't copy file to final location! Error:\(error.description)")
            }
            
        } else {
            //print("Database file found at path: \(finalDatabaseURL.path)")
        }
    }
    
    func clearDb()  {
        openDatabase()
        do{
            try db?.run(Table("Contacts").delete())
        }
        catch{
            print("delete failed", error.localizedDescription)
        }
    }
    func getAllContacts() -> [DBContactLIst]
    {
        openDatabase()
        
        var arrlist = [DBContactLIst]()
        
        do {
            let tableContacts = Table("Contacts")

            for fetchedcontact in try db!.prepare(tableContacts)  {

                var contactToInsert = [String:Any]()
                contactToInsert["id"] = fetchedcontact[id]
                contactToInsert["name"] = fetchedcontact[name]
                contactToInsert["number"] = fetchedcontact[number]
                contactToInsert["identifier"] = fetchedcontact[identifier]
                contactToInsert["following"] = fetchedcontact[following]
                contactToInsert["connection_id"] = fetchedcontact[connection_id]
                contactToInsert["user_id"] = fetchedcontact[user_id]
                contactToInsert["app_user"] = fetchedcontact[app_user]
                contactToInsert["profilePic"] = fetchedcontact[profilePic]
                arrlist.append(DBContactLIst.Populate(contact: contactToInsert))
            }
        }
        catch{
            print("select failed ")
        }
        return arrlist
    }
    
    func insertContactTODb(contacts: [CNContact],onCompletion: @escaping ContactHandler)  {
        openDatabase()
        
        var arrStr:[String] = []
        let rowStr = "insert into Contacts (name,number,identifier,following,connection_id,user_id,app_user,profilePic) values"
        
        for contact in contacts {
            var contactname = ""
            var finalName = ""
            if let givenName = contact.givenName as String? {
                finalName = givenName
            }
            if let familyName = contact.familyName as String? {
                finalName += " " + familyName
            }
            if contact.givenName == "" && contact.familyName == "" {
                if let organizationName = contact.organizationName as String? {
                    finalName = " " + organizationName
                }
            }

            if let givenName = finalName as String? {
                contactname = givenName
                if contactname.contains("'"){
                    contactname = contactname.replacingOccurrences(of: "'", with: "''")
                }
                if contactname.contains("\""){
                    contactname = contactname.replacingOccurrences(of: "\"", with: "")
                }
            }
            for phoneNumber in contact.phoneNumbers {
                let values = "( \"\(contactname)\", \"\(phoneNumber.value.stringValue)\", \"\(contact.identifier)\", \"\("0")\", \"\("")\", \"\("")\", \"\("0")\", \"\("")\" )"
                arrStr.append(values)
            }
        }
        do {
            try db?.run("\(rowStr) \(arrStr.joined(separator: ","))")
            onCompletion(true)
        } catch {
            onCompletion(false)
            print(error)
        }
    }
    
    /// Insert Data in Story Detail Table
    func insertStoryDetailToDB(userId:String, storyId:String,onCompletion: @escaping ContactHandler)  {
        openDatabase()
        var arrStr:[String] = []
        let rowStr =  "insert into StoryDetail (userId,storyId) values"

        let values = "(\"\(userId)\", \"\(storyId)\")"
        arrStr.append(values)
        do {
            try db?.run("\(rowStr) \(arrStr.joined(separator: ","))")
            onCompletion(true)
        } catch {
            onCompletion(false)
            print(error)
        }
        
//        var storyid = storyId
//        do {
//            let tableContacts = Table("StoryDetail")
//
//            let table = tableContacts.filter(self.storyId == storyid)
//            let row = try db!.pluck(table)
//
//            if let id = try row?.get(self.storyId) {
//                storyid = id
//            } else{
//                storyid = ""
//            }
//            onCompletion(true)
//        }
//        catch{
//            print("select failed ", error)
//            onCompletion(false)
//        }
        
    }
    
    /// Insert Data in Stroy Seen Table
    func insertStorySeenDataToDB(storyId:String,onCompletion: @escaping ContactHandler)  {
        openDatabase()
        
        var arrStr:[String] = []
        let rowStr = "insert into StroySeen (storyId) values"
        let values = "(\"\(storyId)\")"
        arrStr.append(values)
        do {
            try db?.run("\(rowStr) \(arrStr.joined(separator: ","))")
            onCompletion(true)
        } catch {
            onCompletion(false)
            print(error)
        }
    }
    
    /// Fetch story id from story detail table
    func fetchStoryDetailData(storyid:String, onCompletion: @escaping ContactHandler) -> String  {
        openDatabase()
        var storyid = storyid
        do {
            let tableContacts = Table("StoryDetail")
            
            let table = tableContacts.filter(self.storyId == storyid)
            let row = try db!.pluck(table)
            
            if let id = try row?.get(self.storyId) {
                storyid = id
            } else{
                storyid = ""
            }
            onCompletion(true)
        }
        catch{
            print("select failed ", error)
            onCompletion(false)
        }
        return storyid
    }
   
    /// Fetch story id from story seen table and return bool value, that all stories of paticular user is seen or not.
    func isContainsAllStories(arrStoryid:[String], onCompletion: @escaping ContactHandler) -> Bool  {
        openDatabase()
        var isContainsAllStoriesId:Bool = false
        var fetchStoryId: String = ""
        var arrStories: [String] = []
        for storyid in arrStoryid {
            do {
                let tableContacts = Table("StroySeen")
                
                let table = tableContacts.filter(self.storyId == storyid)
                let row = try db!.pluck(table)
                
                if let id = try row?.get(self.storyId) {
                    fetchStoryId = id
                    arrStories.append(fetchStoryId)
                } else{
                    fetchStoryId = ""
                }
            }
            catch{
                print("select failed ", error)
                onCompletion(false)
                isContainsAllStoriesId = false
            }
        }
        
        if arrStoryid.count == arrStories.count {
            isContainsAllStoriesId =  true
            onCompletion(true)
        }else {
            isContainsAllStoriesId =  false
        }
        return isContainsAllStoriesId
    }
    
    func clearStoryDetailTable()  {
        openDatabase()
        do{
            try db?.run(Table("StoryDetail").delete())
        }
        catch{
            print("delete failed", error.localizedDescription)
        }
    }
    
    func updateContactWith(parameter:ContactLIst)  {
       openDatabase()
        let tableContacts = Table("Contacts")
        let user = tableContacts.filter(number == parameter.number)
        do{
            try db?.run(user.update(name<-parameter.connection.fullName,number<-parameter.connection.phoneNumber,identifier<-parameter.deviceContactId, following<-parameter.connection.isFollowed,connection_id<-parameter.connection.connecttionId,user_id<-parameter.connection._id,app_user<-true,profilePic<-parameter.connection.profilePic))
            
        }
        catch{
//            print("select failed ")
        }
    }
}
