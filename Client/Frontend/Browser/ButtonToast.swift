// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import SnapKit

struct ButtonToastUX {
    static let ToastHeight: CGFloat = 55.0 + ToastOffset
    static let ToastOffset: CGFloat = 16
    static let ToastPadding: CGFloat = 16.0
    static let ToastButtonPadding: CGFloat = 16.0
    static let ToastDelay = DispatchTimeInterval.milliseconds(900)
    static let ToastButtonBorderRadius: CGFloat = 5
    static let ToastButtonBorderWidth: CGFloat = 1
    static let ToastLabelFont = UIFont.preferredFont(forTextStyle: .body)
    static let ToastDescriptionFont = UIFont.preferredFont(forTextStyle: .caption1)
    
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

    init(
        labelText: String,
        descriptionText: String? = nil,
        imageName: String? = nil,
        buttonText: String? = nil,
        backgroundColor: UIColor = SimpleToastUX.ToastDefaultColor,
        textAlignment: NSTextAlignment = .left,
        completion: ((_ buttonPressed: Bool) -> Void)? = nil, autoDismissCompletion: (() -> Void)? = nil
    ) {
        super.init(frame: .zero)

        self.completionHandler = completion
        self.didDismissWithoutTapHandler = autoDismissCompletion

        self.clipsToBounds = true
        let createdToastView = createView(labelText,
                                          descriptionText: descriptionText,
                                          imageName: imageName,
                                          buttonText: buttonText,
                                          textAlignment: textAlignment)
        self.addSubview(createdToastView)

        self.toastView.backgroundColor = .clear

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
        let horizontalStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.layer.cornerRadius = 10
        stackView.backgroundColor = SimpleToastUX.ToastDefaultColor
        }

        if let imageName = imageName {
            let icon = UIImageView(image: UIImage.templateImageNamed(imageName))
            icon.contentMode = .scaleAspectFit
            icon.tintColor = UIColor.theme.ecosia.toastImageTint
            icon.setContentHuggingPriority(.required, for: .horizontal)
            let space = UIView()
            space.widthAnchor.constraint(equalToConstant: 8).isActive = true
            horizontalStackView.addArrangedSubview(space)
            horizontalStackView.addArrangedSubview(icon)
        }
        
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading
        labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let label = UILabel()
        label.textAlignment = textAlignment
        label.textColor = UIColor.theme.ecosia.primaryTextInverted
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.text = labelText
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelStackView.addArrangedSubview(label)

        var descriptionLabel: UILabel?
        if let descriptionText = descriptionText {
            label.lineBreakMode = .byClipping
            label.numberOfLines = 1 // if showing a description we cant wrap to the second line
            label.adjustsFontSizeToFitWidth = true

            descriptionLabel = UILabel()
            descriptionLabel?.textAlignment = textAlignment
            descriptionLabel?.textColor = UIColor.theme.ecosia.primaryTextInverted
            descriptionLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
            descriptionLabel?.text = descriptionText
            descriptionLabel?.lineBreakMode = .byTruncatingTail
            labelStackView.addArrangedSubview(descriptionLabel!)
        }

        horizontalStackView.addArrangedSubview(labelStackView)
        setupPaddedButton(stackView: horizontalStackView, buttonText: buttonText)
        toastView.addSubview(horizontalStackView)

        if textAlignment == .center {
            label.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
            descriptionLabel?.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
        }

        labelStackView.snp.makeConstraints { make in
            make.centerY.equalTo(horizontalStackView.snp.centerY)
        }
        
        horizontalStackView.snp.makeConstraints { make in
            make.left.equalTo(toastView.snp.left).offset(ButtonToastUX.ToastPadding)
            make.right.equalTo(toastView.snp.right).offset(-ButtonToastUX.ToastPadding)
            make.bottom.equalTo(toastView.safeArea.bottom).offset(-ButtonToastUX.ToastOffset)
            make.top.equalTo(toastView.snp.top)
            make.height.equalTo(ButtonToastUX.ToastHeight - ButtonToastUX.ToastOffset)
        }
        return toastView
    }

    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }

        /* Ecosia: branding
        let paddedView = UIView()
        paddedView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(paddedView)
         */
        let roundedButton = UIButton()
        roundedButton.translatesAutoresizingMaskIntoConstraints = false
        /* Ecosia: branding
        roundedButton.layer.cornerRadius = ButtonToastUX.ToastButtonBorderRadius
        roundedButton.layer.borderWidth = ButtonToastUX.ToastButtonBorderWidth
        roundedButton.layer.borderColor = UIColor.Photon.White100.cgColor
         */
        roundedButton.setTitle(buttonText, for: [])
        roundedButton.setTitleColor(UIColor.theme.ecosia.primaryTextInverted, for: .normal)
        roundedButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body).bold()
        roundedButton.titleLabel?.numberOfLines = 1
        roundedButton.titleLabel?.lineBreakMode = .byClipping
        roundedButton.titleLabel?.adjustsFontSizeToFitWidth = true
        roundedButton.titleLabel?.minimumScaleFactor = 0.1
        stackView.addArrangedSubview(roundedButton)
        roundedButton.snp.makeConstraints { make in
            //make.height.equalTo(roundedButton.titleLabel!.intrinsicContentSize.height + 2 * ButtonToastUX.ToastButtonPadding)
            make.width.equalTo(roundedButton.titleLabel!.intrinsicContentSize.width + 2 * ButtonToastUX.ToastButtonPadding)
            //make.centerY.centerX.equalToSuperview()
        }
        roundedButton.addTarget(self, action: #selector(buttonPressed), for: .primaryActionTriggered)
        /* Ecosia: branding
        paddedView.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.top)
            make.bottom.equalTo(stackView.snp.bottom)
            make.width.equalTo(roundedButton.snp.width).offset(ButtonToastUX.ToastButtonPaddedView.WidthOffset)
        }
        paddedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
         */
    }

    override func showToast(viewController: UIViewController? = nil,
                            delay: DispatchTimeInterval = SimpleToastUX.ToastDelayBefore,
                            duration: DispatchTimeInterval? = SimpleToastUX.ToastDismissAfter,
                            updateConstraintsOn: @escaping (Toast) -> [NSLayoutConstraint]) {
        super.showToast(viewController: viewController, delay: delay, duration: duration, updateConstraintsOn: updateConstraintsOn)
    }

    // MARK: - Button action
    @objc func buttonPressed() {
        completionHandler?(true)
        dismiss(true)
    }
}
