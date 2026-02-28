//
//  Configuration.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 24/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

struct Configuration {
    lazy var environment: Environment = {
        if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
            if configuration.range(of: "Development") != nil {
                return Environment.Development
            } else if configuration.range(of: "Staging") != nil {
                return Environment.Staging
            }
        }
        return Environment.Production
    }()
}

