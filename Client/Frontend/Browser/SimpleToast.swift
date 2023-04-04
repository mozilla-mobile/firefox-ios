// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import UIKit

struct SimpleToastUX {
    static let ToastHeight = BottomToolbarHeight
    static let Offset = CGFloat(12)
    static let Margin = CGFloat(16)
    static let ToastAnimationDuration = 0.5
    static var ToastDefaultColor: UIColor { UIColor.theme.ecosia.quarternaryBackground }
    static let ToastFont = UIFont.preferredFont(forTextStyle: .body)
    static let ToastDismissAfter = DispatchTimeInterval.milliseconds(4500) // 4.5 seconds.
    static let ToastDelayBefore = DispatchTimeInterval.milliseconds(0) // 0 seconds
    static let ToastPrivateModeDelayBefore = DispatchTimeInterval.milliseconds(750)
    static let BottomToolbarHeight = CGFloat(45)
}

class SimpleToast {
    enum AccessoryImage {
        case named(String), view(UIView)
    }
    
    private var toastView: UIView?
    private var dismissAfter: DispatchTimeInterval?

    var onShown: (() -> Void)?
    
    @discardableResult
    func showAlertWithText(
        _ text: String,
        image: AccessoryImage,
        bottomContainer: UIView,
        dismissAfter timeout: DispatchTimeInterval? = SimpleToastUX.ToastDismissAfter,
        bottomInset: CGFloat? = nil
    ) -> SimpleToast {
        let toast = self.createView(text: text, image: image)
        toast.layer.cornerRadius = 10
        toast.layer.masksToBounds = true

        bottomContainer.addSubview(toast)
        toast.snp.makeConstraints { (make) in
            make.left.equalTo(bottomContainer).offset(SimpleToastUX.Margin)
            make.right.equalTo(bottomContainer).offset(-SimpleToastUX.Margin)
            make.height.equalTo(SimpleToastUX.ToastHeight)
            make.bottom.equalTo(bottomContainer).offset(-((bottomInset ?? 0) + SimpleToastUX.Offset))
        }
        toastView = toast
        dismissAfter = timeout
        animate(toast)
        return self
    }

    fileprivate func createView(text: String, image: AccessoryImage) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        stack.layer.cornerRadius = 10
        stack.backgroundColor = SimpleToastUX.ToastDefaultColor

        let toast = UILabel()
        toast.text = text
        toast.numberOfLines = 1
        toast.textColor = UIColor.theme.ecosia.primaryTextInverted
        toast.font = SimpleToastUX.ToastFont
        toast.adjustsFontForContentSizeCategory = true
        toast.adjustsFontSizeToFitWidth = true
        toast.textAlignment = .left
        toast.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let imageView: UIView
        
        switch image {
        case let .named(name):
            imageView = UIImageView(image: .init(named: name)?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = UIColor.theme.ecosia.toastImageTint
            imageView.contentMode = .scaleAspectFit
            imageView.setContentHuggingPriority(.required, for: .horizontal)
        case let .view(view):
            imageView = view
        }

        let leftSpace = UIView()
        leftSpace.widthAnchor.constraint(equalToConstant: 8).isActive = true
        stack.addArrangedSubview(leftSpace)
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(toast)
        let rightSpace = UIView()
        rightSpace.widthAnchor.constraint(equalToConstant: 8).isActive = true
        stack.addArrangedSubview(rightSpace)
        return stack
    }
    
    func dismiss() {
        DispatchQueue.main.async {
            self.toastView.map(self.dismiss)
        }
    }

    fileprivate func dismiss(_ toast: UIView) {
        var frame = toast.frame
        frame.origin.y = frame.origin.y + SimpleToastUX.ToastHeight + SimpleToastUX.Offset

        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration,
            animations: {
                toast.frame = frame
            },
            completion: { [weak self] finished in
                toast.removeFromSuperview()
                self?.toastView = nil
            }
        )
    }

    fileprivate func animate(_ toast: UIView) {
        var start = toast.frame
        start.origin.y = SimpleToastUX.ToastHeight + SimpleToastUX.Offset
        start.size.height = SimpleToastUX.ToastHeight
        toast.frame = start

        var end = toast.frame
        end.origin.y = end.origin.y - SimpleToastUX.ToastHeight - SimpleToastUX.Offset

        UIView.animate(withDuration: SimpleToastUX.ToastAnimationDuration,
            animations: {
                toast.frame = end
            },
            completion: { [weak self] finished in
            guard let dismissAfter = self?.dismissAfter else { return }
                let dispatchTime = DispatchTime.now() + dismissAfter

                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self?.dismiss(toast)
                })
            }
        )
    }
}
