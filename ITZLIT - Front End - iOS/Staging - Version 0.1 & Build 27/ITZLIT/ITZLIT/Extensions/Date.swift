//
//  Date.swift
//  ITZLIT
//
//  Created by Devang Bhatt on 08/12/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

extension Date {
    
    func getDifferanceFromCurrentTime(serverDate : Date) -> String {
        var strTimeAgo = ""
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: serverDate, to: self)
        if components.year! >= 1{
            strTimeAgo = "\(components.year!) \(components.year == 1 ? "Year" : "Years")"
        }
        else if components.month! >= 1 {
            strTimeAgo = "\(components.month!) \(components.month == 1 ? "Month" : "Months") ago"
        }
        else if components.day! >= 7 {
            strTimeAgo = "\((components.day! / 7)) \(components.day!/7 >= 1 ? "Week" : "Weeks") ago"
        }
        else {
            if components.day == 0 {
                if components.hour! >= 1 {
                    strTimeAgo = "\(components.hour!) \(components.hour == 1 ? "Hour" : "Hours") ago"
                }
                else if components.minute! >= 1{
                    strTimeAgo = "\(components.minute!) \(components.minute == 1 ? "Minute" : "Minutes") ago"
                }
                else if components.second! >= 1 {
                    strTimeAgo = "\(components.second!) \(components.second == 1 ? "Second" : "Seconds") ago"
                }
                else {
                    strTimeAgo = "Just now"
                }
            }
            else if components.day! == 1{
                strTimeAgo = "Yesterday"
            }
            else {
                strTimeAgo = "\(components.day!) Days ago"
            }
        }
        return strTimeAgo
    }
    
    func getCurrentUTCDateTime() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
        let strCurrentDate = dateFormatter.string(from: self)
        let finalCurrentUTCDate = dateFormatter.date(from: strCurrentDate) ?? self
        return finalCurrentUTCDate
    }
    
    func getFlushUTCDateTime() -> Date {
        let dateFormatter = DateFormatter()
        let time = "05:00 AM"
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let strCurrentDate = dateFormatter.string(from: self)
        let stringDate = strCurrentDate + " " + time
        
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
        
        let convertedDate = dateFormatter.date(from: stringDate)
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let strDate =  dateFormatter.string(from: convertedDate ?? self)
        let finalFlushUTCDate = dateFormatter.date(from: strDate)
        return finalFlushUTCDate ?? self
    }
}
