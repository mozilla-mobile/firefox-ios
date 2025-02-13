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
            toastView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Toast.UX.shadowVerticalSpacing),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Toast.UX.shadowVerticalSpacing),
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
        setupPaddedButton(stackView: contentStackView, buttonText: viewModel.buttonText)
        toastView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: UX.spacing),
            contentStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -UX.spacing),
            contentStackView.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -UX.spacing),
            contentStackView.topAnchor.constraint(equalTo: toastView.topAnchor, constant: UX.spacing)
        ])
        return toastView
    }

    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }

        stackView.addArrangedSubview(roundedButton)
        roundedButton.setTitle(buttonText, for: [])

        NSLayoutConstraint.activate([
            roundedButton.heightAnchor.constraint(
                equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.height + 2 * UX.buttonPadding),
            roundedButton.widthAnchor.constraint(
                equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.width + 2 * UX.buttonPadding)
        ])

        roundedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textInverted
        descriptionLabel.textColor = theme.colors.textInverted
        imageView.tintColor = theme.colors.textInverted
        roundedButton.setTitleColor(theme.colors.textInverted, for: [])
        roundedButton.layer.borderColor = theme.colors.borderInverted.cgColor
    }

    override func adjustLayoutForA11ySizeCategory() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        if contentSizeCategory.isAccessibilityCategory {
            contentStackView.axis = .vertical
            contentStackView.alignment = .leading
            contentStackView.distribution = .fillProportionally
        } else {
            contentStackView.axis = .horizontal
            contentStackView.alignment = .center
            contentStackView.distribution = .fill
        }

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
