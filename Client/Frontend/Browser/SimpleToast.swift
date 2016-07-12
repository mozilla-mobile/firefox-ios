/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct SimpleToastUX {
    static let ToastHeight = CGFloat(50)
    static let ToastAnimationDuration = 0.5
    static let ToastDefaultColor = UIColor(red: 76.0 / 255, green: 158.0 / 255, blue: 255.0 / 255, alpha: 1)
    static let ToastFont = UIFont.systemFont(ofSize: 15)
    static let ToastDismissAfter = 2.0
}

struct SimpleToast {

     func showAlert(withText text: String) {
        guard let window = UIApplication.shared().windows.first,
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
        toast.textColor = UIColor.white()
        toast.backgroundColor = SimpleToastUX.ToastDefaultColor
        toast.font = SimpleToastUX.ToastFont
        toast.textAlignment = .center
        return toast
    }

    private func dismiss(_ toast: UIView) {
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration,
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

    private func animate(_ toast: UIView) {
        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration,
            animations: {
                var frame = toast.frame
                frame.origin.y = frame.origin.y - SimpleToastUX.ToastHeight
                toast.frame = frame
            },
            completion: { finished in
                let dispatchTime = DispatchTime.now() + Double(Int64(SimpleToastUX.ToastDismissAfter * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.after(when: dispatchTime, block: {
                    self.dismiss(toast)
                })
            }
        )
    }
}
