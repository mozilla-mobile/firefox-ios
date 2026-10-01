// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class WebCompatLearnMoreFooterView: UICollectionReusableView, ThemeApplicable, ReusableCell, UITextViewDelegate {
    private var tapHandler: ((URL) -> Void)?
    private var footer: WebCompatReportViewModel.Footer?

    private lazy var textView: UITextView = .build { textView in
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textView)
        let margins = layoutMarginsGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: WebCompatReporterUX.Spacing.interItem),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(footer: WebCompatReportViewModel.Footer, onTapLink: @escaping (URL) -> Void) {
        self.footer = footer
        tapHandler = onTapLink
        textView.accessibilityIdentifier = footer.linkA11yIdentifier
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        guard let footer else { return }
        let font = FXFontStyles.Regular.footnote.scaledFont()
        let attributedText = NSMutableAttributedString(
            string: footer.text,
            attributes: [.font: font, .foregroundColor: theme.colors.textSecondary]
        )
        if let linkURL = footer.linkURL {
            let linkRange = (footer.text as NSString).range(of: footer.linkText)
            if linkRange.location != NSNotFound {
                attributedText.addAttribute(.link, value: linkURL, range: linkRange)
            }
        }
        textView.attributedText = attributedText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.actionPrimary]
    }

    // MARK: - UITextViewDelegate

    // The coordinator owns navigation, so hand the tapped URL up rather than
    // letting the text view open it.
    @available(iOS 17.0, *)
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case let .link(url) = textItem.content else { return defaultAction }
        return UIAction { [weak self] _ in self?.tapHandler?(url) }
    }

    // iOS 15/16 fallback; replaced by textView(_:primaryActionFor:) on iOS 17+.
    func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        tapHandler?(url)
        return false
    }
}
