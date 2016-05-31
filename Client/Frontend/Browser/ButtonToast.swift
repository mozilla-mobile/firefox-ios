/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct ButtonToastUX {
    static let ToastDismissAfter = 4.0
    static let ToastPadding = 15.0
    static let ToastButtonPadding:CGFloat = 10.0
    static let ToastDelay = 0.9
    static let ToastButtonBorderRadius:CGFloat = 5
    static let ToastButtonBorderWidth:CGFloat = 1
}

class ButtonToast {
    
    private var dismissed = false
    private var completionHandler: (Bool) -> Void = {_ in }
    private lazy var toast: UIView = {
        let toast = UIView()
        toast.backgroundColor = SimpleToastUX.ToastDefaultColor
        return toast
    }()
    
    func showAlertWithText(labelText: String, buttonText:String, offset:CGFloat, completion: (buttonPressed: Bool) -> Void) {
        guard let window = UIApplication.sharedApplication().windows.first else {
            return
        }
        
        completionHandler = completion
        
        let toast = self.createView(labelText, buttonText: buttonText)
        window.addSubview(toast)
        toast.snp_makeConstraints { (make) in
            make.width.equalTo(window.snp_width)
            make.height.equalTo(SimpleToastUX.ToastHeight)
            make.bottom.equalTo(window.snp_bottom).offset(-offset)
        }
        animate(toast)
    }
    
    private func createView(labelText: String, buttonText: String) -> UIView {
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        label.font = SimpleToastUX.ToastFont
        label.text = labelText
        toast.addSubview(label)
        
        let button = UIButton()
        button.layer.cornerRadius = ButtonToastUX.ToastButtonBorderRadius
        button.layer.borderWidth = ButtonToastUX.ToastButtonBorderWidth
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.setTitle(buttonText, forState: .Normal)
        button.titleLabel?.font = SimpleToastUX.ToastFont
        
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(ButtonToast.buttonPressed(_:)))
        button.addGestureRecognizer(recognizer)
        
        toast.addSubview(button)
        
        label.snp_makeConstraints { (make) in
            make.leading.equalTo(toast).offset(ButtonToastUX.ToastPadding)
            make.centerY.equalTo(toast)
        }
        
        button.snp_makeConstraints { (make) in
            make.trailing.equalTo(toast).offset(-ButtonToastUX.ToastPadding)
            make.centerY.equalTo(toast)
            make.width.equalTo(button.titleLabel!.intrinsicContentSize().width + 2*ButtonToastUX.ToastButtonPadding)
        }
        
        return toast
    }
    
    private func dismiss(toast: UIView, buttonPressed: Bool) {
        guard dismissed == false else {
            return
        }
        dismissed = true
        
        toast.transform = CGAffineTransformIdentity
        UIView.animateWithDuration(SimpleToastUX.ToastAnimationDuration,
                                   animations: {
                                    toast.transform = CGAffineTransformMakeScale(1.0, 0.001)
                                    toast.frame.origin.y = toast.frame.origin.y + SimpleToastUX.ToastHeight/2
            },
                                   completion: { finished in
                                    toast.removeFromSuperview()
                                    if(!buttonPressed) {
                                        self.completionHandler(false)
                                    }
            }
        )
    }
    
    private func animate(toast: UIView) {
        toast.transform = CGAffineTransformMakeScale(1.0, 0.001)
        toast.frame.origin.y = toast.frame.origin.y + SimpleToastUX.ToastHeight/2
        UIView.animateWithDuration(SimpleToastUX.ToastAnimationDuration, delay: ButtonToastUX.ToastDelay, options: [],
                                   animations: {
                                    toast.transform = CGAffineTransformIdentity
                                    toast.frame.origin.y = toast.frame.origin.y - SimpleToastUX.ToastHeight/2
            },
                                   completion: { finished in
                                    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(SimpleToastUX.ToastDismissAfter * Double(NSEC_PER_SEC)))
                                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                                        self.dismiss(toast, buttonPressed: false)
                                    })
            }
        )
    }
    
    @objc func buttonPressed(gestureRecognizer: UIGestureRecognizer) {
        self.completionHandler(true)
        self.dismiss(toast, buttonPressed: true)
    }
}
