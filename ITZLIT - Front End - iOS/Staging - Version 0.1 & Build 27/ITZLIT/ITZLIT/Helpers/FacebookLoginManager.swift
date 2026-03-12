//
//  FacebookLoginManager.swift
//  HydroX
//
//  Created by devang.bhatt on 26/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class FBLoginManager: NSObject {
    class func loginButton(_ loginButton: LoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?, completionHandler: @escaping (Bool, [String: Any]) -> ()) {
        GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"]).start { _, result, error in
            guard error == nil else { return }
            if let dictResult = result as? [String: Any],
               let userID = dictResult["id"] as? String {
                UserDefaultHelper.setPREF(userID, key: AppUserDefaults.fb_Id)
                if let token = AccessToken.current?.tokenString {
                    UserDefaultHelper.setPREF(token, key: AppUserDefaults.fb_Token)
                }
                completionHandler(true, dictResult)
            }
        }
    }

    class func loginButtonDidLogOut(_ loginButton: LoginButton) {
        LoginManager().logOut()
    }
}
