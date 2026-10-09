// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class QuickAnswersContentView: UIView, ThemeApplicable {
    private struct UX {
        static let contentSpacing: CGFloat = 32.0
        static let searchLabelTopPadding: CGFloat = 24.0
        static let animationDuration: TimeInterval = 0.2
        static let audioWaveformSize = CGSize(width: 18.0, height: 25.0)
        /// The vertical space the waveform and its spacing leave behind.
        static let resultTranslationOffset = audioWaveformSize.height + contentSpacing
        /// How far below their final position the result sections start before cascading in.
        static let resultCascadeOffset: CGFloat = 30.0
        static let resultSlideDuration: TimeInterval = 0.25
        static let resultCascadeDuration: TimeInterval = 0.3
        /// The sections start settling shortly after the transcript begins moving up.
        static let resultCascadeStartDelay: TimeInterval = 0.1
        static let resultCascadeStagger: TimeInterval = 0.1
        static let presentationSlideOffset: CGFloat = 15.0
    }

    // MARK: - Subviews
    private let scrollView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
        $0.clipsToBounds = false
    }
    private let contentView: UIView = .build()
    private let audioWaveform: AudioWaveformView = .build()
    private let placeholderLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.adjustsFontForContentSizeCategory = true
    }
    private let transcriptLabel: TranscriptLabel = .build {
        $0.font = FXFontStyles.Bold.title1.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let searchingLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.subheadline.scaledFont()
        $0.alpha = 0.0
        $0.textAlignment = .center
        $0.adjustsFontForContentSizeCategory = true
    }
    private let answerCardView: QuickAnswersAnswerCardView = .build {
        $0.alpha = 0.0
    }
    private let sourceView: QuickAnswersSourceView = .build {
        $0.alpha = 0.0
    }
    private let footerLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.footnote.scaledFont()
        $0.numberOfLines = 0
        $0.alpha = 0.0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let optInView: OptInView = .build()
    private var theme: Theme?
    private var strings: QuickAnswersViewConfiguration.ContentViewStrings?

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
        contentView.addSubviews(
            audioWaveform,
            placeholderLabel,
            transcriptLabel,
            searchingLabel,
            answerCardView,
            sourceView,
            footerLabel
        )
        scrollView.addSubview(contentView)
        addSubview(scrollView)

        scrollView.pinToSuperview()
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            audioWaveform.topAnchor.constraint(equalTo: contentView.topAnchor),
            audioWaveform.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            audioWaveform.widthAnchor.constraint(equalToConstant: UX.audioWaveformSize.width),
            audioWaveform.heightAnchor.constraint(equalToConstant: UX.audioWaveformSize.height),

            placeholderLabel.topAnchor.constraint(equalTo: audioWaveform.bottomAnchor, constant: UX.contentSpacing),
            placeholderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            transcriptLabel.topAnchor.constraint(equalTo: audioWaveform.bottomAnchor, constant: UX.contentSpacing),
            transcriptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            transcriptLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            searchingLabel.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: UX.searchLabelTopPadding),
            searchingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            answerCardView.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: UX.contentSpacing),
            answerCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            answerCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            sourceView.topAnchor.constraint(equalTo: answerCardView.bottomAnchor, constant: UX.contentSpacing),
            sourceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sourceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            footerLabel.topAnchor.constraint(equalTo: sourceView.bottomAnchor, constant: UX.contentSpacing),
            footerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Configuration
    func configureStrings(_ strings: QuickAnswersViewConfiguration.ContentViewStrings) {
        self.strings = strings
        placeholderLabel.text = strings.placeholder
        searchingLabel.text = strings.answering
        sourceView.configureStrings(sourcesHeader: strings.sources)
    }

    func startAudioWaveformAnimation() {
        audioWaveform.startAnimating()
    }

    func configureOptIn(
        strings: QuickAnswersViewConfiguration.OptInStrings,
        learnMoreURL: URL?,
        theme: Theme,
        onContinue: @escaping () -> Void,
        onLearnMore: @escaping (URL) -> Void
    ) {
        optInView.configure(
            strings: strings,
            learnMoreURL: learnMoreURL,
            theme: theme,
            onContinue: onContinue,
            onLearnMore: onLearnMore
        )
    }

    func showOptIn() {
        contentView.addSubview(optInView)
        optInView.pinToSuperview()
        placeholderLabel.alpha = 0.0
        audioWaveform.alpha = 0.0
    }

    func hideOptIn() {
        UIView.animate(withDuration: UX.animationDuration) {
            self.optInView.alpha = 0.0
            self.placeholderLabel.alpha = 1.0
            self.audioWaveform.alpha = 1.0
        } completion: { [weak self] _ in
            self?.optInView.removeFromSuperview()
            self?.audioWaveform.startAnimating()
        }
    }

    func configureTranscript(_ text: String) {
        // if the placeholder is visible then hide it before adding text to the transcription label.
        // This is needed to don't overlap the show of the transcription with the placeholder label
        guard placeholderLabel.alpha == 1.0 else {
            transcriptLabel.setTranscript(text, animated: true)
            return
        }
        transcriptLabel.setTranscript(text, animated: true)
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            placeholderLabel.alpha = 0.0
        }
    }

    func configureSearching() {
        audioWaveform.stopAnimating()
        if let theme {
            searchingLabel.startShimmering(
                light: theme.colors.textPrimary.withAlphaComponent(0.2),
                dark: theme.colors.textPrimary
            )
            applyColorToTranscript(theme.colors.textSecondary.withAlphaComponent(0.7))
        }
        UIView.animate(withDuration: UX.animationDuration) { [self] in
            searchingLabel.alpha = 1.0
        }
    }
    
    private func applyColorToTranscript(_ color: UIColor) {
        transcriptLabel.foregroundColor = color
        transcriptLabel.setTranscript(transcriptLabel.attributedText?.string ?? "", animated: false)
    }

    func configureResult(
        _ text: String,
        modelName: String,
        sources: [SearchResult.Source],
        onSourceTapped: @escaping (URL) -> Void
    ) {
        if let theme {
            applyColorToTranscript(theme.colors.textPrimary)
        }
        searchingLabel.stopShimmering()
        searchingLabel.alpha = 0.0
        answerCardView.configure(header: strings?.answerHeader ?? "", body: text)
        footerLabel.text = String(format: strings?.footerFormat ?? "", modelName)
        sourceView.configure(with: sources, onSourceTapped: onSourceTapped)
        animateResultCascade()
    }

    // MARK: - Presentation transition
    func prepareForPresentationTransition(sourceRect: CGRect) {
        audioWaveform.alpha = 1.0
        audioWaveform.transform = CGAffineTransform(
            translationX: sourceRect.midX - 201.0,
            y: 32 + 25 + 62 - sourceRect.midY - 50
        )
        placeholderLabel.alpha = 0.0
        placeholderLabel.transform = CGAffineTransform(translationX: 0.0, y: UX.presentationSlideOffset)
    }

    func applyPresentationTransition(isOptInVisible: Bool) {
        audioWaveform.transform = .identity
        audioWaveform.alpha = isOptInVisible ? 0.0 : 1.0
        placeholderLabel.alpha = isOptInVisible ? 0.0 : 1.0
        placeholderLabel.transform = .identity
    }

    // MARK: - Result animation
    private func animateResultCascade() {
        let cascadingSections: [UIView] = [answerCardView, sourceView, footerLabel]
        let finalTransform = CGAffineTransform(translationX: 0.0, y: -UX.resultTranslationOffset)
        let cascadeStartTransform = finalTransform.translatedBy(x: 0.0, y: UX.resultCascadeOffset)

        UIView.animate(withDuration: UX.resultSlideDuration, delay: 0.0, options: .curveEaseInOut) { [self] in
            transcriptLabel.transform = finalTransform
            cascadingSections.forEach { $0.transform = cascadeStartTransform }
            audioWaveform.alpha = 0.0
        }

        for (index, section) in cascadingSections.enumerated() {
            let delay = UX.resultCascadeStartDelay + Double(index) * UX.resultCascadeStagger
            UIView.animate(withDuration: UX.resultCascadeDuration, delay: delay, options: .curveEaseOut) {
                section.transform = finalTransform
                section.alpha = 1.0
            }
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        audioWaveform.applyTheme(theme: theme)
        placeholderLabel.textColor = theme.colors.textSecondary
        transcriptLabel.foregroundColor = theme.colors.textPrimary
        searchingLabel.textColor = theme.colors.textSecondary
        answerCardView.applyTheme(theme: theme)
        footerLabel.textColor = theme.colors.textSecondary
        sourceView.applyTheme(theme: theme)
        optInView.applyTheme(theme: theme)
    }
}
