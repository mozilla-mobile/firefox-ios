/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct SimpleToastUX {
    static let ToastHeight = BottomToolbarHeight
    static let ToastAnimationDuration = 0.5
    static let ToastDefaultColor = UIColor(red: 10 / 255, green: 132 / 255, blue: 255.0 / 255, alpha: 1)
    static let ToastFont = UIFont.systemFont(ofSize: 15)
    static let ToastDismissAfter = DispatchTimeInterval.milliseconds(4500) // 4.5 seconds.
    static let ToastDelayBefore = DispatchTimeInterval.milliseconds(0) // 0 seconds
    static let BottomToolbarHeight = CGFloat(45)
}

struct SimpleToast {

    func showAlertWithText(_ text: String, bottomContainer: UIView) {
        let toast = self.createView()
        toast.text = text
        bottomContainer.addSubview(toast)
        toast.snp.makeConstraints { (make) in
            make.width.equalTo(bottomContainer)
            make.left.equalTo(bottomContainer)
            make.height.equalTo(SimpleToastUX.ToastHeight)
            make.bottom.equalTo(bottomContainer)
        }
        animate(toast)
    }

    fileprivate func createView() -> UILabel {
        let toast = UILabel()
        toast.textColor = UIColor.white
        toast.backgroundColor = SimpleToastUX.ToastDefaultColor
        toast.font = SimpleToastUX.ToastFont
        toast.textAlignment = .center
        return toast
    }

    fileprivate func dismiss(_ toast: UIView) {
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y + SimpleToastUX.ToastHeight
                frame.size.height = 0
                toast.frame = frame
            },
            completion: { finished in
                toast.removeFromSuperview()
            }
        )
    }

    fileprivate func animate(_ toast: UIView) {
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - SimpleToastUX.ToastHeight
                frame.size.height = SimpleToastUX.ToastHeight
                toast.frame = frame
            },
            completion: { finished in
                let dispatchTime = DispatchTime.now() + SimpleToastUX.ToastDismissAfter

                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.dismiss(toast)
                })
            }
        )
    }
}
