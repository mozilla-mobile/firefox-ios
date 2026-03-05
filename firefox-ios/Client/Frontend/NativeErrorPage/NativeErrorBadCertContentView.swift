// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary
import Shared

@MainActor
protocol NativeErrorBadCertContentViewDelegate: AnyObject {
    func badCertContentViewDidTapGoBack()
    func badCertContentViewDidTapProceed()
    func badCertContentViewDidTapViewCertificate()
    func badCertContentViewDidTapLearnMore()
}

/// Encapsulates the "bad certificate" action area: an expandable advanced section,
/// a go-back button, and (optionally) a proceed-at-your-own-risk button.
/// The parent view controller swaps this view in when the error is a bad-cert error.
final class NativeErrorBadCertContentView: UIView, ThemeApplicable {
    private struct UX {
        static let borderWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 12
        static let sectionPaddingTop: CGFloat = 11
        static let sectionPaddingBottom: CGFloat = 10
        static let listItemPadding: CGFloat = 6.5
        static let listItemHorizontalPadding: CGFloat = 16
        static let headerHeight: CGFloat = 24
        static let headerTitleChevronGap: CGFloat = 10
        static let chevronSize: CGFloat = 24
        /// Subheading title letter-spacing: -0.0023em (iOS/Bold/Subhead spec).
        static let subheadLetterSpacingEm: CGFloat = -0.0023
        /// List item 4/5: total row 44pt; content padding 6.5 top/bottom → content height 31pt.
        static let linkRowHeight: CGFloat = 31
        static let linkVerticalPadding: CGFloat = 6.5
        static let buttonHeight: CGFloat = 45
        static let proceedContainerPadding: CGFloat = 8
        static let proceedContainerGap: CGFloat = 10
        static let contentSpacing: CGFloat = 16
        /// List Item 6 (error code row): total height 49pt, content padding 6.5 top/bottom.
        static let errorCodeRowHeight: CGFloat = 49
        static let errorCodeVerticalPadding: CGFloat = 6.5
        /// Footnote letter-spacing: -0.0008em (iOS/Regular/Footnote spec).
        static let footnoteLetterSpacingEm: CGFloat = -0.0008
    }

    weak var delegate: NativeErrorBadCertContentViewDelegate?
    private var theme: Theme?
    private var isAdvancedSectionExpanded = false

    // MARK: - UI Elements

    private lazy var mainStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = UX.contentSpacing
    }

    private lazy var advancedSectionContainer: UIView = .build { view in
        view.layer.borderWidth = UX.borderWidth
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var advancedSectionStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
    }

    private lazy var advancedSectionHeader: UIView = .build()

    private lazy var advancedSectionHeaderButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.toggleAdvancedSection), for: .touchUpInside)
        button.accessibilityIdentifier = AccessibilityIdentifiers.NativeErrorPage.advancedSectionHeader
    }

    private lazy var advancedSectionTitleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
    }

    private lazy var advancedSectionChevron: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var advancedSectionContentStack: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
    }

    private lazy var goBackButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapGoBack), for: .touchUpInside)
    }

    private lazy var proceedButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapProceed), for: .touchUpInside)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        mainStack.addArrangedSubview(advancedSectionContainer)
        mainStack.addArrangedSubview(goBackButton)
        goBackButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight).isActive = true

        setupAdvancedSectionLayout()
    }

    private func setupAdvancedSectionLayout() {
        advancedSectionContainer.addSubview(advancedSectionStack)

        advancedSectionHeader.addSubview(advancedSectionHeaderButton)
        advancedSectionHeaderButton.addSubview(advancedSectionTitleLabel)
        advancedSectionHeaderButton.addSubview(advancedSectionChevron)
        let chevronConfig = UIImage.SymbolConfiguration(
            pointSize: UX.chevronSize, weight: .regular
        )
        advancedSectionChevron.image = UIImage(
            systemName: "chevron.right", withConfiguration: chevronConfig
        )

        advancedSectionStack.addArrangedSubview(advancedSectionHeader)
        advancedSectionStack.addArrangedSubview(advancedSectionContentStack)

        let padding = UX.sectionPaddingTop
        let listPadding = UX.listItemHorizontalPadding
        NSLayoutConstraint.activate([
            advancedSectionStack.topAnchor.constraint(
                equalTo: advancedSectionContainer.topAnchor, constant: padding),
            advancedSectionStack.leadingAnchor.constraint(
                equalTo: advancedSectionContainer.leadingAnchor),
            advancedSectionStack.trailingAnchor.constraint(
                equalTo: advancedSectionContainer.trailingAnchor),
            advancedSectionStack.bottomAnchor.constraint(
                equalTo: advancedSectionContainer.bottomAnchor,
                constant: -UX.sectionPaddingBottom),
            advancedSectionHeaderButton.topAnchor.constraint(
                equalTo: advancedSectionHeader.topAnchor),
            advancedSectionHeaderButton.leadingAnchor.constraint(
                equalTo: advancedSectionHeader.leadingAnchor),
            advancedSectionHeaderButton.trailingAnchor.constraint(
                equalTo: advancedSectionHeader.trailingAnchor),
            advancedSectionHeaderButton.bottomAnchor.constraint(
                equalTo: advancedSectionHeader.bottomAnchor),
            advancedSectionHeaderButton.heightAnchor.constraint(
                equalToConstant: UX.headerHeight),
            advancedSectionTitleLabel.leadingAnchor.constraint(
                equalTo: advancedSectionHeaderButton.leadingAnchor, constant: listPadding),
            advancedSectionTitleLabel.centerYAnchor.constraint(
                equalTo: advancedSectionHeaderButton.centerYAnchor),
            advancedSectionTitleLabel.trailingAnchor.constraint(
                equalTo: advancedSectionChevron.leadingAnchor, constant: -UX.headerTitleChevronGap),
            advancedSectionChevron.trailingAnchor.constraint(
                equalTo: advancedSectionHeaderButton.trailingAnchor, constant: -listPadding),
            advancedSectionChevron.centerYAnchor.constraint(
                equalTo: advancedSectionHeaderButton.centerYAnchor),
            advancedSectionChevron.widthAnchor.constraint(
                equalToConstant: UX.chevronSize),
            advancedSectionChevron.heightAnchor.constraint(
                equalToConstant: UX.chevronSize)
        ])
    }

    /// Builds the proceed-button container with horizontal/vertical padding.
    /// The wrapper UIView is needed so we can inset the button within the stack; it uses an explicit
    /// height constraint so the parent stack view allocates the correct amount of space.
    private func makeProceedButtonContainer() -> UIView {
        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(proceedButton)
        let proceedPadding = UX.proceedContainerPadding
        let hPadding = UX.listItemHorizontalPadding
        NSLayoutConstraint.activate([
            proceedButton.topAnchor.constraint(
                equalTo: buttonContainer.topAnchor, constant: proceedPadding),
            proceedButton.leadingAnchor.constraint(
                equalTo: buttonContainer.leadingAnchor, constant: hPadding),
            proceedButton.trailingAnchor.constraint(
                equalTo: buttonContainer.trailingAnchor, constant: -hPadding),
            proceedButton.bottomAnchor.constraint(
                equalTo: buttonContainer.bottomAnchor, constant: -proceedPadding),
            proceedButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            buttonContainer.heightAnchor.constraint(
                equalToConstant: UX.buttonHeight + 2 * proceedPadding
            )
        ])
        return buttonContainer
    }

    private static func truncateHostInMiddle(_ host: String) -> String {
        let prefixCount = 4
        let suffixCount = 9
        let minLengthToTruncate = prefixCount + 3 + suffixCount
        guard host.count > minLengthToTruncate else { return host }
        let prefix = String(host.prefix(prefixCount))
        let suffix = String(host.suffix(suffixCount))
        return prefix + "..." + suffix
    }

    // MARK: - Configuration

    func configure(
        advancedSection: ErrorPageModel.AdvancedSectionConfig,
        url: URL?,
        goBackTitle: String
    ) {
        advancedSectionContentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        advancedSectionTitleLabel.text = isAdvancedSectionExpanded
            ? String.NativeErrorPage.BadCertDomain.HideAdvancedButton
            : advancedSection.buttonText

        let infoParagraph = createParagraph(
            text: advancedSection.infoText,
            highlightedSubstring: url?.absoluteString
        )
        advancedSectionContentStack.addArrangedSubview(infoParagraph)

        let warningParagraph = createParagraph(text: advancedSection.warningText)
        advancedSectionContentStack.addArrangedSubview(warningParagraph)

        let viewCertLink = createLink(
            text: String.NativeErrorPage.BadCertDomain.ViewCertificateLink,
            action: #selector(didTapViewCertificate),
            accessibilityIdentifier: AccessibilityIdentifiers.NativeErrorPage.viewCertificateLink
        )
        advancedSectionContentStack.addArrangedSubview(viewCertLink)

        let learnMoreLink = createLink(
            text: String.NativeErrorPage.BadCertDomain.LearnMoreLink,
            action: #selector(didTapLearnMore),
            accessibilityIdentifier: AccessibilityIdentifiers.NativeErrorPage.learnMoreLink
        )
        advancedSectionContentStack.addArrangedSubview(learnMoreLink)

        if advancedSection.showProceedButton {
            let host = url?.host ?? url?.absoluteString ?? ""
            let displayHost = Self.truncateHostInMiddle(host)
            let proceedTitle = String(
                format: String.NativeErrorPage.BadCertDomain.ProceedButton,
                displayHost
            )
            proceedButton.configure(viewModel: SecondaryRoundedButtonViewModel(
                title: proceedTitle,
                a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.proceedButton
            ))
            proceedButton.isUserInteractionEnabled = true
            proceedButton.isAccessibilityElement = true
            proceedButton.accessibilityElementsHidden = false
            if let theme { proceedButton.applyTheme(theme: theme) }
            proceedButton.isHidden = false

            let buttonContainer = makeProceedButtonContainer()
            advancedSectionContentStack.addArrangedSubview(buttonContainer)
            advancedSectionContentStack.setCustomSpacing(
                UX.proceedContainerGap, after: buttonContainer
            )
        } else {
            proceedButton.isHidden = true
        }

        if let errorCode = advancedSection.certificateErrorCode {
            let errorCodeLabel = createErrorCode(errorCode: errorCode)
            advancedSectionContentStack.addArrangedSubview(errorCodeLabel)
        }

        goBackButton.configure(viewModel: PrimaryRoundedButtonViewModel(
            title: goBackTitle,
            a11yIdentifier: AccessibilityIdentifiers.NativeErrorPage.goBackButton
        ))
        if let theme { goBackButton.applyTheme(theme: theme) }

        advancedSectionContentStack.isHidden = !isAdvancedSectionExpanded
    }

    // MARK: - Actions

    @objc
    private func toggleAdvancedSection() {
        isAdvancedSectionExpanded.toggle()
        advancedSectionTitleLabel.text = isAdvancedSectionExpanded
            ? String.NativeErrorPage.BadCertDomain.HideAdvancedButton
            : String.NativeErrorPage.BadCertDomain.AdvancedButton
        if let theme = theme { applyHeaderTitleTheme(theme: theme) }
        UIView.animate(withDuration: 0.3) {
            self.advancedSectionContentStack.isHidden = !self.isAdvancedSectionExpanded
            self.advancedSectionChevron.transform = self.isAdvancedSectionExpanded
                ? CGAffineTransform(rotationAngle: .pi / 2) : .identity
        }
    }

    @objc
    private func didTapGoBack() {
        delegate?.badCertContentViewDidTapGoBack()
    }

    @objc
    private func didTapProceed() {
        delegate?.badCertContentViewDidTapProceed()
    }

    @objc
    private func didTapViewCertificate() {
        delegate?.badCertContentViewDidTapViewCertificate()
    }

    @objc
    private func didTapLearnMore() {
        delegate?.badCertContentViewDidTapLearnMore()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        self.theme = theme
        goBackButton.applyTheme(theme: theme)
        proceedButton.applyTheme(theme: theme)
        advancedSectionContainer.backgroundColor = theme.colors.layer2
        advancedSectionContainer.layer.borderColor = theme.colors.borderPrimary.cgColor
        applyHeaderTitleTheme(theme: theme)
        advancedSectionChevron.tintColor = theme.colors.actionPrimary
    }

    private func applyHeaderTitleTheme(theme: any Theme) {
        let font = FXFontStyles.Bold.subheadline.scaledFont()
        let kern = UX.subheadLetterSpacingEm * font.pointSize
        let text = advancedSectionTitleLabel.text ?? ""
        advancedSectionTitleLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: theme.colors.textPrimary,
                .kern: kern
            ]
        )
    }

    // MARK: - Content Builders

    private func addListItemPaddingConstraints(
        subview: UIView,
        in container: UIView,
        height: CGFloat? = nil,
        verticalPadding: CGFloat? = nil
    ) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subview)
        let padding = verticalPadding ?? UX.listItemPadding
        let hPadding = UX.listItemHorizontalPadding
        var constraints = [
            subview.topAnchor.constraint(equalTo: container.topAnchor, constant: padding),
            subview.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: hPadding),
            subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -hPadding),
            subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding)
        ]
        if let height {
            constraints.append(subview.heightAnchor.constraint(equalToConstant: height))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func createParagraph(text: String, highlightedSubstring: String? = nil) -> UIView {
        let container = UIView()
        let textColor = theme?.colors.textPrimary ?? .label
        let regularFont = FXFontStyles.Regular.subheadline.scaledFont()
        let boldFont = FXFontStyles.Bold.subheadline.scaledFont()

        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        if let highlight = highlightedSubstring, !highlight.isEmpty, let range = text.range(of: highlight) {
            let nsRange = NSRange(range, in: text)
            let attributed = NSMutableAttributedString(string: text)
            attributed.addAttributes(
                [.font: regularFont, .foregroundColor: textColor],
                range: NSRange(location: 0, length: text.utf16.count)
            )
            attributed.addAttributes(
                [.font: boldFont, .foregroundColor: textColor],
                range: nsRange
            )
            label.attributedText = attributed
        } else {
            label.font = regularFont
            label.textColor = textColor
            label.text = text
        }
        addListItemPaddingConstraints(subview: label, in: container)
        return container
    }

    private func createLink(
        text: String,
        action: Selector,
        accessibilityIdentifier: String? = nil
    ) -> UIView {
        let container = UIView()
        let font = FXFontStyles.Regular.subheadline.scaledFont()

        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = font
        button.setTitleColor(theme?.colors.actionPrimary, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        if let linkColor = theme?.colors.actionPrimary {
            button.setAttributedTitle(
                NSAttributedString(
                    string: text,
                    attributes: [
                        .font: font,
                        .foregroundColor: linkColor,
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ]
                ),
                for: .normal
            )
        }
        if let accessibilityIdentifier { button.accessibilityIdentifier = accessibilityIdentifier }
        addListItemPaddingConstraints(
            subview: button,
            in: container,
            height: UX.linkRowHeight,
            verticalPadding: UX.linkVerticalPadding
        )
        return container
    }

    private func createErrorCode(errorCode: String) -> UIView {
        let container = UIView()
        let font = FXFontStyles.Regular.footnote.scaledFont()
        let textColor = theme?.colors.textPrimary ?? .label
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let dateString = dateFormatter.string(from: Date())
        let errorCodeText = String(
            format: String.NativeErrorPage.BadCertDomain.ErrorCodeLabel, errorCode
        )
        let fullText = "\(errorCodeText)\n\(dateString)"
        let kern = UX.footnoteLetterSpacingEm * font.pointSize

        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(
            string: fullText,
            attributes: [
                .font: font,
                .foregroundColor: textColor,
                .kern: kern
            ]
        )
        addListItemPaddingConstraints(
            subview: label,
            in: container,
            verticalPadding: UX.errorCodeVerticalPadding
        )
        container.heightAnchor.constraint(
            greaterThanOrEqualToConstant: UX.errorCodeRowHeight
        ).isActive = true
        return container
    }
}
