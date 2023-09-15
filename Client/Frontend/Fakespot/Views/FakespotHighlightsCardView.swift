// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ComponentLibrary
import Common
import UIKit

struct FakespotHighlightsCardViewModel {
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.card
    let title: String = .Shopping.HighlightsCardTitle
    let titleA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.title
    let moreButtonTitle: String = .Shopping.HighlightsCardMoreButtonTitle
    let moreButtonA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.moreButton
    let lessButtonTitle: String = .Shopping.HighlightsCardLessButtonTitle
    let lessButtonA11yId: String = AccessibilityIdentifiers.Shopping.HighlightsCard.lessButton

    let highlights: Highlights

    var highlightGroupViewModels: [FakespotHighlightGroupViewModel] {
        var highlightGroups: [FakespotHighlightGroupViewModel] = []

        if !highlights.price.isEmpty {
            highlightGroups.append(FakespotHighlightGroupViewModel(
                highlightGroup: FakespotHighlightGroup(type: .price, reviews: highlights.price)))
        }

        if !highlights.quality.isEmpty {
            highlightGroups.append(FakespotHighlightGroupViewModel(
                highlightGroup: FakespotHighlightGroup(type: .quality, reviews: highlights.quality)))
        }

        if !highlights.competitiveness.isEmpty {
            highlightGroups.append(FakespotHighlightGroupViewModel(
                highlightGroup: FakespotHighlightGroup(type: .competitiveness, reviews: highlights.competitiveness)))
        }
        return highlightGroups
    }
}

class FakespotHighlightsCardView: UIView, ThemeApplicable {
    private struct UX {
        static let titleFontSize: CGFloat = 17
        static let buttonFontSize: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let contentHorizontalSpace: CGFloat = 8
        static let contentTopSpace: CGFloat = 8
        static let highlightSpacing: CGFloat = 16
        static let highlightStackBottomSpace: CGFloat = 16
    }

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .headline,
            size: UX.titleFontSize)
        label.numberOfLines = 0
    }

    private lazy var highlightStackView: UIStackView = .build { view in
        view.axis = .vertical
        view.spacing = UX.highlightSpacing
    }

    private lazy var moreButton: ActionButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .body,
            size: UX.buttonFontSize,
            weight: .semibold)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.showMoreAction), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private lazy var dividerView: UIView = .build()

    private var highlightGroups: [FakespotHighlightGroupView] = []
    private var viewModel: FakespotHighlightsCardViewModel?
    private var isShowingPreview = true

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: FakespotHighlightsCardViewModel) {
        self.viewModel = viewModel
        let cardModel = ShadowCardViewModel(view: contentView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)

        viewModel.highlightGroupViewModels.forEach { viewModel in
            let highlightGroup: FakespotHighlightGroupView = .build()
            highlightGroup.configure(viewModel: viewModel)
            highlightGroups.append(highlightGroup)
        }
        updateHighlights()

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.titleA11yId

        moreButton.setTitle(viewModel.moreButtonTitle, for: .normal)
        moreButton.accessibilityIdentifier = viewModel.moreButtonA11yId
    }

    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)

        highlightGroups.forEach { $0.applyTheme(theme: theme) }

        titleLabel.textColor = theme.colors.textPrimary
        moreButton.setTitleColor(theme.colors.textOnLight, for: .normal)
        moreButton.backgroundColor = theme.colors.actionSecondary
        dividerView.backgroundColor = theme.colors.borderPrimary
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(highlightStackView)
        contentView.addSubview(dividerView)
        contentView.addSubview(moreButton)
        addSubview(cardContainer)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                constant: UX.contentHorizontalSpace),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.contentTopSpace),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.contentHorizontalSpace),
            titleLabel.bottomAnchor.constraint(equalTo: highlightStackView.topAnchor, constant: -UX.highlightSpacing),

            highlightStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                        constant: UX.contentHorizontalSpace),
            highlightStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                         constant: -UX.contentHorizontalSpace),
            highlightStackView.bottomAnchor.constraint(equalTo: dividerView.topAnchor,
                                                       constant: -UX.highlightStackBottomSpace),

            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: moreButton.topAnchor, constant: -8),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            moreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            moreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            moreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @objc
    private func showMoreAction() {
        guard let viewModel else { return }

        isShowingPreview = !isShowingPreview
        updateHighlights()

        moreButton.setTitle(
            isShowingPreview ? viewModel.moreButtonTitle : viewModel.lessButtonTitle,
            for: .normal)
        moreButton.accessibilityIdentifier = isShowingPreview ? viewModel.moreButtonA11yId : viewModel.lessButtonA11yId

        if !isShowingPreview {
            recordTelemetry()
        }
    }

    private func updateHighlights() {
        highlightStackView.removeAllArrangedViews()

        for (index, group) in highlightGroups.enumerated() {
            guard (isShowingPreview && index == 0) || !isShowingPreview else { return }

            highlightStackView.addArrangedSubview(group)
            group.showPreview(isShowingPreview)
        }
    }

    private func recordTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingRecentReviews)
    }
}
