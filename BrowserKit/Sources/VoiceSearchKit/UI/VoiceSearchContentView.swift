// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class VoiceSearchContentView: UIView, ThemeApplicable {
    private struct UX {
        static let contentViewHorizontalPadding: CGFloat = 24.0
        static let loadingSearchLabelTopPadding: CGFloat = 32.0
        static let searchResultViewTopPadding: CGFloat = 32.0
        static let animationsDuration: CGFloat = 0.2
        static let speechResultLabelFinalAlpha: CGFloat = 0.3
    }
    private let scrollView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.alwaysBounceVertical = true
    }
    private let contentView: UIView = .build()
    private let speechResultLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.numberOfLines = 0
    }
    private let loadingSearchLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.title2.scaledFont()
        $0.alpha = 0.0
        // MARK: - FXIOS-14720 Add Strings and accessibility IDs
        $0.text = "Searching ..."
    }
    private let searchResultView: SearchResultView = .build {
        $0.alpha = 0.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(speechResultLabel, loadingSearchLabel, searchResultView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                                 constant: UX.contentViewHorizontalPadding),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                  constant: -UX.contentViewHorizontalPadding),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                               constant: -UX.contentViewHorizontalPadding * 2),

            speechResultLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            speechResultLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            speechResultLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            loadingSearchLabel.topAnchor.constraint(equalTo: speechResultLabel.bottomAnchor,
                                                    constant: UX.loadingSearchLabelTopPadding),
            loadingSearchLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            loadingSearchLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            searchResultView.topAnchor.constraint(equalTo: speechResultLabel.bottomAnchor,
                                                  constant: UX.searchResultViewTopPadding),
            searchResultView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchResultView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            searchResultView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
    }

    func setSpeechResult(text: String) {
        speechResultLabel.text = text
        if speechResultLabel.alpha != 1.0 {
            UIView.animate(withDuration: UX.animationsDuration) { [self] in
                speechResultLabel.alpha = 1.0
                loadingSearchLabel.alpha = 0.0
                searchResultView.alpha = 0.0
            }
        }
    }

    func setIsLoadingSearchResult() {
        loadingSearchLabel.transform = .identity.translatedBy(x: 0.0, y: UX.loadingSearchLabelTopPadding)
        UIView.animate(withDuration: UX.animationsDuration) { [self] in
            loadingSearchLabel.alpha = 1.0
            loadingSearchLabel.transform = .identity
        }
    }

    func setSearchResult(title: String, body: String, url: URL?) {
        searchResultView.configure(title: title, body: body)
        searchResultView.transform = .identity.translatedBy(x: 0.0, y: UX.searchResultViewTopPadding)
        loadingSearchLabel.alpha = 0.0
        UIView.animate(withDuration: UX.animationsDuration) { [self] in
            searchResultView.transform = .identity
            searchResultView.alpha = 1.0
            speechResultLabel.alpha = UX.speechResultLabelFinalAlpha
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        speechResultLabel.textColor = theme.colors.textPrimary
        searchResultView.applyTheme(theme: theme)
        scrollView.backgroundColor = .clear
    }
}
