// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

final class FakespotReviewQualityCardView: UIView, Notifiable, ThemeApplicable {
    private struct UX {
        static let contentStackViewSpacing: CGFloat = 16
        static let footerStackViewSpacing: CGFloat = 8
        static let abdfRatingsStackViewSpacing: CGFloat = 8
        static let cRatingStackViewSpacing: CGFloat = 40
        static let headlineStackViewSpacing: CGFloat = 20
        static let labelFontSize: CGFloat = 15
        static let ratingsFooterStackViewInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        static let contentStackViewInsets = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private let aReliabilityScoreView = FakespotReliabilityScoreView(rating: .gradeA)
    private let bReliabilityScoreView = FakespotReliabilityScoreView(rating: .gradeB)
    private let cReliabilityScoreView = FakespotReliabilityScoreView(rating: .gradeC)
    private let dReliabilityScoreView = FakespotReliabilityScoreView(rating: .gradeD)
    private let fReliabilityScoreView = FakespotReliabilityScoreView(rating: .gradeF)

    private lazy var collapsibleContainer: CollapsibleCardView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.contentStackViewInsets
    }

    private lazy var headlineStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.headlineStackViewSpacing
    }

    private lazy var headlineLabel: UILabel = .build { label in
        label.text = .Shopping.ReviewQualityCardHeadlineLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.headlineLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.labelFontSize)
    }

    private lazy var subHeadlineLabel: UILabel = .build { label in
        label.text = .Shopping.ReviewQualityCardSubHeadlineLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.subHeadlineLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.labelFontSize)
    }

    private lazy var ratingsStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .leading
    }

    private lazy var abRatingsStackView: UIStackView = .build { stackView in
        stackView.alignment = .top
        stackView.spacing = UX.abdfRatingsStackViewSpacing
    }

    private lazy var dfRatingsStackView: UIStackView = .build { stackView in
        stackView.alignment = .top
        stackView.distribution = .fillEqually
        stackView.spacing = UX.abdfRatingsStackViewSpacing
    }

    private lazy var abRatingsReliableLabelStackView: UIStackView = .build { stackView in
        stackView.alignment = .top
        stackView.spacing = UX.abdfRatingsStackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.ratingsFooterStackViewInsets
    }

    private lazy var cRatingReliableLabelStackView: UIStackView = .build { stackView in
        stackView.alignment = .top
        stackView.spacing = UX.cRatingStackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.ratingsFooterStackViewInsets
    }

    private lazy var dfRatingsReliableLabelStackView: UIStackView = .build { stackView in
        stackView.alignment = .top
        stackView.spacing = UX.abdfRatingsStackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.ratingsFooterStackViewInsets
    }

    private lazy var reliableReviewsLabel: UILabel = .build { label in
        label.text = .Shopping.ReviewQualityCardReliableReviewsLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.reliableReviewsLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.labelFontSize)
    }

    private lazy var mixReliableReviewsLabel: UILabel = .build { label in
        label.text = .Shopping.ReviewQualityCardMixedReviewsLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.mixedReviewsLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.labelFontSize)
    }

    private lazy var unreliableReviewsLabel: UILabel = .build { label in
        label.text = .Shopping.ReviewQualityCardUnreliableReviewsLabel
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.unreliableReviewsLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.labelFontSize)
    }

    private lazy var footerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.footerStackViewSpacing
        stackView.alignment = .leading
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.ratingsFooterStackViewInsets
    }

    private lazy var adjustedRatingLabel: UILabel = .build { label in
        let text = String.Shopping.ReviewQualityCardAdjustedRatingLabel
        let normalFont = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                size: UX.labelFontSize)
        let boldFont = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: UX.labelFontSize)
        label.attributedText = text.attributedText(boldPartsOfString: ["adjusted rating"],
                                                   initialFont: normalFont,
                                                   boldFont: boldFont)
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.adjustedRatingLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
    }

    private lazy var highlightsLabel: UILabel = .build { label in
        let text = String.Shopping.ReviewQualityCardHighlightsLabel
        let normalFont = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                size: UX.labelFontSize)
        let boldFont = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: UX.labelFontSize)
        label.attributedText = text.attributedText(boldPartsOfString: ["Highlights"],
                                                   initialFont: normalFont,
                                                   boldFont: boldFont)
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.highlightsLabel
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
    }

    private lazy var learnMoreButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.setTitle(.Shopping.ReviewQualityCardLearnMoreButtonTitle, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.ReviewQualityCard.learnMoreButtonTitle
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.buttonEdgeSpacing = 0
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.labelFontSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(collapsibleContainer)

        contentStackView.addArrangedSubview(headlineStackView)
        contentStackView.addArrangedSubview(ratingsStackView)
        ratingsStackView.addArrangedSubview(abRatingsReliableLabelStackView)
        ratingsStackView.addArrangedSubview(cRatingReliableLabelStackView)
        ratingsStackView.addArrangedSubview(dfRatingsReliableLabelStackView)
        contentStackView.addArrangedSubview(footerStackView)
        contentStackView.addArrangedSubview(learnMoreButton)
        headlineStackView.addArrangedSubview(headlineLabel)
        headlineStackView.addArrangedSubview(subHeadlineLabel)

        [aReliabilityScoreView, bReliabilityScoreView].forEach(abRatingsStackView.addArrangedSubview)
        [abRatingsStackView, reliableReviewsLabel].forEach(abRatingsReliableLabelStackView.addArrangedSubview)

        [cReliabilityScoreView, mixReliableReviewsLabel].forEach(cRatingReliableLabelStackView.addArrangedSubview)

        [dReliabilityScoreView, fReliabilityScoreView].forEach(dfRatingsStackView.addArrangedSubview)
        [dfRatingsStackView, unreliableReviewsLabel].forEach(dfRatingsReliableLabelStackView.addArrangedSubview)

        footerStackView.addArrangedSubview(adjustedRatingLabel)
        footerStackView.addArrangedSubview(highlightsLabel)

        NSLayoutConstraint.activate([
            collapsibleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            collapsibleContainer.topAnchor.constraint(equalTo: topAnchor),
            collapsibleContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            collapsibleContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            abRatingsStackView.axis = .vertical
            dfRatingsStackView.axis = .vertical
            abRatingsReliableLabelStackView.spacing = UX.cRatingStackViewSpacing
            dfRatingsReliableLabelStackView.spacing = UX.cRatingStackViewSpacing
        } else {
            abRatingsStackView.axis = .horizontal
            dfRatingsStackView.axis = .horizontal
            abRatingsReliableLabelStackView.spacing = UX.abdfRatingsStackViewSpacing
            dfRatingsReliableLabelStackView.spacing = UX.abdfRatingsStackViewSpacing
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    @objc
    private func didTapLearnMore() {
        // didTapLearnMore will be enabled with task FXIOS-7427
    }

    func configure() {
        let viewModel = CollapsibleCardViewModel(
            contentView: contentStackView,
            cardViewA11yId: AccessibilityIdentifiers.Shopping.ReviewQualityCard.card,
            title: .Shopping.ReviewQualityCardLabelTitle,
            titleA11yId: AccessibilityIdentifiers.Shopping.ReviewQualityCard.title,
            expandButtonA11yId: AccessibilityIdentifiers.Shopping.ReviewQualityCard.expandButton,
            expandButtonA11yLabelExpanded: .Shopping.ReviewQualityCardExpandedAccessibilityLabel,
            expandButtonA11yLabelCollapsed: .Shopping.ReviewQualityCardCollapsedAccessibilityLabel)
        collapsibleContainer.configure(viewModel)
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    // MARK: - Theming System
    func applyTheme(theme: Theme) {
        collapsibleContainer.applyTheme(theme: theme)
        let colors = theme.colors
        learnMoreButton.setTitleColor(colors.textAccent, for: .normal)
        [aReliabilityScoreView, bReliabilityScoreView, cReliabilityScoreView, dReliabilityScoreView, fReliabilityScoreView]
            .forEach { $0.applyTheme(theme: theme) }
    }
}
