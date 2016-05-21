/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct SimpleToastUX {
    static let ToastHeight = CGFloat(50)
    static let ToastAnimationDuration = 0.5
    static let ToastDefaultColor = UIColor(red: 76.0 / 255, green: 158.0 / 255, blue: 255.0 / 255, alpha: 1)
    static let ToastFont = UIFont.systemFontOfSize(14)
    static let ToastDismissAfter = 2.0
}

struct SimpleToast {

     func showAlertWithText(text: String) {
        guard let window = UIApplication.sharedApplication().windows.first,
        let keyboardHeight = KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(window) else {
            return
        }
        let toast = self.createView()
        toast.text = text
        window.addSubview(toast)
        toast.snp_makeConstraints { (make) in
            make.width.equalTo(window.snp_width)
            make.height.equalTo(SimpleToastUX.ToastHeight)
            make.bottom.equalTo(window.snp_bottom).offset(-keyboardHeight)
        }
        animate(toast)
    }

    private func createView() -> UILabel {
        let toast = UILabel()
        toast.textColor = UIColor.whiteColor()
        toast.backgroundColor = SimpleToastUX.ToastDefaultColor
        toast.font = SimpleToastUX.ToastFont
        toast.textAlignment = .Center
        return toast
    }

    private func dismiss(toast: UIView) {
        UIView.animateWithDuration(SimpleToastUX.ToastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y + SimpleToastUX.ToastHeight
                toast.frame = frame
            },
            completion: { finished in
                toast.removeFromSuperview()
            }
        )
    }

    private func animate(toast: UIView) {
        UIView.animateWithDuration(SimpleToastUX.ToastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - SimpleToastUX.ToastHeight
                toast.frame = frame
            },
            completion: { finished in
                let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(SimpleToastUX.ToastDismissAfter * Double(NSEC_PER_SEC)))
                dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                    self.dismiss(toast)
                })
        })
    }


}
