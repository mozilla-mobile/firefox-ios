/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class Toast {
    private let text: String

    init(text: String) {
        self.text = text
    }

    func show() {
        guard let window = UIApplication.shared.windows.first else {
            return
        }

        let toast = UIView()
        toast.alpha = 0
        toast.backgroundColor = UIConstants.colors.toastBackground
        toast.layer.cornerRadius = 18
        window.addSubview(toast)

        let label = UILabel()
        label.text = text
        label.textColor = UIConstants.colors.toastText
        label.font = UIConstants.fonts.toast
        label.numberOfLines = 0
        label.accessibilityIdentifier = "Toast.label"
        toast.addSubview(label)

        toast.snp.makeConstraints { make in
            let bottomOffset = -(KeyboardHelper.defaultHelper.currentState?.intersectionHeightForView(view: window.rootViewController!.view) ?? 0.0)
            make.bottom.equalTo(window).offset(-24 + bottomOffset)
            make.centerX.equalTo(window)
            make.leading.greaterThanOrEqualTo(window)
            make.trailing.lessThanOrEqualTo(window)
        }

        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(toast).inset(20)
            make.top.bottom.equalTo(toast).inset(10)
        }

        toast.animateHidden(false, duration: UIConstants.layout.toastAnimationDuration) {
            DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.layout.toastDuration) {
                toast.animateHidden(true, duration: UIConstants.layout.toastAnimationDuration) {
                    toast.removeFromSuperview()
                }
            }
        }
    }
}
