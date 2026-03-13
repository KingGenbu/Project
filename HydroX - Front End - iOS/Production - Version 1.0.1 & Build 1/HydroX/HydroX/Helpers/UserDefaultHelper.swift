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
    class func getPREF(_ key:String)->String?
    {
        return Foundation.UserDefaults.standard.value(forKey: key ) as? String
    }

    class func setPREF(_ sValue:String, key:String)
    {
        Foundation.UserDefaults.standard.setValue(sValue, forKey: key )
    }

    class func  delPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
    }
    //MARK:- set and get preferences for Integer

    class func getIntPREF(_ key:String) -> Int?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? Int
    }

    class func setIntPREF(_ sValue:Int, key:String)
    {
        Foundation.UserDefaults.standard.setValue(sValue, forKey: key )
    }

    class func  delIntPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
    }

    //MARK:- set and get preferences for Double

    class func getDoublePREF(_ key:String) -> Double?
    {
        return Foundation.UserDefaults.standard.object(forKey: key ) as? Double
    }

    class func setDoublePREF(_ sValue:Double, key:String)
    {
        Foundation.UserDefaults.standard.setValue(sValue, forKey: key )
    }

    //MARK:- set and get preferences for Array

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

    class func setArrIntPREF(_ sValue:[Int], key:String)
    {
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
    }

    class func setArrPREF(_ sValue:[String], key:String)
    {
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
    }

    class func setArrBoolPREF(_ sValue:[Bool], key:String)
    {
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
    }

    class func  delArrPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
    }
    //MARK:- set and get preferences for Dictionary
    class func getDicPREF(_ key:String)-> [String: Any]
    {
        var _defaultData:[String:Any] = [:]

        if let data = Foundation.UserDefaults.standard.object(forKey: key ) as? Data {
            guard let object = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSString.self, NSNumber.self, NSArray.self], from: data) as? [String: Any] else {
                return _defaultData
            }

            _defaultData = object ?? [:]
        }
        return _defaultData
    }

    class func setDicPREF(_ sValue:[String: Any], key:String)
    {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: sValue, requiringSecureCoding: false) {
            Foundation.UserDefaults.standard.set(data, forKey: key)
        }
    }

    class func  delDicPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
    }

    //MARK:- set and get preferences for Boolean
    class func getBoolPREF(_ key:String) -> Bool {
        return Foundation.UserDefaults.standard.bool(forKey: key )
    }

    class func setBoolPREF(_ sValue:Bool , key:String){
        Foundation.UserDefaults.standard.set(sValue, forKey: key )
    }

    class func  delBoolPREF(_ key:String)
    {
        Foundation.UserDefaults.standard.removeObject(forKey: key )
    }

    class func setBundleSetting(value: String, key: String) {
        Foundation.UserDefaults.standard.setValue(value, forKey: key )
    }
}
