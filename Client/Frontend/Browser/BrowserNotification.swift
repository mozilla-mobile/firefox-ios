//
//  BrowserNotification.swift
//  Client
//
//  Created by Aaron on 1/14/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import UIKit

public enum NotificationType {
    case Success;
    case Failure;
    case Notify;
    case Waring;
}

class BrowserNotification: UIView {

    private var errorLabel:UILabel!
    private var tapGesture: UITapGestureRecognizer!
    private var isVisible: Bool!

    override init() {
        super.init(frame: CGRectMake(0.0, UIScreen.mainScreen().bounds.size.height, UIScreen.mainScreen().bounds.size.width, 100))
        viewDidInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        viewDidInit()
    }

    private func viewDidInit() {
        self.backgroundColor = UIColor.redColor()

        errorLabel = UILabel()
        errorLabel.backgroundColor = UIColor.clearColor()
        self.addSubview(errorLabel)

        self.errorLabel.snp_remakeConstraints { make in
            make.left.equalTo(self)
            make.centerY.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(44)
        }

        tapGesture = UITapGestureRecognizer(target: self, action: "SELdidClickSlideOut")
    }

    func notification(error: NSError?, type: NotificationType) {
        errorLabel.text = error?.localizedDescription

        switch (type) {
        case .Success:
            self.backgroundColor = UIColor.greenColor()
        case .Failure:
            self.backgroundColor = UIColor.redColor()
        case .Notify:
            self.backgroundColor = UIColor.blueColor()
        case .Waring:
            self.backgroundColor = UIColor.yellowColor()
        }

        slideViewIn()
    }

    private func slideViewIn() {
        isVisible = true
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.frame = CGRectMake(0.0, UIScreen.mainScreen().bounds.size.height-100.0, UIScreen.mainScreen().bounds.size.width, 100)
            self.alpha = 0.8
        }) { (finished) -> Void in
            if (finished) {
                self.addGestureRecognizer(self.tapGesture)
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            if (self.isVisible == true)
            {
                self.slideViewOut()
            }
        })
    }

    private func slideViewOut() {
        isVisible = false
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.frame = CGRectMake(0.0, UIScreen.mainScreen().bounds.size.height, UIScreen.mainScreen().bounds.size.width, 100)
            self.alpha = 0.0
        }) { (finished) -> Void in
            if (finished) {
                self.removeGestureRecognizer(self.tapGesture)
            }
        }
    }

    func SELdidClickSlideOut() {
        slideViewOut()
    }
}
