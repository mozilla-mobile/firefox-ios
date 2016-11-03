//
//  NBTextField.swift
//  libPhoneNumber
//
//  Created by tabby on 2015. 11. 7..
//  Copyright © 2015년 ohtalk.me. All rights reserved.
//

import libPhoneNumber


public class NBTextField: UITextField
{
    // MARK: Options/Variables for phone number formatting
    
    var phoneNumberUtility: NBPhoneNumberUtil = NBPhoneNumberUtil()
    var phoneNumberFormatter: NBAsYouTypeFormatter?
    
    var shouldCheckValidationForInputText: Bool = true
    
    var countryCode: String = "KR" {//5 NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String {
        didSet {
            phoneNumberFormatter = NBAsYouTypeFormatter(regionCode: countryCode)
            numberTextDidChange()
        }
    }

    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForNotifications()
        phoneNumberFormatter = NBAsYouTypeFormatter(regionCode: countryCode)
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: UITextField input managing
    
    override public func deleteBackward() {
        if text?.characters.last == " " {
            if let indexNumberWithWhiteSpace = text?.endIndex.advancedBy(-1) {
                text = text?.substringToIndex(indexNumberWithWhiteSpace)
            }
            return
        }
        super.deleteBackward()
    }

    
    // MARK: Notification for "UITextFieldTextDidChangeNotification"
    
    private func registerForNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "numberTextDidChange", name: UITextFieldTextDidChangeNotification, object: self)
    }
    
    func numberTextDidChange() {
        let numbersOnly = phoneNumberUtility.normalizePhoneNumber(text)
        text = phoneNumberFormatter!.inputStringAndRememberPosition(numbersOnly)
        
        if phoneNumberFormatter!.isSuccessfulFormatting == false && shouldCheckValidationForInputText {
            shakeIt()
        }
    }
    
    func shakeIt() {
        let offset = self.bounds.size.width / 30
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = NSValue(CGPoint: CGPointMake(self.center.x - offset, self.center.y))
        animation.toValue = NSValue(CGPoint: CGPointMake(self.center.x + offset, self.center.y))
        self.layer.addAnimation(animation, forKey: "position")
    }
}
