/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

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
        toast.backgroundColor = .locationBar
        toast.alpha = 0
        toast.layer.cornerRadius = UIConstants.layout.toastMessageHeight / 2
        window.addSubview(toast)

        let label = SmartLabel()
        label.text = text
        label.textColor = .primaryText
        label.font = .footnote12Semibold
        
        label.numberOfLines = 0
        label.accessibilityIdentifier = "Toast.label"
        toast.addSubview(label)

        toast.snp.makeConstraints { make in
            let topOffset = UIConstants.layout.urlBarHeightInset + (UIConstants.layout.urlBarBorderInset * 2) + UIConstants.layout.urlBarHeight
            make.top.equalTo(window.safeAreaLayoutGuide).offset(topOffset)
            make.centerX.equalTo(window)
            make.leading.greaterThanOrEqualTo(window)
            make.trailing.lessThanOrEqualTo(window)
            make.height.equalTo(UIConstants.layout.toastMessageHeight)
        }

        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(toast).inset(20)
            make.centerY.equalTo(toast)
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
