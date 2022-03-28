// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

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

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toastView.heightAnchor.constraint(equalTo: heightAnchor),

            heightAnchor.constraint(greaterThanOrEqualToConstant: ButtonToastUX.ToastHeight)
        ])

        animationConstraint = toastView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: ButtonToastUX.ToastHeight)
        animationConstraint?.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func createView(_ labelText: String, descriptionText: String?, imageName: String?, buttonText: String?, textAlignment: NSTextAlignment) -> UIView {
        let horizontalStackView: UIStackView = .build { stackView in
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = ButtonToastUX.ToastPadding
        }

        if let imageName = imageName {
            let icon = UIImageView(image: UIImage.templateImageNamed(imageName))
            icon.tintColor = UIColor.Photon.White100
            horizontalStackView.addArrangedSubview(icon)
        }

        let labelStackView: UIStackView = .build { stackView in
            stackView.axis = .vertical
            stackView.alignment = .leading
        }

        let titleLabel: UILabel = .build { label in
            label.textAlignment = textAlignment
            label.textColor = UIColor.Photon.White100
            label.font = ButtonToastUX.ToastLabelFont
            label.text = labelText
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
        }

        labelStackView.addArrangedSubview(titleLabel)

        var descriptionLabel: UILabel?
        if let descriptionText = descriptionText {
            titleLabel.lineBreakMode = .byClipping
            titleLabel.numberOfLines = 1 // if showing a description we cant wrap to the second line
            titleLabel.adjustsFontSizeToFitWidth = true

            descriptionLabel = .build { label in
                label.textAlignment = textAlignment
                label.textColor = UIColor.Photon.White100
                label.font = ButtonToastUX.ToastDescriptionFont
                label.text = descriptionText
                label.lineBreakMode = .byTruncatingTail
            }

            labelStackView.addArrangedSubview(descriptionLabel!)
        }

        horizontalStackView.addArrangedSubview(labelStackView)
        setupPaddedButton(stackView: horizontalStackView, buttonText: buttonText)
        toastView.addSubview(horizontalStackView)

        if textAlignment == .center {
            titleLabel.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
            descriptionLabel?.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            labelStackView.centerYAnchor.constraint(equalTo: horizontalStackView.centerYAnchor),

            horizontalStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: ButtonToastUX.ToastPadding),
            horizontalStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: toastView.safeAreaLayoutGuide.bottomAnchor),
            horizontalStackView.topAnchor.constraint(equalTo: toastView.topAnchor),
            horizontalStackView.heightAnchor.constraint(equalToConstant: ButtonToastUX.ToastHeight),
        ])
        return toastView
    }

    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }

        let paddedView = UIView()
        paddedView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(paddedView)

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

        NSLayoutConstraint.activate([
            roundedButton.heightAnchor.constraint(equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.height + 2 * ButtonToastUX.ToastButtonPadding),
            roundedButton.widthAnchor.constraint(equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.width + 2 * ButtonToastUX.ToastButtonPadding),
            roundedButton.centerYAnchor.constraint(equalTo: paddedView.centerYAnchor),
            roundedButton.centerXAnchor.constraint(equalTo: paddedView.centerXAnchor),

            paddedView.topAnchor.constraint(equalTo: stackView.topAnchor),
            paddedView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            paddedView.widthAnchor.constraint(equalTo: roundedButton.widthAnchor, constant: ButtonToastUX.ToastButtonPaddedView.WidthOffset)
        ])

        roundedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))

        paddedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
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
