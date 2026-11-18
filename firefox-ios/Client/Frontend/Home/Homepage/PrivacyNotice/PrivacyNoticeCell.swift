// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import ComponentLibrary

/// The privacy notice cell used in the homepage collection view
final class PrivacyNoticeCell: UICollectionViewCell,
                               UITextViewDelegate,
                               ReusableCell,
                               ThemeApplicable {
    enum UX {
        static let cellCornerRadius: CGFloat = 16
        static let cellBorderWidth: CGFloat = 1
        static let bodyLabelVerticalInset: CGFloat = 10
        static let contentHorizontalInset: CGFloat = 16
        static let contentSpacing: CGFloat = 16
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let closeButtonImageSize = CGSize(width: 20, height: 20)
    }

    var logger: Logger = DefaultLogger.shared

    private var closeButtonAction: (() -> Void)?
    private var linkAction: ((URL) -> Void)?

    // MARK: - UI Elements
    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.numberOfLines = 0
        label.text = .FirefoxHomepage.PrivacyNotice.Headline
    }

    private lazy var bodyTextView: UITextView = .build { textView in
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = []
        textView.adjustsFontForContentSizeCategory = true

        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
    }

    private lazy var closeButton: UIButton = .build { button in
        var config = UIButton.Configuration.plain()

        let image = UIImage(named: (StandardImageIdentifiers.Medium.cross))
        let scaledAndTemplatedImage = image?.createScaled(UX.closeButtonImageSize).withRenderingMode(.alwaysTemplate)

        config.image = scaledAndTemplatedImage
        button.configuration = config

        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
    }

    private lazy var learnMoreButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .FirefoxHomepage.PrivacyNotice.LearnMoreLink,
            a11yIdentifier: AccessibilityIdentifiers.TabTray.syncDataButton // todo
        )
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.learnMoreButtonTapped), for: .touchUpInside)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupLayout()
        setupBodyTextViewAttributedString()
    }

    override func layoutSubviews() {
        contentView.layer.cornerRadius = UX.cellCornerRadius
        contentView.layer.borderWidth = UX.cellBorderWidth
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(theme: Theme, closeButtonAction: (() -> Void)?, linkAction: ((URL) -> Void)?) {
        self.closeButtonAction = closeButtonAction
        self.linkAction = linkAction
        applyTheme(theme: theme)
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(bodyTextView)
        contentView.addSubview(learnMoreButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                            constant: UX.contentHorizontalInset),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.contentHorizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                 constant: -UX.contentSpacing),
            titleLabel.bottomAnchor.constraint(equalTo: bodyTextView.topAnchor,
                                               constant: -UX.bodyLabelVerticalInset),

            bodyTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                  constant: UX.contentHorizontalInset),
            bodyTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                   constant: -UX.contentHorizontalInset),
            bodyTextView.bottomAnchor.constraint(equalTo: learnMoreButton.topAnchor,
                                                 constant: -UX.contentHorizontalInset),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                  constant: -UX.contentHorizontalInset),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),

            learnMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                     constant: UX.contentHorizontalInset),
            learnMoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                      constant: -UX.contentHorizontalInset),
            learnMoreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                    constant: -UX.contentHorizontalInset),
        ])
    }

    private func setupBodyTextViewAttributedString() {
        let bodyString = String.FirefoxHomepage.PrivacyNotice.MarkdownBody
        let markdown = String(format: bodyString, AppName.shortName.rawValue)
            .replacingOccurrences(
                of: "PRIVACY_NOTICE_URL",
                with: SupportUtils.URLForUpdatedPrivacyNotice?.absoluteString ?? "#"
            )

        do {
            let attributedString = try NSMutableAttributedString(
                markdown: markdown,
                options: .init(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )
            attributedString.addAttributes([ .font: FXFontStyles.Regular.footnote.scaledFont() ],
                                           range: NSRange(location: 0, length: attributedString.length))
            bodyTextView.attributedText = attributedString
        } catch {
            logger.log(
                "Failed to create attributed string from markdown",
                level: .warning,
                category: .homepage,
                description: "Failed to create attributed string with error: \(error.localizedDescription)"
            )
        }
    }

    @objc
    func closeButtonTapped(_ sender: Any) {
        closeButtonAction?()
    }

    @objc
    func learnMoreButtonTapped(_ sender: Any) {
        guard let url = SupportUtils.URLForUpdatedPrivacyNoticeDiff else { return }
        linkAction?(url)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        contentView.backgroundColor = theme.colors.layer2
        contentView.layer.borderColor = theme.colors.borderPrimary.cgColor
        bodyTextView.textColor = theme.colors.textPrimary
        bodyTextView.linkTextAttributes = [
            .foregroundColor: theme.colors.actionPrimary,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        var config = closeButton.configuration
        config?.baseForegroundColor = theme.colors.iconPrimary
        closeButton.configuration = config
        learnMoreButton.applyTheme(theme: theme)
    }

    // MARK: TextView Delegate

    func textView(_ textView: UITextView,
                  shouldInteractWith url: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return true }
        linkAction?(url)
        return false
    }
}
