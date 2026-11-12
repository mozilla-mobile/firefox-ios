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
    enum UX {
        static let delay = DispatchTimeInterval.milliseconds(900)
        static let stackViewSpacing: CGFloat = 8
        static let spacing: CGFloat = 8
        static let buttonPadding: CGFloat = 8
        static let buttonBorderRadius: CGFloat = 8
        static let buttonBorderWidth: CGFloat = 1
        static let topBottomButtonPadding: CGFloat = 8
        static let animationDuration: TimeInterval = 0.3
        static let imageSize: CGFloat = 24
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

    // Accessibility layout: checkmark sits on the same line as the filename (baseline aligned),
    // with the button on the next row, indented to align with the filename's leading edge.
    private var titleRowStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.spacing = UX.stackViewSpacing
    }

    private var buttonContainerView: UIView = .build()

    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
    }

    private var roundedButton: UIButton = .build { button in
        button.layer.cornerRadius = UX.buttonBorderRadius
        button.layer.borderWidth = UX.buttonBorderWidth
        button.titleLabel?.font = FXFontStyles.Regular.subheadline.scaledFont()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.1
    }

    private var hasImage = false
    private var hasDescription = false
    /// The tappable action view added by `setupPaddedButton` (the rounded button, or the
    /// paste control in `PasteControlToast`).
    var actionView: UIView?

    // Pass themeManager to call on init
    init(viewModel: ButtonToastViewModel,
         theme: Theme?,
         completion: (@MainActor (_ buttonPressed: Bool) -> Void)? = nil) {
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
            hasImage = true
            imageView = UIImageView(image: UIImage.templateImageNamed(imageName))
            imageView.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.text = viewModel.labelText
        if let descriptionText = viewModel.descriptionText {
            hasDescription = true
            titleLabel.lineBreakMode = .byClipping
            titleLabel.numberOfLines = 1 // if showing a description we can't wrap to the second line
            titleLabel.adjustsFontSizeToFitWidth = true

            descriptionLabel.text = descriptionText
        }

        setupPaddedButton(stackView: contentStackView, buttonText: viewModel.buttonText)
        toastView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: UX.spacing),
            contentStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -UX.spacing),
            contentStackView.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -UX.spacing),
            contentStackView.topAnchor.constraint(equalTo: toastView.topAnchor, constant: UX.spacing)
        ])
        applyStandardLayout()
        return toastView
    }

    func setupPaddedButton(stackView: UIStackView, buttonText: String?) {
        guard let buttonText = buttonText else { return }

        roundedButton.setTitle(buttonText, for: [])

        NSLayoutConstraint.activate([
            roundedButton.heightAnchor.constraint(
                equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.height + 2 * UX.buttonPadding),
            roundedButton.widthAnchor.constraint(
                equalToConstant: roundedButton.titleLabel!.intrinsicContentSize.width + 2 * UX.buttonPadding)
        ])

        roundedButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        actionView = roundedButton
    }

    // MARK: - Layout

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            adjustLayoutForA11ySizeCategory()
        }
    }

    // The toast's traits are unspecified at init time and traitCollectionDidChange is not
    // reliably called when the toast is added to the hierarchy, so re-evaluate the layout
    // once the toast is attached and has inherited its environment.
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            adjustLayoutForA11ySizeCategory()
        }
    }

    override func adjustLayoutForA11ySizeCategory() {
        let contentSizeCategory = traitCollection.preferredContentSizeCategory == .unspecified
            ? UIApplication.shared.preferredContentSizeCategory
            : traitCollection.preferredContentSizeCategory
        if Self.usesAccessibilityLayout(contentSizeCategory: contentSizeCategory,
                                        horizontalSizeClass: traitCollection.horizontalSizeClass) {
            applyAccessibilityLayout()
        } else {
            applyStandardLayout()
        }

        setNeedsLayout()
    }

    // Decide with the size class (not the device type): compact widths get the stacked
    // accessibility layout, regular widths keep enough room for the single-line layout.
    static func usesAccessibilityLayout(contentSizeCategory: UIContentSizeCategory,
                                        horizontalSizeClass: UIUserInterfaceSizeClass) -> Bool {
        contentSizeCategory.isAccessibilityCategory && horizontalSizeClass == .compact
    }

    private func applyStandardLayout() {
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.distribution = .fill

        if hasImage {
            move(imageView, to: contentStackView, at: 0)
        }
        move(titleLabel, to: labelStackView, at: 0)
        if hasDescription {
            move(descriptionLabel, to: labelStackView, at: 1)
        }
        move(labelStackView, to: contentStackView, at: hasImage ? 1 : 0)
        if let actionView {
            move(actionView, to: contentStackView, at: contentStackView.arrangedSubviews.count)
        }
    }

    private func applyAccessibilityLayout() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .leading
        contentStackView.distribution = .fill

        if hasImage {
            move(imageView, to: titleRowStackView, at: 0)
        }
        move(titleLabel, to: titleRowStackView, at: hasImage ? 1 : 0)
        move(titleRowStackView, to: contentStackView, at: 0)

        if hasDescription {
            move(descriptionLabel, to: contentStackView, at: 1)
        }

        if let actionView {
            buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
            move(actionView, toContainer: buttonContainerView)
            move(buttonContainerView, to: contentStackView, at: contentStackView.arrangedSubviews.count)

            // Indent the button so it aligns with the filename's leading edge.
            let leadingInset = hasImage ? UX.imageSize + UX.stackViewSpacing : 0
            NSLayoutConstraint.activate([
                actionView.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor,
                                                    constant: leadingInset),
                actionView.topAnchor.constraint(equalTo: buttonContainerView.topAnchor),
                actionView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor),
                actionView.trailingAnchor.constraint(lessThanOrEqualTo: buttonContainerView.trailingAnchor)
            ])
        }
    }

    private func move(_ view: UIView, to stackView: UIStackView, at index: Int) {
        if let currentStack = view.superview as? UIStackView {
            currentStack.removeArrangedSubview(view)
        }
        view.removeFromSuperview()
        // The index is computed before the view is removed from its current stack, so
        // clamp it to the post-removal count when re-inserting into the same stack.
        stackView.insertArrangedSubview(view, at: min(index, stackView.arrangedSubviews.count))
    }

    private func move(_ view: UIView, toContainer container: UIView) {
        if let currentStack = view.superview as? UIStackView {
            currentStack.removeArrangedSubview(view)
        }
        view.removeFromSuperview()
        container.addSubview(view)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textInverted
        descriptionLabel.textColor = theme.colors.textInverted
        imageView.tintColor = theme.colors.textInverted
        roundedButton.setTitleColor(theme.isNova ? theme.colors.textToast : theme.colors.textInverted, for: [])
        let borderColor = theme.isNova ? theme.colors.borderAccentToast : theme.colors.borderInverted
        roundedButton.layer.borderColor = borderColor.cgColor
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
        pasteControl.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionView = pasteControl
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        let borderColor = theme.isNova ? theme.colors.borderAccentToast : theme.colors.borderInverted
        pasteControl.layer.borderColor = borderColor.cgColor
    }
}
