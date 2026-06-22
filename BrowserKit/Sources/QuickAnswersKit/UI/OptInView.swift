// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

// TODO: - FXIOS-14720 Add Strings and accessibility ids
final class OptInView: UIView, UITextViewDelegate, ThemeApplicable {
    private struct UX {
        static let contentSpacing: CGFloat = 16.0
        static let buttonContentInset = NSDirectionalEdgeInsets(
            top: 13.5,
            leading: 16.0,
            bottom: 13.5,
            trailing: 16.0
        )
        static let descriptionText = """
        Ask a question out loud, and get a short answer from a Firefox partner. \
        We don't store your voice, questions, or answers.
        """
        static let learnMoreText = "Learn more"
        static let learnMoreURL = SupportUtils.URLForTopic("quick-answer-mobile")
    }

    var onContinue: (() -> Void)?
    var onLearnMore: ((URL) -> Void)?

    // MARK: - Subviews
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.headline.scaledFont()
        $0.text = "Ask With Your Voice"
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.adjustsFontForContentSizeCategory = true
    }
    private lazy var descriptionTextView: UITextView = .build {
        $0.isScrollEnabled = false
        $0.isEditable = false
        $0.textContainerInset = .zero
        $0.adjustsFontForContentSizeCategory = true
        $0.delegate = self
    }
    private lazy var continueButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.contentInsets = UX.buttonContentInset
        $0.configuration?.title = "Continue"
        $0.addAction(UIAction { [weak self] _ in self?.onContinue?() }, for: .touchUpInside)
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupSubviews() {
        addSubviews(titleLabel, descriptionTextView, continueButton)
        descriptionTextView.attributedText = makeDescriptionText()

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            descriptionTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.contentSpacing),
            descriptionTextView.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: trailingAnchor),

            continueButton.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: UX.contentSpacing),
            continueButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            continueButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            continueButton.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            continueButton.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func makeDescriptionText() -> NSAttributedString {
        let font = FXFontStyles.Regular.subheadline.scaledFont()
        let text = NSMutableAttributedString(
            string: UX.descriptionText + " ",
            attributes: [.font: font]
        )
        var linkAttributes: [NSAttributedString.Key: Any] = [.font: font]
        if let learnMoreURL = UX.learnMoreURL {
            linkAttributes[.link] = learnMoreURL
        }
        text.append(NSAttributedString(string: UX.learnMoreText, attributes: linkAttributes))
        return text
    }

    // MARK: - UITextViewDelegate
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        onLearnMore?(URL)
        return false
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.textColor = theme.colors.textSecondary
        descriptionTextView.linkTextAttributes = [
            .foregroundColor: theme.colors.textAccent,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        continueButton.configuration?.baseBackgroundColor = theme.colors.actionPrimary
        continueButton.configuration?.baseForegroundColor = theme.colors.textInverted
    }
}
