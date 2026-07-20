// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class WebCompatLearnMoreFooterView: UICollectionReusableView, UITextViewDelegate {
    private static let linkScheme = "webcompat-learn-more"

    private var tapHandler: (() -> Void)?

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

    func configure(footer: WebCompatReportViewModel.Footer, theme: Theme, onTapLink: @escaping () -> Void) {
        tapHandler = onTapLink
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let attributedText = NSMutableAttributedString(
            string: footer.text,
            attributes: [.font: font, .foregroundColor: theme.colors.textSecondary]
        )
        let linkRange = (footer.text as NSString).range(of: footer.linkText)
        if linkRange.location != NSNotFound,
           let url = URL(string: "\(WebCompatLearnMoreFooterView.linkScheme)://") {
            attributedText.addAttribute(.link, value: url, range: linkRange)
        }
        textView.attributedText = attributedText
        textView.linkTextAttributes = [.foregroundColor: theme.colors.actionPrimary]
    }

    // MARK: - UITextViewDelegate

    func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        tapHandler?()
        return false
    }
}
