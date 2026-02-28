//
//  ApiManager.swift
//  ITZLIT
//
//  Created by devang.bhatt on 04/11/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

typealias ServiceResponse = (JSON, NSError?, URLResponse?) -> Void
typealias ErrorResponse = (NSError?, URLResponse?) -> Void
typealias ContactHandler = (Bool) -> Void
class ApiManager: NSObject {

    static let Instance = ApiManager()
    private var token = ""
    
    class var invitationLinkURL: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["invitationLinkURL"]! as! String
    }
    
    class var socketURL: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["socketURL"]! as! String
    }
    
    class var ytClientID: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["ytClientID"]! as! String
    }
    
    class var fbUrlScheme: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["FB_URL_Scheme"]! as! String
    }
    
    class var wowzaKey: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["WowzaKey"]! as! String
    }
    
    class var baseUrl: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["Base_URL"]! as! String
    }
    
    //var baseUrl = WebserverPath.baseUrl
    class var branchScheme: String {
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        return myDict!["Branch_URI_Scheme"]! as! String
    }
    override init() {
        if UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil {
            self.token = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token)!
        }
    }
    
    func sendHttpGetWithoutHeader(path: String, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + path
        print("GET - targetPath: " + targetUrl)
       
        Alamofire.request("\(targetUrl)", method: .get).responseJSON { response in
            switch response.result {
                
            case .success( _):
//                print(json)
                if response.response?.statusCode == 200 {
                    let swiftyJSON = try! JSON(data: response.data!)
                    
                    onComplete(swiftyJSON, nil, response.response)
                    break
                }
                
            case .failure(let error):
                print("error: \(error)")
                onError(error as NSError?, response.response)
            }
        }
    }
    
    func httpPostRequestWithoutHeader(urlPath: String, parameter: [String:Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        
        let targetUrl = ApiManager.baseUrl + urlPath
        print(targetUrl)
        
        Alamofire.request(targetUrl, method: HTTPMethod.post, parameters: parameter).responseJSON { (response) in
            switch response.result {
        
            case .success(_):
//                print(json)
                let swiftyJSON = try! JSON.init(data: response.data!)
                onCompletion(swiftyJSON, nil, response.response)
                 break
                
            case .failure(let error):
                print(error)
                onError(error as NSError, response.response)
                break
            }
        }
    }
    
    func httpPostRequestWithHeader(urlPath: String, parameter: [String:Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath
        print(targetUrl)
        
        if UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil
        {
            self.token = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token)!
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }
        
        Alamofire.request(targetUrl, method: HTTPMethod.post, parameters: parameter, headers: headers).responseJSON { (response) in
            switch response.result {
                
            case .success(let json):
                print(json)
                let swiftyJSON = try! JSON.init(data: response.data!)
                onCompletion(swiftyJSON, nil, response.response)
                 break
                
            case .failure(let error):
                print(error)
                onError(error as NSError, response.response)
                break
            }
        }
    }
    
    func sendMultiPart(path: String, formData: [String: String], imgData: Data, isAWSURL:Bool = false, isVideo: Bool = false, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
 
        let targetUrl = (isAWSURL == true ? path : ApiManager.baseUrl + path)
        
//        print("Multipart POST - targetPath: " + targetUrl)
         if UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil
        {
            self.token = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token)!
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }
 
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for (k, v) in formData {
                multipartFormData.append(v.data(using: String.Encoding.utf8)!, withName: k)
            }
            
            if !isAWSURL {
                multipartFormData.append(imgData, withName: "story", fileName: isVideo ? "attachment.mov" : "attachment.jpg", mimeType: isVideo ? "video/mp4" : "image/jpeg")
            } else {
                
                multipartFormData.append(imgData, withName: "file", fileName: isVideo ? "attachment.mov" : "attachment.jpg", mimeType: isVideo ? "video/quicktime" : "image/jpeg")
            }
        }, to: targetUrl, method: .post, headers:  ["\(WebserviceRequestParmeterKey.xAuthToken)":"\(self.token)"])
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (Progress) in
//                    print("Upload Progress: \(Progress.fractionCompleted)")
                })
                upload.responseJSON { response in
//                    print(response)
                    if response.response?.statusCode == 200 {
                        let swiftyJSON = try! JSON(data: response.data!)
                        onComplete(swiftyJSON, nil, response.response)
                    } else {
                        if let errorMessage = response.error?.localizedDescription {
                            Helper.showAlertDialog(APP_NAME, message: errorMessage, clickAction: {})
                        }
                        Helper.hideProgressBar()
                    }
                    
                }
                
            case .failure(let encodingError):
                Helper.hideProgressBar()
                onError(encodingError as NSError, nil)
            }
        }
    
    }
    
    func sendMultiPartAWS(path: String, imgData: Data, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
 
//        print("Multipart POST - targetPath: " + path)
  
        Alamofire.upload(imgData, to: path, method: .put).responseJSON { response in
//            print(response.result)
            if response.response?.statusCode == 200 {
                
                let swiftyJSON = JSON.init(response.data!)
                onComplete(swiftyJSON, nil, response.response)
                
             } else {
                Helper.hideProgressBar()
            }
         }
    }
    
 
    func sendHttpGetWithHeader(path: String, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + path
        print("GET - targetPath: " + targetUrl)
        
        var headers = [String: String]()
        
        if UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil
        {
            self.token = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token)!
        }
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }
         Alamofire.request("\(targetUrl)", method: .get, headers: headers).responseJSON { response in
            switch response.result {
                
            case .success(let json):
                
                print(json)
                let swiftyJSON = try! JSON(data: response.data!)
                
                onComplete(swiftyJSON, nil, response.response)
                break
 
            case .failure(let error):
                print("error: \(error)")
                onError(error as NSError?, response.response)
            }
        }
    }
    func httpPostEncodingRequestWithHeader(urlPath: String, parameter: [String:Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath
        print(targetUrl)
        
        if UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) != nil
        {
            self.token = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token)!
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }
        
        Alamofire.request(targetUrl, method: .post, parameters: parameter, encoding: JSONEncoding.default , headers:["\(WebserviceRequestParmeterKey.xAuthToken)":"\(self.token)"]).responseJSON { (response) in
          
            switch response.result {
                
            case .success(let json):
                print(json)
                
                let swiftyJSON = try! JSON.init(data: response.data!)
                onCompletion(swiftyJSON, nil, response.response)
                break
                
            case .failure(let error):
                print(error)
                onError(error as NSError, response.response)
                break
            }
        }
    }
    func sendPostEncodingWithoutHeader(urlPath: String, parameter: [String:Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath
//        print("POST - targetPath: " + targetUrl)
        
       
        Alamofire.request(targetUrl, method: .post, parameters: parameter, encoding: JSONEncoding.default).responseJSON { (response) in
//            print(response)
            switch response.result {
            case .success( _):
//                print(jsonValue as? [String : Any] ?? "no value")
                let swiftyJSON = try! JSON(data: response.data!)
                
                onCompletion(swiftyJSON, nil, response.response)
                break
 
            case .failure(let error):
                onError(error as NSError?, response.response)
                break;
            }
        }
    }
}

