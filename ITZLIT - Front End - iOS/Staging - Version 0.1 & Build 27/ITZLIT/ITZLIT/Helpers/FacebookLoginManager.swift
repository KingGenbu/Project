//
//  FacebookLoginManager.swift
//  ITZLIT
//
//  Created by devang.bhatt on 26/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class FBLoginManager : NSObject {
    class func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!, completionHandler: @escaping (Bool,[String:Any])->()) {
        FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields":"email, first_name, last_name, picture.type(large)"]).start { (connection, result, error) -> Void in
            
            if error == nil {
 
                if let dictResult = result as? [String:Any] {
                    if let userID = dictResult["id"] as? String {
                        UserDefaultHelper.setPREF(userID, key: AppUserDefaults.fb_Id)
                        let token = FBSDKAccessToken.current().tokenString
                        UserDefaultHelper.setPREF(token!, key: AppUserDefaults.fb_Token)
                        completionHandler(true, dictResult)
                    }
                }
            }
         }
    }
    
    class func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        FBSDKLoginManager().logOut()
    }
}
