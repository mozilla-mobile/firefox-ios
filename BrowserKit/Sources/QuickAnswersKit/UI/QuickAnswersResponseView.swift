// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Displays the voice interaction content area for QuickAnswers.
///
/// Manages four visual states that mirror the flow of a voice query:
/// - `idle`: shows a "Ask anything…" placeholder
/// - `recording`: shows live speech transcription as it arrives
/// - `searching`: shows the final transcript and an animated "Searching" indicator
/// - `result`: shows the transcript, the AI answer, and source cards
// TODO: - FXIOS-14720 Add Strings and accessibility ids
final class QuickAnswersResponseView: UIView, ThemeApplicable {
    private struct UX {
        static let contentSpacing: CGFloat = 16.0
        static let animationDuration: TimeInterval = 0.2
    }

    // MARK: - Subviews
    private let scrollView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
    }
    private let contentStack: UIStackView = .build {
        $0.axis = .vertical
        $0.spacing = UX.contentSpacing
    }
    private let placeholderLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.text = "Ask anything…"
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    private let transcriptLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
        $0.isHidden = true
    }
    private let searchingLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.callout.scaledFont()
        $0.text = "Answering…"
        $0.isHidden = true
    }
    private let answerLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.numberOfLines = 0
        $0.isHidden = true
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
        contentStack.addArrangedSubview(placeholderLabel)
        contentStack.addArrangedSubview(transcriptLabel)
        contentStack.addArrangedSubview(searchingLabel)
        contentStack.addArrangedSubview(answerLabel)

        scrollView.addSubview(contentStack)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    // MARK: - Configuration
    func configureTranscript(_ text: String) {
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            transcriptLabel.text = text
            transcriptLabel.isHidden = false
            placeholderLabel.isHidden = true
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        placeholderLabel.textColor = theme.colors.textSecondary
        transcriptLabel.textColor = theme.colors.textPrimary
        searchingLabel.textColor = theme.colors.textSecondary
        answerLabel.textColor = theme.colors.textPrimary
    }
}

@available(iOS 17, *)
#Preview {
    let view = QuickAnswersResponseView()
    view.applyTheme(theme: LightTheme())
    return view
}
