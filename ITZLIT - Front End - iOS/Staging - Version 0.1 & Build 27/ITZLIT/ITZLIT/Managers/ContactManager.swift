//
//  ContactManager.swift
//  ITZLIT
//
//  Created by Dhaval Soni on 15/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
import UIKit
import AddressBook
import Contacts



class DBContactLIst
{
    var id:Int64?
    var name:String?
    var number : String?
    var identifier:String?
    var following:Bool?
    var connection_id:String?
    var user_id:String?
    var app_user:Bool?
    var profilePic : String?
    var pic:Data?
    func Populate(dictionary: [String:Any]) {
        id = dictionary["id"] as? Int64
        name = dictionary["name"] as? String
        number = dictionary["number"] as? String
        identifier = dictionary["identifier"] as? String
        following = dictionary["following"] as? Bool
        connection_id = dictionary["connection_id"] as? String
        user_id = dictionary["user_id"] as? String
        app_user = dictionary["app_user"] as? Bool
        profilePic = dictionary["profilePic"] as? String
        pic = dictionary["pic"] as? Data
    }
    class func Populate(contact:[String:Any]) -> DBContactLIst
    {
        
        
        let result = DBContactLIst()
        result.Populate(dictionary: contact)
        
        
        
        return result
    }
    
}
class ContactManager: NSObject {
    static let shared = ContactManager()
    fileprivate var hasRegisteredForNotifications: Bool?
    var dbUpadting: Bool?
    var inProgressSync: Bool = false
    fileprivate var store = CNContactStore()
    func fetchContactList()->[CNContact] {
        var contacts: [CNContact]!
        contacts = {
            
            let keysToFetch = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactPostalAddressesKey,
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataKey,
                CNContactImageDataAvailableKey,
                CNContactThumbnailImageDataKey] as [Any]
            
            // Get all the containers
            var allContainers: [CNContainer] = []
            do {
                allContainers = try self.store.containers(matching: nil)
            } catch {
                print("Error fetching containers")
            }
            var results: [CNContact] = []
            // Iterate all containers and append their contacts to our results array
            for container in allContainers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                
                do {
                    let containerResults = try self.store.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                    results.append(contentsOf: containerResults)
                } catch {
                    print("Error fetching results for container")
                }
            }
            return results
            
        }()
        
        return contacts
    }
    func checkContactsAccess(_ completion: @escaping (_ accessGranted: Bool) -> Void) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        // Access was granted.
        case .authorized:
            registerForCNContactStoreDidChangeNotification()
            completion(true)
        case .notDetermined:
            self.store.requestAccess(for: .contacts, completionHandler: {(granted, error) in
                self.registerForCNContactStoreDidChangeNotification()
                completion(granted)
            })
        // Access was denied.
        case .restricted,.denied:
            completion(false)  
        }
    }
    /// Register for CNContactStoreDidChangeNotification notifications.
    fileprivate func registerForCNContactStoreDidChangeNotification() {
        // Don't register if we have already done so.
        if hasRegisteredForNotifications == nil {
            
            NotificationCenter.default.addObserver(self, selector: #selector(ContactManager.storeDidChange(_:)), name: NSNotification.Name.CNContactStoreDidChange, object: nil)
            hasRegisteredForNotifications = true
        }
    }
    
    /// Stop listening for CNContactStoreDidChangeNotification notifications.
    fileprivate func unregisterForCNContactStoreDidChangeNotification() {
        // Only unregister an existing notification registration.
        if hasRegisteredForNotifications ?? true {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.CNContactStoreDidChange, object: nil)
            hasRegisteredForNotifications = false
        }
    }
    
    
    
    /// Notifies listeners that changes have occured in the contact store.
    @objc func storeDidChange(_ notification: Notification) {
        if dbUpadting == nil {
            dbUpadting = true
            let NavVccVar = UIApplication.shared.keyWindow?.rootViewController as! UINavigationController
            let ShnSrnVar = NavVccVar.visibleViewController
            if (ShnSrnVar?.isKind(of: ContactViewController.self))!{
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "handleStoreDidChangeNotification"), object: nil)
                
            } else {
                
                DispatchQueue.global(qos: .background).async {
                    
                    ContactManager.shared.setUpContactToDbWith(Loader: false, onCompletion: {(refresh) in
                        
                        
                        self.dbUpadting = nil
                        
                    })
                }
            }
            
            
        }
        //        unregisterForCNContactStoreDidChangeNotification()
        //        hasRegisteredForNotifications = nil
        //        registerForCNContactStoreDidChangeNotification()
        //
        //        
        //        
        //        NotificationCenter.default.post(name: Notification.Name(rawValue: MGCAppConfiguration.MGCNotifications.storeDidChange), object: self)
    }
    func storeContactToDb(contacts: [CNContact])  {
    }
    
    func setUpcontactUpdateNotify()  {
        
        checkContactsAccess { (accessGranted: Bool) in
            if accessGranted {
                
            }
        }
    }
    
    func setUpContactToDbWith(Loader:Bool ,onCompletion: @escaping ContactHandler)  {
        //   let localDBList = DBManager.shared.getAllContacts()
        //  if localDBList.count == 0 {//Fetch & store to db
        ContactManager.shared.inProgressSync = true
        let arrCnContact = self.fetchContactList()
        DBManager.shared.clearDb()
        if arrCnContact.count > 0{
            DBManager.shared.insertContactTODb(contacts: arrCnContact, onCompletion: { (refresh) in
                if refresh {
                    self.syncContactToserverWith(Loader: Loader) { (refresh) in
                        onCompletion(true)
                        ContactManager.shared.inProgressSync = false
                        
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "handleStoreDidChangeNotification"), object: "Login")
 
                    }
                }else{
                     ContactManager.shared.inProgressSync = false
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "handleStoreDidChangeNotification"), object: "Stop")
                }
                
            })
        } else {
            ContactManager.shared.inProgressSync = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: "handleStoreDidChangeNotification"), object: "Stop")
        }
        
        
    }
    
    func syncContactToserverWith(Loader:Bool,onCompletion: @escaping ContactHandler)  {
        
        let localDBList = DBManager.shared.getAllContacts()
        let regionCode = Locale.current.regionCode
        let notAppusers = localDBList.filter({$0.app_user == false})
        if notAppusers.count > 0 {
            let parameter: [String: Any] = [WebserviceRequestParmeterKey.regionCode: regionCode!,
                                            WebserviceRequestParmeterKey.contactListTOsyc : generatePacketToSync(contacts: notAppusers)]
            
            contactSyncApiwith(Loader: Loader, Perameter: parameter, onCompletion: {(refresh) in
                onCompletion(true)
            })
        } else {
            onCompletion(true)
        }
        
    }
    func generatePacketToSync(contacts:[DBContactLIst])->NSMutableArray{
        let finalList = NSMutableArray()
        for contact in contacts {
            var contactToSend = [String:Any]()
            contactToSend["deviceContactId"] = contact.identifier
            
            contactToSend["number"] = contact.number
            finalList.add(contactToSend)
        }
        return finalList
    }
    //MARK:- contact sync
    func contactSyncApiwith(Loader:Bool , Perameter:[String:Any],onCompletion: @escaping ContactHandler)  {
        if Loader {
            Helper.showProgressBar()
        }
        ApiManager.Instance.httpPostEncodingRequestWithHeader(urlPath: WebserverPath.contactsyc, parameter: Perameter, onCompletion: { (json, error, response) in
            if Loader {
                Helper.hideProgressBar()
            }
            if error == nil {
                if json.count > 0 && (response as! HTTPURLResponse).statusCode == 200  {
                    let syncedContacts = ContactLIst.Populate(list: json.arrayObject! as NSArray)
                    
                    for index in 0...syncedContacts.count-1 {
                        if syncedContacts[index].connection._id.count != 0 {
                            
                            DBManager.shared.updateContactWith(parameter: syncedContacts[index])
                            
                        }
                    }
                    onCompletion(true)
                }
            }
        }, onError: { (error, response) in
            onCompletion(true)
            print(error ?? "error")
        })
    }
    deinit {
        unregisterForCNContactStoreDidChangeNotification()
    }
}
