//
//  UIView.swift
//  ITZLIT
//
//  Created by devang.bhatt on 26/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func addGradientToBackground() {
 
        let layer = CAGradientLayer()
        layer.frame = CGRect(origin: .zero, size: self.frame.size)
        layer.colors = [UIColor.gradientStart.cgColor, UIColor.gradientSecColor.cgColor,UIColor.gradientThirdColor.cgColor,UIColor.gradientFourthColor.cgColor,UIColor.gradientFifthColor.cgColor]
        layer.locations = [0.0, 0.18, 0.44, 0.73, 1.0]
        layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        layer.endPoint = CGPoint(x: 1.0, y: 0.0)
        self.layer.insertSublayer(layer, at: 0)
        self.layer.masksToBounds = true
     }
 
    func dropShadow(scale: Bool = true) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)//CGSize(width: -1, height: 1)
        self.layer.shadowRadius = 1
        self.layer.cornerRadius = 2.0
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offSet
        self.layer.shadowRadius = radius
        
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
 
}
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
