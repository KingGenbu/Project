//
//  Meter.swift
//  Meter
//
//  Created by Dhaval Soni on 13/12/17.
//  Copyright © 2017 Dhaval Soni. All rights reserved.
//


import UIKit






class Meter: UIView {
    
    fileprivate var coloredImageView : UIImageView!
    fileprivate var emptyImageView : UIImageView!
    var lits : CGFloat = 0 {
        didSet{
//            if emptyImageView != nil {
//                coloredImageView.removeFromSuperview()
//                emptyImageView.removeFromSuperview()
//            }
//
//            self.addBehavior()
            
            if lits <= 41 {
                
                emptyImageView.frame.origin.y = -((self.frame.size.height*0.0245)*lits )
//                if lits <= 25 {
//                let singlebarHight =  floor(self.frame.size.height*0.0207253886)
//                let spacing = (self.frame.size.height - (41*singlebarHight))/40
//                emptyImageView.frame.origin.y = 0
//                emptyImageView.frame.origin.y = -(singlebarHight*lits + spacing*lits )
//                } else {
//                    let singlebarHight =  floor(self.frame.size.height*0.0257253886)
//                    let spacing = (self.frame.size.height - (41*singlebarHight))/40
//                    emptyImageView.frame.origin.y = 0
//                    emptyImageView.frame.origin.y = -(singlebarHight*lits + spacing*lits )
//                }
            }else {
                emptyImageView.frame.origin.y = -((self.frame.size.height*0.0245)*41 )
            }
            
        }
    }
   
    
    
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        
    }
    convenience init() {
        self.init(frame: CGRect.zero)
        
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        coloredImageView.frame.size = self.frame.size
        emptyImageView.frame.size = self.frame.size
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
          self.addBehavior()
    }
    
    func addBehavior() {
        self.clipsToBounds = true
        coloredImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        coloredImageView.image = #imageLiteral(resourceName: "meter")
        coloredImageView.contentMode = .scaleToFill
        
        emptyImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        emptyImageView.image = #imageLiteral(resourceName: "meterEmpty")
        emptyImageView.contentMode = .scaleToFill
        self.addSubview(coloredImageView)
        self.addSubview(emptyImageView)
    }
}
