// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class HighlightableButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .white : .clear
        }
    }
}

struct ButtonToastViewModel {
    var labelText: String
    var descriptionText: String?
    var imageName: String?
    var buttonText: String?
    var backgroundColor: UIColor = ButtonToast.UX.toastDefaultColor
    var textAlignment: NSTextAlignment = .left
}

class ButtonToast: Toast {
    struct UX {
        static let ToastPadding: CGFloat = 15.0
        static let ToastButtonPadding: CGFloat = 10.0
        static let ToastDelay = DispatchTimeInterval.milliseconds(900)
        static let ToastButtonBorderRadius: CGFloat = 5
        static let ToastButtonBorderWidth: CGFloat = 1
        static let descriptionFontSize: CGFloat = 13
        static let toastDefaultColor = UIColor.Photon.Blue40
        // Padded View
        static let WidthOffset: CGFloat = 20.0
        static let TopOffset: CGFloat = 5.0
        static let BottomOffset: CGFloat = 20.0
    }

    // MARK: - UI
    private var horizontalStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.ToastPadding
    }

    private var imageView: UIImageView = .build { imageView in }

    private var labelStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .leading
    }

    private var titleLabel: UILabel = .build { label in
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .body,
                                                                       size: UX.descriptionFontSize)
        label.lineBreakMode = .byTruncatingTail
    }

    private var roundedButton: HighlightableButton = .build { button in
        button.layer.cornerRadius = UX.ToastButtonBorderRadius
        button.layer.borderWidth = UX.ToastButtonBorderWidth
        button.layer.borderColor = UIColor.Photon.White100.cgColor
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                                size: Toast.UX.fontSize)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.1
    }

    // Pass themeManager to call on init
    init(viewModel: ButtonToastViewModel,
         completion: ((_ buttonPressed: Bool) -> Void)? = nil,
         autoDismissCompletion: (() -> Void)? = nil
    ) {
        super.init(frame: .zero)

        self.completionHandler = completion
        self.didDismissWithoutTapHandler = autoDismissCompletion

        self.clipsToBounds = true
        let createdToastView = createView(viewModel: viewModel)
        self.addSubview(createdToastView)

        // TODO: Handle on applyTheme
        self.toastView.backgroundColor = viewModel.backgroundColor

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toastView.heightAnchor.constraint(equalTo: heightAnchor),

            heightAnchor.constraint(greaterThanOrEqualToConstant: Toast.UX.toastHeight)
        ])

        animationConstraint = toastView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                                             constant: Toast.UX.toastHeight)
        animationConstraint?.isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createView(viewModel: ButtonToastViewModel) -> UIView {
        if let imageName = viewModel.imageName {
            imageView = UIImageView(image: UIImage.templateImageNamed(imageName))
            horizontalStackView.addArrangedSubview(imageView)
        }

        titleLabel.textAlignment = viewModel.textAlignment
        titleLabel.text = viewModel.labelText

        labelStackView.addArrangedSubview(titleLabel)

        if let descriptionText = viewModel.descriptionText {
            titleLabel.lineBreakMode = .byClipping
            titleLabel.numberOfLines = 1 // if showing a description we cant wrap to the second line
            titleLabel.adjustsFontSizeToFitWidth = true

            descriptionLabel.textAlignment = viewModel.textAlignment
            descriptionLabel.text = descriptionText
            labelStackView.addArrangedSubview(descriptionLabel)
        }

        horizontalStackView.addArrangedSubview(labelStackView)
        setupPaddedButton(stackView: horizontalStackView, buttonText: viewModel.buttonText)
        toastView.addSubview(horizontalStackView)

        if viewModel.textAlignment == .center {
            titleLabel.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
            descriptionLabel.centerXAnchor.constraint(equalTo: toastView.centerXAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            labelStackView.centerYAnchor.constraint(equalTo: horizontalStackView.centerYAnchor),

            horizontalStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: UX.ToastPadding),
            horizontalStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: toastView.safeAreaLayoutGuide.bottomAnchor),
            horizontalStackView.topAnchor.constraint(equalTo: toastView.topAnchor),
            horizontalStackView.heightAnchor.constraint(equalToConstant: Toast.UX.toastHeight),
        ])
        return toastView
    }

    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }

        let paddedView = UIView()
        paddedView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(paddedView)

        roundedButton.setTitle(buttonText, for: [])
        paddedView.addSubview(roundedButton)

        NSLayoutConstraint.activate([
            roundedButton.heightAnchor.constraint(equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.height + 2 * UX.ToastButtonPadding),
            roundedButton.widthAnchor.constraint(equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.width + 2 * UX.ToastButtonPadding),
            roundedButton.centerYAnchor.constraint(equalTo: paddedView.centerYAnchor),
            roundedButton.centerXAnchor.constraint(equalTo: paddedView.centerXAnchor),

            paddedView.topAnchor.constraint(equalTo: stackView.topAnchor),
            paddedView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            paddedView.widthAnchor.constraint(equalTo: roundedButton.widthAnchor, constant: UX.WidthOffset)
        ])

        roundedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))

        paddedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
    }

    override func applyTheme(theme: Theme) {
        print("YRD apply theme on button toast")

        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor = theme.colors.textPrimary
        imageView.tintColor = theme.colors.iconPrimary
        roundedButton.setTitleColor(theme.colors.actionPrimary, for: .highlighted)
        super.applyTheme(theme: theme)
    }

    // MARK: - Button action
    @objc func buttonPressed() {
        completionHandler?(true)
        dismiss(true)
    }
}
