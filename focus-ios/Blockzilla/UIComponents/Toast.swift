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
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.backgroundColor = .locationBar
        toast.alpha = 0
        toast.layer.cornerRadius = UIConstants.layout.toastMessageHeight / 2
        window.addSubview(toast)

        let label = SmartLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = .primaryText
        label.font = .footnote12Semibold

        label.numberOfLines = 0
        label.accessibilityIdentifier = "Toast.label"
        toast.addSubview(label)

        let topOffset = UIConstants.layout.urlBarHeightInset + (UIConstants.layout.urlBarBorderInset * 2) + UIConstants.layout.urlBarHeight

        NSLayoutConstraint.activate([
            toast.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: topOffset),
            toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor),
            toast.heightAnchor.constraint(equalToConstant: UIConstants.layout.toastMessageHeight),

            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: UIConstants.layout.toastLabelOffset),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -UIConstants.layout.toastLabelOffset),
            label.centerYAnchor.constraint(equalTo: toast.centerYAnchor)
        ])

        toast.animateHidden(false, duration: UIConstants.layout.toastAnimationDuration) {
            DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.layout.toastDuration) {
                toast.animateHidden(true, duration: UIConstants.layout.toastAnimationDuration) {
                    toast.removeFromSuperview()
                }
            }
        }
    }
}
