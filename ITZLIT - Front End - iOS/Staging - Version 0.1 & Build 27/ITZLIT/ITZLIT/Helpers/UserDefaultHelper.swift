//
//  UserDefaultHelper.swift
//  breeze
//
//  Created by devang.bhatt on 09/08/17.
//  Copyright © 2017 Solution Analysts. All rights reserved.
//

import UIKit
import CoreLocation

class UserDefaultHelper: NSObject {
    
    typealias JSON = [String: Any]
    
    //MARK:- set and get preferences for String
    /*!
     method getPreferenceValueForKey
     abstract To get the preference value for the key that has been passed
     */
    class func getPREF(_ key:String)->String?
    {
        return Foundation.UserDefaults.standard.value(forKey: key ) as? String
    }
    
    /*!
     method setPreferenceValueForKey for int value
     abstract To set the preference value for the key that has been passed
     */
    
    class func setPREF(_ sValue:String, key:String)
    {
        Foundation.UserDefaults.standard.setValue(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    /*!
     method delPREF for string
     abstract To delete the preference value for the key that has been passed
     */
    
    class func  delPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    //MARK:- set and get preferences for Integer
    
    /*!
     method getPreferenceValueForKey for array for int value
     abstract To get the preference value for the key that has been passed
     */
    class func getIntPREF(_ key:String) -> Int?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? Int
    }
        
    /*!
     method setPreferenceValueForKey
     abstract To set the preference value for the key that has been passed
     */
    
    class func setIntPREF(_ sValue:Int, key:String)
    {
        Foundation.UserDefaults.standard.setValue(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    /*!
     method delPREF for integer
     abstract To delete the preference value for the key that has been passed
     */
    
    class func  delIntPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    //MARK:- set and get preferences for Double
    
    /*!
     method getPreferenceValueForKey for array for int value
     abstract To get the preference value for the key that has been passed
     */
    class func getDoublePREF(_ key:String) -> Double?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? Double
    }
    
    
    /*!
     method setPreferenceValueForKey
     abstract To set the preference value for the key that has been passed
     */
    
    class func setDoublePREF(_ sValue:Double, key:String)
    {
        Foundation.UserDefaults.standard.setValue(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    //MARK:- set and get preferences for Array
    
    /*!
     method getPreferenceValueForKey for array
     abstract To get the preference value for the key that has been passed
     */
    class func getIntArrPREF(_ key:String) -> [Int]?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? [Int]
    }
    
    class func getArrPREF(_ key:String) -> [String]?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? [String]
    }
    
    class func getArrBoolPREF(_ key:String) -> [Bool]?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? [Bool]
    }
    
    /*!
     method setPreferenceValueForKey for array
     abstract To set the preference value for the key that has been passed
     */
    
    class func setArrIntPREF(_ sValue:[Int], key:String)
    {
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    class func setArrPREF(_ sValue:[String], key:String)
    {
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    class func setArrBoolPREF(_ sValue:[Bool], key:String)
    {
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    /*!
     method delPREF
     abstract To delete the preference value for the key that has been passed
     */
    
    class func  delArrPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    //MARK:- set and get preferences for Dictionary
    /*!
     method getPreferenceValueForKey for dictionary
     abstract To get the preference value for the key that has been passed
     */
    class func getDicPREF(_ key:String)-> [String: Any]
    {
        var _defaultData:[String:Any] = [:]
        
        if let data = Foundation.UserDefaults.standard.object(forKey: key ) as? Data {
            guard let object = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] else {
                return _defaultData
            }
            
            _defaultData = object
        }
        return _defaultData
    }
    
    /*!
     method setPreferenceValueForKey for dictionary
     abstract0 To set the preference value for the key that has been passed
     */
    
    class func setDicPREF(_ sValue:[String: Any], key:String)
    {
        Foundation.UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: sValue), forKey: key)
        Foundation.UserDefaults.standard.synchronize()
    }
    
    class func  delDicPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    //MARK:- set and get preferences for Boolean
    /*!
     method getPreferenceValueForKey for boolean
     abstract To get the preference value for the key that has been passed
     */
    class func getBoolPREF(_ key:String) -> Bool {
        return Foundation.UserDefaults.standard.bool(forKey: key )
    }
    
    
    /*!
     method setBoolPreferenceValueForKey
     abstract To set the preference value for the key that has been passed
     */
    
    class func setBoolPREF(_ sValue:Bool , key:String){
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    /*!
     method delPREF for boolean
     abstract To delete the preference value for the key that has been passed
     */
    
    class func  delBoolPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
    
    class func setBundleSetting(value: String, key: String) {
        Foundation.UserDefaults.standard.setValue(value, forKey: key )
        Foundation.UserDefaults.standard.synchronize()
    }
}


