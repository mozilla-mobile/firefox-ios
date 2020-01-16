/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit

struct ButtonToastUX {
    static let ToastHeight: CGFloat = 55.0
    static let ToastPadding: CGFloat = 15.0
    static let ToastButtonPadding: CGFloat = 10.0
    static let ToastDelay = DispatchTimeInterval.milliseconds(900)
    static let ToastButtonBorderRadius: CGFloat = 5
    static let ToastButtonBorderWidth: CGFloat = 1
    static let ToastLabelFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    static let ToastDescriptionFont = UIFont.systemFont(ofSize: 13)
    
    struct ToastButtonPaddedView {
        static let WidthOffset: CGFloat = 20.0
        static let TopOffset: CGFloat = 5.0
        static let BottomOffset: CGFloat = 20.0
    }
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
        let createdToastView = createView(labelText, descriptionText: descriptionText, imageName: imageName, buttonText: buttonText, textAlignment: textAlignment)
        self.addSubview(createdToastView)

        self.toastView.backgroundColor = backgroundColor

        self.toastView.snp.makeConstraints { make in
            make.left.right.height.equalTo(self)
            self.animationConstraint = make.top.greaterThanOrEqualTo(self).offset(ButtonToastUX.ToastHeight).constraint
        }

        self.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(ButtonToastUX.ToastHeight)
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
        setupPaddedButton(stackView: horizontalStackView, buttonText: buttonText)
        toastView.addSubview(horizontalStackView)

        if textAlignment == .center {
            label.snp.makeConstraints { make in
                make.centerX.equalTo(toastView)
            }

            descriptionLabel?.snp.makeConstraints { make in
                make.centerX.equalTo(toastView)
            }
        }

        labelStackView.snp.makeConstraints { make in
            make.centerY.equalTo(horizontalStackView.snp.centerY)
        }
        
        horizontalStackView.snp.makeConstraints { make in
            make.left.equalTo(toastView.snp.left).offset(ButtonToastUX.ToastPadding)
            make.right.equalTo(toastView.snp.right)
            make.bottom.equalTo(toastView.safeArea.bottom)
            make.top.equalTo(toastView.snp.top)
            make.height.equalTo(ButtonToastUX.ToastHeight)
        }
        return toastView
    }
    
    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }
            
        let paddedView = UIView()
        paddedView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(paddedView)
        paddedView.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.top).offset(ButtonToastUX.ToastButtonPaddedView.TopOffset)
            make.bottom.equalTo(stackView.snp.bottom).offset(ButtonToastUX.ToastButtonPaddedView.BottomOffset)
        }
        
        let roundedButton = HighlightableButton()
        roundedButton.translatesAutoresizingMaskIntoConstraints = false
        roundedButton.layer.cornerRadius = ButtonToastUX.ToastButtonBorderRadius
        roundedButton.layer.borderWidth = ButtonToastUX.ToastButtonBorderWidth
        roundedButton.layer.borderColor = UIColor.Photon.White100.cgColor
        roundedButton.setTitle(buttonText, for: [])
        roundedButton.setTitleColor(toastView.backgroundColor, for: .highlighted)
        roundedButton.titleLabel?.font = SimpleToastUX.ToastFont
        roundedButton.titleLabel?.numberOfLines = 1
        roundedButton.titleLabel?.lineBreakMode = .byClipping
        roundedButton.titleLabel?.adjustsFontSizeToFitWidth = true
        roundedButton.titleLabel?.minimumScaleFactor = 0.1
        paddedView.addSubview(roundedButton)
        roundedButton.snp.makeConstraints { make in
            make.height.equalTo(roundedButton.titleLabel!.intrinsicContentSize.height + 2 * ButtonToastUX.ToastButtonPadding)
            make.width.equalTo(roundedButton.titleLabel!.intrinsicContentSize.width + 2 * ButtonToastUX.ToastButtonPadding)
            make.centerY.centerX.equalToSuperview()
        }
        roundedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
        
        paddedView.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.top)
            make.bottom.equalTo(stackView.snp.bottom)
            make.width.equalTo(roundedButton.snp.width).offset(ButtonToastUX.ToastButtonPaddedView.WidthOffset)
        }
        paddedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
    }

    override func showToast(viewController: UIViewController? = nil, delay: DispatchTimeInterval = SimpleToastUX.ToastDelayBefore, duration: DispatchTimeInterval? = SimpleToastUX.ToastDismissAfter, makeConstraints: @escaping (SnapKit.ConstraintMaker) -> Swift.Void) {
        super.showToast(viewController: viewController, delay: delay, duration: duration, makeConstraints: makeConstraints)
    }
    
    // MARK: - Button action
    @objc func buttonPressed() {
        completionHandler?(true)
        dismiss(true)
    }
}
