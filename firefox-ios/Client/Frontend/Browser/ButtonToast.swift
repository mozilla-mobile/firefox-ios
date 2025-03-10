// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct ButtonToastViewModel {
    var labelText: String
    var descriptionText: String?
    var imageName: String?
    var buttonText: String?
}

class ButtonToast: Toast {
    struct UX {
        static let delay = DispatchTimeInterval.milliseconds(900)
        static let stackViewSpacing: CGFloat = 8
        static let spacing: CGFloat = 8
        static let buttonPadding: CGFloat = 8
        static let buttonBorderRadius: CGFloat = 8
        static let buttonBorderWidth: CGFloat = 1
        static let topBottomButtonPadding: CGFloat = 8
    }

    // MARK: - UI
    private var contentStackView: UIStackView = .build { stackView in
        stackView.spacing = UX.stackViewSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
    }

    private var imageView: UIImageView = .build { imageView in }

    private var labelStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
    }

    private var roundedButton: UIButton = .build { button in
        button.layer.cornerRadius = UX.buttonBorderRadius
        button.layer.borderWidth = UX.buttonBorderWidth
        button.titleLabel?.font = FXFontStyles.Regular.subheadline.scaledFont()
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.1
    }

    // Pass themeManager to call on init
    init(viewModel: ButtonToastViewModel,
         theme: Theme?,
         completion: ((_ buttonPressed: Bool) -> Void)? = nil) {
        super.init(frame: .zero)

        self.completionHandler = completion

        clipsToBounds = true
        let createdToastView = createView(viewModel: viewModel)
        addSubview(createdToastView)

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                               constant: Toast.UX.shadowVerticalSpacing),
            toastView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Toast.UX.shadowVerticalSpacing),
            toastView.heightAnchor.constraint(equalTo: heightAnchor, constant: -Toast.UX.shadowHorizontalSpacing),

            heightAnchor.constraint(greaterThanOrEqualToConstant: Toast.UX.toastHeightWithShadow)
        ])

        animationConstraint = toastView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                                             constant: Toast.UX.toastHeightWithShadow)
        animationConstraint?.isActive = true
        if let theme {
            applyTheme(theme: theme)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createView(viewModel: ButtonToastViewModel) -> UIView {
        if let imageName = viewModel.imageName {
            imageView = UIImageView(image: UIImage.templateImageNamed(imageName))
            contentStackView.addArrangedSubview(imageView)
        }

        titleLabel.text = viewModel.labelText
        labelStackView.addArrangedSubview(titleLabel)
        if let descriptionText = viewModel.descriptionText {
            titleLabel.lineBreakMode = .byClipping
            titleLabel.numberOfLines = 1 // if showing a description we cant wrap to the second line
            titleLabel.adjustsFontSizeToFitWidth = true

            descriptionLabel.text = descriptionText
            labelStackView.addArrangedSubview(descriptionLabel)
        }

        contentStackView.addArrangedSubview(labelStackView)
        toastView.addSubview(contentStackView)
        setupPaddedButton(stackView: contentStackView, buttonText: viewModel.buttonText)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: UX.spacing),
            contentStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -UX.spacing),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: toastView.bottomAnchor, constant: -UX.spacing),
            contentStackView.topAnchor.constraint(equalTo: toastView.topAnchor, constant: UX.spacing),
        ])

        return toastView
    }

    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }

        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.title = buttonText
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(
            top: UX.buttonPadding,
            leading: UX.buttonPadding,
            bottom: UX.buttonPadding,
            trailing: UX.buttonPadding
        )

        roundedButton.configuration = buttonConfiguration

        stackView.addSubview(roundedButton)

        roundedButton.addAction(UIAction { [weak self] _ in
            self?.buttonPressed()
        }, for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Position constraints 
            roundedButton.leadingAnchor.constraint(equalTo: labelStackView.leadingAnchor),
            roundedButton.trailingAnchor.constraint(greaterThanOrEqualTo: toastView.leadingAnchor, constant: -UX.spacing),
            roundedButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: UX.spacing),
            roundedButton.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -UX.spacing)
        ])
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textInverted
        descriptionLabel.textColor = theme.colors.textInverted
        imageView.tintColor = theme.colors.textInverted

        if var buttonConfig = roundedButton.configuration {
            buttonConfig.baseForegroundColor = theme.colors.textInverted
            roundedButton.configuration = buttonConfig
        }

        roundedButton.layer.borderColor = theme.colors.borderInverted.cgColor
    }

    override func adjustLayoutForA11ySizeCategory() {
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byTruncatingTail

        setNeedsLayout()
    }

    // MARK: - Button action
    @objc
    func buttonPressed() {
        completionHandler?(true)
        dismiss(true)
    }
}

@available(iOS 16.0, *)
class PasteControlToast: ButtonToast {
    private var theme: Theme?
    private var pasteControlTarget: UIViewController?

    private lazy var pasteControl: UIPasteControl = {
        let pasteControlConfig = UIPasteControl.Configuration()
        pasteControlConfig.displayMode = .labelOnly
        pasteControlConfig.baseForegroundColor = theme?.colors.textInverted
        pasteControlConfig.baseBackgroundColor = theme?.colors.actionPrimary

        let pasteControl = UIPasteControl(configuration: pasteControlConfig)
        pasteControl.target = pasteControlTarget
        pasteControl.translatesAutoresizingMaskIntoConstraints = false
        pasteControl.layer.borderWidth = UX.buttonBorderWidth
        pasteControl.layer.cornerRadius = UX.buttonBorderRadius

        return pasteControl
    }()

    init(viewModel: ButtonToastViewModel, theme: Theme?, target: UIViewController?) {
        self.theme = theme
        self.pasteControlTarget = target
        super.init(viewModel: viewModel, theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        stackView.addArrangedSubview(pasteControl)
        pasteControl.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        pasteControl.layer.borderColor = theme.colors.borderInverted.cgColor
    }
}
