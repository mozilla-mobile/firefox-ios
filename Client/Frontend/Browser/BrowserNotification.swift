//
//  BrowserNotification.swift
//  Client
//
//  Created by Aaron on 1/14/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import UIKit

class BrowserNotification: UIView {

    private var errorLabel:UILabel!
    
    override init() {
        super.init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewDidInit()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewDidInit()
    }

    private func viewDidInit() {
        self.backgroundColor = UIColor.whiteColor()
        self.alpha = 0.0

        errorLabel = UILabel()
        errorLabel.backgroundColor = UIColor.clearColor()
        errorLabel.textColor = UIColor.lightGrayColor()
        errorLabel.textAlignment = NSTextAlignment.Center
        errorLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        errorLabel.numberOfLines = 0
        self.addSubview(errorLabel)

        self.errorLabel.snp_remakeConstraints { make in
            make.left.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(self).offset(-100)
        }
    }

    func notification(error: NSError?) {
        errorLabel.text = error?.localizedDescription
        showError()
    }
    
    func hideNotification() {
        hideError()
    }
    
    private func showError() {
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 1.0
            }, completion: { (finished) -> Void in
                if (finished) {
                }
        })
    }
    
    private func hideError() {
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.alpha = 0.0
            }, completion: { (finished) -> Void in
                if (finished) {
                }
        })
    }
    
    func SELdidClickSlideOut() {
        hideError()
    }
}
