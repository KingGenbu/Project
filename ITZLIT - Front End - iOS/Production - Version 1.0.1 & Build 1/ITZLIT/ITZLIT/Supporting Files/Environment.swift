//
//  Environment.swift
//  ITZLIT
//
//  Created by Sagar Thummar on 24/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation

enum Environment: String {
    case Development = "Development"
    case Staging = "Staging"
    case Production = "Production"

    var name: String {
        switch self {
        case .Development: return self.rawValue
        case .Staging: return self.rawValue
        case .Production: return self.rawValue
        }
    }
}
