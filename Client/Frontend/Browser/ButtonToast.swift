/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

struct ButtonToastUX {
    static let ToastHeight: CGFloat = 55.0
    static let ToastPadding: CGFloat = 10.0
    static let ToastButtonPadding: CGFloat = 10.0
    static let ToastDelay = DispatchTimeInterval.milliseconds(900)
    static let ToastButtonBorderRadius: CGFloat = 5
    static let ToastButtonBorderWidth: CGFloat = 1
    static let ToastLabelFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    static let ToastDescriptionFont = UIFont.systemFont(ofSize: 13)
}

class ButtonToast: Toast {
    class HighlightableButton: UIButton {
        override var isHighlighted: Bool {
            didSet {
                backgroundColor = isHighlighted ? .white : .clear
            }
        }
    }

    init(labelText: String, descriptionText: String? = nil, imageName: String? = nil, buttonText: String? = nil, backgroundColor: UIColor = SimpleToastUX.ToastDefaultColor, textAlignment: NSTextAlignment = .left, completion: ((_ buttonPressed: Bool) -> Void)? = nil) {
        super.init(frame: .zero)

        self.completionHandler = completion

        self.clipsToBounds = true
        self.addSubview(createView(labelText, descriptionText: descriptionText, imageName: imageName, buttonText: buttonText, textAlignment: textAlignment))

        self.toastView.backgroundColor = backgroundColor

        self.toastView.snp.makeConstraints { make in
            make.left.right.height.equalTo(self)
            self.animationConstraint = make.top.equalTo(self).offset(ButtonToastUX.ToastHeight).constraint
        }

        self.snp.makeConstraints { make in
            make.height.equalTo(ButtonToastUX.ToastHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func createView(_ labelText: String, descriptionText: String?, imageName: String?, buttonText: String?, textAlignment: NSTextAlignment) -> UIView {
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = ButtonToastUX.ToastPadding

        if let imageName = imageName {
            let icon = UIImageView(image: UIImage.templateImageNamed(imageName))
            icon.tintColor = UIColor.Photon.White100
            horizontalStackView.addArrangedSubview(icon)
        }

        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading

        let label = UILabel()
        label.textAlignment = textAlignment
        label.textColor = UIColor.Photon.White100
        label.font = ButtonToastUX.ToastLabelFont
        label.text = labelText
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        labelStackView.addArrangedSubview(label)

        var descriptionLabel: UILabel?
        if let descriptionText = descriptionText {
            label.lineBreakMode = .byClipping
            label.numberOfLines = 1 // if showing a description we cant wrap to the second line
            label.adjustsFontSizeToFitWidth = true

            descriptionLabel = UILabel()
            descriptionLabel?.textAlignment = textAlignment
            descriptionLabel?.textColor = UIColor.Photon.White100
            descriptionLabel?.font = ButtonToastUX.ToastDescriptionFont
            descriptionLabel?.text = descriptionText
            descriptionLabel?.lineBreakMode = .byTruncatingTail
            labelStackView.addArrangedSubview(descriptionLabel!)
        }

        horizontalStackView.addArrangedSubview(labelStackView)

        if let buttonText = buttonText {
            let button = HighlightableButton()
            button.layer.cornerRadius = ButtonToastUX.ToastButtonBorderRadius
            button.layer.borderWidth = ButtonToastUX.ToastButtonBorderWidth
            button.layer.borderColor = UIColor.Photon.White100.cgColor
            button.setTitle(buttonText, for: [])
            button.setTitleColor(toastView.backgroundColor, for: .highlighted)
            button.titleLabel?.font = SimpleToastUX.ToastFont
            button.titleLabel?.numberOfLines = 1
            button.titleLabel?.lineBreakMode = .byClipping
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.1
            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))

            button.snp.makeConstraints { (make) in
                make.width.equalTo(button.titleLabel!.intrinsicContentSize.width + 2 * ButtonToastUX.ToastButtonPadding)
            }

            horizontalStackView.addArrangedSubview(button)
        }

        toastView.addSubview(horizontalStackView)

        if textAlignment == .center {
            label.snp.makeConstraints { make in
                make.centerX.equalTo(toastView)
            }

            descriptionLabel?.snp.makeConstraints { make in
                make.centerX.equalTo(toastView)
            }
        }

        horizontalStackView.snp.makeConstraints { make in
            make.centerX.equalTo(toastView)
            make.centerY.equalTo(toastView)
            make.width.equalTo(toastView.snp.width).offset(-2 * ButtonToastUX.ToastPadding)
        }

        return toastView
    }

    @objc func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        completionHandler?(true)
        dismiss(true)
    }

    override func showToast(viewController: UIViewController? = nil, delay: DispatchTimeInterval = SimpleToastUX.ToastDelayBefore, duration: DispatchTimeInterval? = SimpleToastUX.ToastDismissAfter, makeConstraints: @escaping (SnapKit.ConstraintMaker) -> Swift.Void) {
        super.showToast(viewController: viewController, delay: delay, duration: duration, makeConstraints: makeConstraints)
    }
}
