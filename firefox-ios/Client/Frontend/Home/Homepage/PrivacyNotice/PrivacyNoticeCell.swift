// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// The privacy notice cell used in the homepage collection view
final class PrivacyNoticeCell: UICollectionViewCell,
                               UITextViewDelegate,
                               ReusableCell,
                               ThemeApplicable {
    struct UX {
        static let cellCornerRadius: CGFloat = 16
        static let cellBorderWidth: CGFloat = 1
        static let bodyLabelVerticalInset: CGFloat = 10
        static let contentHorizontalInset: CGFloat = 16
        static let contentSpacing: CGFloat = 4
        static let closeButtonSize = CGSize(width: 30, height: 30)
        static let closeButtonImageSize = CGSize(width: 20, height: 20)
    }

    private var closeButtonAction: (() -> Void)?
    private var linkAction: ((URL) -> Void)?

    // MARK: - UI Elements

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
        contentView.addSubview(bodyTextView)
        contentView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            bodyTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.bodyLabelVerticalInset),
            bodyTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.contentHorizontalInset),
            bodyTextView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -UX.contentSpacing),
            bodyTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.bodyLabelVerticalInset),

            closeButton.centerYAnchor.constraint(equalTo: bodyTextView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                  constant: -UX.contentHorizontalInset),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
        ])
    }

    private func setupBodyTextViewAttributedString() {
        let bodyString = String.FirefoxHomepage.PrivacyNotice.Body
        let privacyNoticeString = String.FirefoxHomepage.PrivacyNotice.PrivacyNoticeLink
        let learnMoreString = String.FirefoxHomepage.PrivacyNotice.LearnMoreLink
        let fullText = String(format: bodyString, privacyNoticeString, AppName.shortName.rawValue, learnMoreString)
        let attributedString = NSMutableAttributedString(string: fullText)

        attributedString.addAttributes([
            .font: FXFontStyles.Regular.footnote.scaledFont(),
        ], range: NSRange(location: 0, length: attributedString.length))

        if let updatedPrivacyNoticeUrl = SupportUtils.URLForUpdatedPrivacyNotice,
           let updatedPrivacyNoticeDiffUrl = SupportUtils.URLForUpdatedPrivacyNoticeDiff {
            let privacyNoticeLinkRange = (fullText as NSString).range(of: .FirefoxHomepage.PrivacyNotice.PrivacyNoticeLink)
            attributedString.addAttribute(.link, value: updatedPrivacyNoticeUrl, range: privacyNoticeLinkRange)

            let learnMoreLinkRange = (fullText as NSString).range(of: .FirefoxHomepage.PrivacyNotice.LearnMoreLink)
            attributedString.addAttribute(.link, value: updatedPrivacyNoticeDiffUrl, range: learnMoreLinkRange)
        }

        bodyTextView.attributedText = attributedString
    }

    @objc
    func closeButtonTapped(_ sender: Any) {
        closeButtonAction?()
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
