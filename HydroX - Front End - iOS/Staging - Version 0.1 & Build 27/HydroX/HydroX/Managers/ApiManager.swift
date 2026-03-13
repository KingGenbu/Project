//
//  ApiManager.swift
//  HydroX
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

    /// Read a string value from the active Info.plist by key
    private static func plistValue(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            return ""
        }
        return value
    }

    class var invitationLinkURL: String { plistValue(for: "invitationLinkURL") }
    class var socketURL: String         { plistValue(for: "socketURL") }
    class var ytClientID: String        { plistValue(for: "ytClientID") }
    class var fbUrlScheme: String       { plistValue(for: "FB_URL_Scheme") }
    class var wowzaKey: String          { plistValue(for: "WowzaKey") }
    class var baseUrl: String           { plistValue(for: "Base_URL") }
    class var branchScheme: String      { plistValue(for: "Branch_URI_Scheme") }
    class var thumbnailBaseUrl: String   { plistValue(for: "ThumbnailBaseURL") }
    class var streamingHost: String      { plistValue(for: "StreamingHost") }
    class var streamingAppName: String   { plistValue(for: "StreamingAppName") }
    class var streamingUsername: String   { plistValue(for: "StreamingUsername") }
    class var streamingPassword: String   { plistValue(for: "StreamingPassword") }

    override init() {
        if let saved = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) {
            self.token = saved
        }
    }

    func sendHttpGetWithoutHeader(path: String, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + path
        print("GET - targetPath: " + targetUrl)

        Alamofire.request("\(targetUrl)", method: .get).responseJSON { response in
            switch response.result {
            case .success:
                if response.response?.statusCode == 200 {
                    let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
                    onComplete(swiftyJSON, nil, response.response)
                }
            case .failure(let error):
                print("error: \(error)")
                onError(error as NSError?, response.response)
            }
        }
    }

    func httpPostRequestWithoutHeader(urlPath: String, parameter: [String: Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath
        print(targetUrl)

        Alamofire.request(targetUrl, method: .post, parameters: parameter).responseJSON { response in
            switch response.result {
            case .success:
                let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
                onCompletion(swiftyJSON, nil, response.response)
            case .failure(let error):
                print(error)
                onError(error as NSError, response.response)
            }
        }
    }

    func httpPostRequestWithHeader(urlPath: String, parameter: [String: Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath
        print(targetUrl)

        if let saved = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) {
            self.token = saved
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }

        Alamofire.request(targetUrl, method: .post, parameters: parameter, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let json):
                print(json)
                let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
                onCompletion(swiftyJSON, nil, response.response)
            case .failure(let error):
                print(error)
                onError(error as NSError, response.response)
            }
        }
    }

    func sendMultiPart(path: String, formData: [String: String], imgData: Data, isAWSURL: Bool = false, isVideo: Bool = false, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = isAWSURL ? path : ApiManager.baseUrl + path

        if let saved = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) {
            self.token = saved
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }

        Alamofire.upload(multipartFormData: { multipartFormData in
            for (k, v) in formData {
                multipartFormData.append(v.data(using: .utf8)!, withName: k)
            }
            if !isAWSURL {
                multipartFormData.append(imgData, withName: "story", fileName: isVideo ? "attachment.mov" : "attachment.jpg", mimeType: isVideo ? "video/mp4" : "image/jpeg")
            } else {
                multipartFormData.append(imgData, withName: "file", fileName: isVideo ? "attachment.mov" : "attachment.jpg", mimeType: isVideo ? "video/quicktime" : "image/jpeg")
            }
        }, to: targetUrl, method: .post, headers: ["\(WebserviceRequestParmeterKey.xAuthToken)": "\(self.token)"])
        { result in
            switch result {
            case .success(let upload, _, _):
                upload.uploadProgress { _ in }
                upload.responseJSON { response in
                    if response.response?.statusCode == 200 {
                        let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
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
        Alamofire.upload(imgData, to: path, method: .put).responseJSON { response in
            if response.response?.statusCode == 200 {
                let swiftyJSON = JSON(response.data as Any)
                onComplete(swiftyJSON, nil, response.response)
            } else {
                Helper.hideProgressBar()
            }
        }
    }

    func sendHttpGetWithHeader(path: String, onComplete: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + path
        print("GET - targetPath: " + targetUrl)

        if let saved = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) {
            self.token = saved
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }

        Alamofire.request("\(targetUrl)", method: .get, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let json):
                print(json)
                let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
                onComplete(swiftyJSON, nil, response.response)
            case .failure(let error):
                print("error: \(error)")
                onError(error as NSError?, response.response)
            }
        }
    }

    func httpPostEncodingRequestWithHeader(urlPath: String, parameter: [String: Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath
        print(targetUrl)

        if let saved = UserDefaultHelper.getPREF(AppUserDefaults.pref_user_registered_token) {
            self.token = saved
        }
        var headers = [String: String]()
        if self.token.count > 0 {
            headers[WebserviceRequestParmeterKey.xAuthToken] = self.token
        }

        Alamofire.request(targetUrl, method: .post, parameters: parameter, encoding: JSONEncoding.default,
                          headers: ["\(WebserviceRequestParmeterKey.xAuthToken)": "\(self.token)"]).responseJSON { response in
            switch response.result {
            case .success(let json):
                print(json)
                let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
                onCompletion(swiftyJSON, nil, response.response)
            case .failure(let error):
                print(error)
                onError(error as NSError, response.response)
            }
        }
    }

    func sendPostEncodingWithoutHeader(urlPath: String, parameter: [String: Any], onCompletion: @escaping ServiceResponse, onError: @escaping ErrorResponse) {
        let targetUrl = ApiManager.baseUrl + urlPath

        Alamofire.request(targetUrl, method: .post, parameters: parameter, encoding: JSONEncoding.default).responseJSON { response in
            switch response.result {
            case .success:
                let swiftyJSON = (try? JSON(data: response.data ?? Data())) ?? JSON.null
                onCompletion(swiftyJSON, nil, response.response)
            case .failure(let error):
                onError(error as NSError?, response.response)
            }
        }
    }
}
