//
//  ILCustomViews.swift
//  ITZLIT
//
//  Created by devang.bhatt on 25/10/17.
//  Copyright © 2017 Solution Analysts Pvt. Ltd. All rights reserved.
//

import UIKit

@IBDesignable class ILCustomViews: UIView {

    @IBOutlet var lblName: UILabel!
    @IBOutlet var txtName: UITextField!
    @IBOutlet var vwSeparator: UIView!
   
    var view: UIView!
    var delegate : UITextFieldDelegate? = nil {
        didSet{
            txtName.delegate = delegate
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
    }
    
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "ILCustomViews", bundle: bundle)
        
        // Assumes UIView is top level and only object in BreezeCustomView.xib file
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return view
    }
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            txtName.attributedPlaceholder = NSAttributedString(string:txtName.placeholder != nil ? txtName.placeholder! : "", attributes:[NSAttributedStringKey.foregroundColor: newValue!])
        }
    }
    
    @IBInspectable var placeHolderSize: UIFont? {
        get {
            return self.placeHolderSize
        }
        set {
            txtName.attributedPlaceholder = NSMutableAttributedString(string: txtName.placeholder != nil ? txtName.placeholder! : "", attributes:[NSAttributedStringKey.font:UIFont(name: "", size: 0)!])
        }
    }
    
    @IBInspectable var textFieldPlaceHolder:String? {
        get {
            return txtName.placeholder
        }
        set(textFieldPlaceHolder) {
            txtName.placeholder = textFieldPlaceHolder
        }
    }
    
    @IBInspectable var labelName: String? {
        get {
            return lblName.text
        }
        set(lablName) {
            lblName.text = lablName
        }
    }
    
    @IBInspectable var labelColor: UIColor? {
        get {
            return self.labelColor
        }
        set(lablColor) {
           lblName.textColor = lablColor
        }
    }
    @IBInspectable var labelFontSize: CGFloat = 10.0
}
