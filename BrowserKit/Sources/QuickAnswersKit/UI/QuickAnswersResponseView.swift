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
final class QuickAnswersResponseView: UIView, ThemeApplicable {
    enum State {
        case idle
        case recording(transcript: String)
        case searching(transcript: String)
        case result(transcript: String, answer: String, sources: [SourceCardView.Item])
    }

    private struct UX {
        static let transcriptFontSize: CGFloat = 22.0
        static let answerFontSize: CGFloat = 16.0
        static let contentSpacing: CGFloat = 16.0
        static let animationDuration: TimeInterval = 0.2
        static let searchingPulseDuration: CFTimeInterval = 0.8
        static let searchingPulseMinOpacity: Float = 0.3
        static let searchingAnimationKey = "searchingPulse"
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
        $0.font = .systemFont(ofSize: UX.transcriptFontSize, weight: .medium)
        $0.text = "Ask anything…" // TODO: Localize
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    private let transcriptLabel: UILabel = .build {
        $0.font = .systemFont(ofSize: UX.transcriptFontSize, weight: .medium)
        $0.numberOfLines = 0
        $0.isHidden = true
    }
    private let searchingLabel: UILabel = .build {
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.text = "Searching…" // TODO: Localize
        $0.isHidden = true
    }
    private let answerLabel: UILabel = .build {
        $0.font = .systemFont(ofSize: UX.answerFontSize)
        $0.numberOfLines = 0
        $0.isHidden = true
    }
    private let sourcesView: QuickAnswersSourcesView = .build {
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
        contentStack.addArrangedSubview(sourcesView)

        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

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

    func configure(state: State) {
        UIView.animate(withDuration: UX.animationDuration) {
            switch state {
            case .idle:
                self.placeholderLabel.isHidden = false
                self.transcriptLabel.isHidden = true
                self.searchingLabel.isHidden = true
                self.answerLabel.isHidden = true
                self.sourcesView.isHidden = true
                self.stopSearchingAnimation()

            case .recording(let transcript):
                let hasTranscript = !transcript.isEmpty
                self.placeholderLabel.isHidden = hasTranscript
                self.transcriptLabel.text = transcript
                self.transcriptLabel.isHidden = !hasTranscript
                self.searchingLabel.isHidden = true
                self.answerLabel.isHidden = true
                self.sourcesView.isHidden = true
                self.stopSearchingAnimation()

            case .searching(let transcript):
                self.placeholderLabel.isHidden = true
                self.transcriptLabel.text = transcript
                self.transcriptLabel.isHidden = false
                self.searchingLabel.isHidden = false
                self.answerLabel.isHidden = true
                self.sourcesView.isHidden = true
                self.startSearchingAnimation()

            case .result(let transcript, let answer, let sources):
                self.placeholderLabel.isHidden = true
                self.transcriptLabel.text = transcript
                self.transcriptLabel.isHidden = false
                self.searchingLabel.isHidden = true
                self.answerLabel.text = answer
                self.answerLabel.isHidden = answer.isEmpty
                self.sourcesView.configure(with: sources)
                self.sourcesView.isHidden = sources.isEmpty
                self.stopSearchingAnimation()
            }
        }
    }

    // MARK: - Searching animation

    private func startSearchingAnimation() {
        guard searchingLabel.layer.animation(forKey: UX.searchingAnimationKey) == nil else { return }
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1.0
        pulse.toValue = UX.searchingPulseMinOpacity
        pulse.duration = UX.searchingPulseDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        searchingLabel.layer.add(pulse, forKey: UX.searchingAnimationKey)
    }

    private func stopSearchingAnimation() {
        searchingLabel.layer.removeAnimation(forKey: UX.searchingAnimationKey)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        placeholderLabel.textColor = theme.colors.textSecondary
        transcriptLabel.textColor = theme.colors.textPrimary
        searchingLabel.textColor = theme.colors.textSecondary
        answerLabel.textColor = theme.colors.textPrimary
        sourcesView.applyTheme(theme: theme)
    }
}
