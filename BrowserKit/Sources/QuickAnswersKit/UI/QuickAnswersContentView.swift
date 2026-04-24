// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// TODO: - FXIOS-14720 Add Strings and accessibility ids
final class QuickAnswersContentView: UIView, ThemeApplicable {
    private struct UX {
        static let contentSpacing: CGFloat = 32.0
        static let animationDuration: TimeInterval = 0.2
    }

    // MARK: - Subviews
    private let scrollView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
        $0.clipsToBounds = false
    }
    private let contentView: UIView = .build()
    private let placeholderLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.text = "Ask anything…"
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.adjustsFontForContentSizeCategory = true
    }
    private let transcriptLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let searchingLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.callout.scaledFont()
        $0.text = "Answering…"
        $0.alpha = 0.0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let answerLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.numberOfLines = 0
        $0.alpha = 0.0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let sourceView: QuickAnswersSourceView = .build {
        $0.alpha = 0.0
    }
    private var theme: Theme?

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
        contentView.addSubviews(placeholderLabel, transcriptLabel, searchingLabel, answerLabel, sourceView)
        scrollView.addSubview(contentView)
        addSubview(scrollView)

        scrollView.pinToSuperview()
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            placeholderLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            transcriptLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            transcriptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            transcriptLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            searchingLabel.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: UX.contentSpacing),
            searchingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            answerLabel.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: UX.contentSpacing),
            answerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            answerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            sourceView.topAnchor.constraint(equalTo: answerLabel.bottomAnchor, constant: UX.contentSpacing),
            sourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sourceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sourceView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Configuration
    func adjustBottomInsets(for height: CGFloat) {
        scrollView.contentInset.bottom = height
    }

    func configureTranscript(_ text: String) {
        // if the placeholder is visible then hide it before adding text to the transcription label.
        // This is needed to don't overlap the show of the transcription with the placeholder label
        guard placeholderLabel.alpha == 1.0 else {
            UIView.transition(
                with: transcriptLabel,
                duration: UX.animationDuration,
                options: .transitionCrossDissolve
            ) { [self] in
                transcriptLabel.text = text
            }
            return
        }
        transcriptLabel.text = text
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            placeholderLabel.alpha = 0.0
        }
    }

    func configureSearching() {
        if let theme {
            searchingLabel.startShimmering(
                light: theme.colors.textDisabled,
                dark: theme.colors.textPrimary
            )
        }
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            searchingLabel.alpha = 1.0
        }
    }

    func configureAnswer(_ text: String) {
        searchingLabel.stopShimmering()
        searchingLabel.alpha = 0.0
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            answerLabel.text = text
            answerLabel.alpha = 1.0
        }
    }

    func configureSources(_ items: [QuickAnswersSourceCell.Item]) {
        sourceView.configure(with: items)
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            sourceView.alpha = 1.0
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        placeholderLabel.textColor = theme.colors.textSecondary
        transcriptLabel.textColor = theme.colors.textPrimary
        searchingLabel.textColor = theme.colors.textSecondary
        answerLabel.textColor = theme.colors.textPrimary
        sourceView.applyTheme(theme: theme)
    }
}
