// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// Firefox homepage stories header that fades between the news affordance and section title.
final class NewsTransitionHeaderCell: UICollectionReusableView,
                                      ReusableCell,
                                      ThemeApplicable {
    struct UX {
        /// The scroll distance of the homepage over which the headers will crossfade
        static let transitionDistance: CGFloat = 96
        /// Overall header transition progress where the picker starts moving; 0.2 means 20% into the transition.
        static let pickerTranslationStartProgress: CGFloat = 0.2
        static let transitioningZPosition: CGFloat = -1
        static let pinnedZPosition: CGFloat = 1
    }

    private lazy var newsAffordanceHeaderView: NewsAffordanceHeaderView = .build()
    private lazy var sectionTitleHeaderView: LabelButtonHeaderView = .build()
    private lazy var storyCategoryPickerView: StoryCategoryPickerView = .build()
    private lazy var headerContainerView: UIView = .build { view in
        view.isAccessibilityElement = true
        view.accessibilityTraits = .header
    }

    private var headerContainerHeightConstraint: NSLayoutConstraint?
    private var hasCategories = false
    private var progress: CGFloat = 0
    private var transitionEnabled = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        setupLayout()
        updateViewState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progress = 0
        transitionEnabled = true
        hasCategories = false
        sectionTitleHeaderView.prepareForReuse()
        updateViewState()
    }

    /// Report the stable layout height for the header's resting content.
    /// The affordance is treated as an overlay during the transition, so layout only reserves space
    /// for the section title (plus picker when categories are present).
    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let headerSize = sectionTitleHeaderView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
        let pickerSize = storyCategoryPickerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )

        let headerHeight = hasCategories ? headerSize.height + pickerSize.height : headerSize.height
        return CGSize(width: max(headerSize.width, pickerSize.width), height: headerHeight)
    }

    func configure(
        sectionHeaderConfiguration: SectionHeaderConfiguration,
        textColor: UIColor?,
        theme: Theme,
        transitionEnabled: Bool = true,
        categories: [MerinoCategoryConfiguration] = [],
        selectedNewsfeedCategoryID: String? = nil,
        newsfeedCategoryPickerOffsetX: CGFloat? = nil,
        onCategoryPickerScroll: ((CGFloat) -> Void)? = nil,
        onNewsAffordanceTap: (@MainActor () -> Void)? = nil,
        onSelection: (@MainActor @Sendable (String?) -> Void)? = nil
    ) {
        self.transitionEnabled = transitionEnabled
        newsAffordanceHeaderView.applyTheme(theme: theme)
        newsAffordanceHeaderView.configure(onTap: onNewsAffordanceTap)
        sectionTitleHeaderView.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            moreButtonAction: nil,
            textColor: textColor,
            theme: theme
        )
        headerContainerView.accessibilityIdentifier = sectionHeaderConfiguration.a11yIdentifier
        sectionTitleHeaderView.moreButton.isHidden = true
        storyCategoryPickerView.configure(
            categories: categories,
            selectedNewsfeedCategoryID: selectedNewsfeedCategoryID,
            newsfeedCategoryPickerOffsetX: newsfeedCategoryPickerOffsetX,
            onScroll: onCategoryPickerScroll,
            onSelection: onSelection
        )
        storyCategoryPickerView.applyTheme(theme: theme)
        hasCategories = !categories.isEmpty

        updateViewState()
    }

    func setTransitionProgress(_ progress: CGFloat) {
        self.progress = min(max(progress, 0), 1)
        updateViewState()
    }

    func setTransitionEnabled(_ transitionEnabled: Bool) {
        guard self.transitionEnabled != transitionEnabled else { return }
        self.transitionEnabled = transitionEnabled
        updateViewState()
    }

    func updatePickerState(
        selectedNewsfeedCategoryID: String?,
        newsfeedCategoryPickerOffsetX: CGFloat?
    ) {
        storyCategoryPickerView.applyNewsfeedPickerState(
            selectedNewsfeedCategoryID: selectedNewsfeedCategoryID,
            newsfeedCategoryPickerOffsetX: newsfeedCategoryPickerOffsetX
        )
    }

    func applyTheme(theme: Theme) {
        newsAffordanceHeaderView.applyTheme(theme: theme)
        sectionTitleHeaderView.applyTheme(theme: theme)
        storyCategoryPickerView.applyTheme(theme: theme)
    }

    private func setupLayout() {
        headerContainerView.addSubview(newsAffordanceHeaderView)
        headerContainerView.addSubview(sectionTitleHeaderView)

        addSubview(storyCategoryPickerView)
        addSubview(headerContainerView)

        // The crossfading header views are bottom-aligned overlays, so the container needs an explicit
        // measured height instead of relying on intrinsic height from stacked subviews.
        let headerContainerHeightConstraint = headerContainerView.heightAnchor.constraint(equalToConstant: 0)
        headerContainerHeightConstraint.priority = .defaultLow
        self.headerContainerHeightConstraint = headerContainerHeightConstraint

        NSLayoutConstraint.activate([
            headerContainerHeightConstraint,

            storyCategoryPickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            storyCategoryPickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            storyCategoryPickerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            headerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            newsAffordanceHeaderView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            newsAffordanceHeaderView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            newsAffordanceHeaderView.topAnchor.constraint(greaterThanOrEqualTo: headerContainerView.topAnchor),
            newsAffordanceHeaderView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),

            sectionTitleHeaderView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            sectionTitleHeaderView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            sectionTitleHeaderView.topAnchor.constraint(greaterThanOrEqualTo: headerContainerView.topAnchor),
            sectionTitleHeaderView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
        ])
    }

    private func updateViewState() {
        layer.zPosition = transitionEnabled && progress < 1 ? UX.transitioningZPosition : UX.pinnedZPosition

        // Transitioning header + category picker
        if transitionEnabled {
            newsAffordanceHeaderView.alpha = 1 - progress
            sectionTitleHeaderView.alpha = progress

            let pickerProgress = pickerProgress(for: progress)
            headerContainerView.transform = CGAffineTransform(
                translationX: 0,
                y: -pickerTranslationOffset() * pickerProgress
            )
            storyCategoryPickerView.alpha = pickerProgress
            storyCategoryPickerView.transform = CGAffineTransform(
                translationX: 0,
                y: pickerTranslationOffset() * (1 - pickerProgress)
            )

        // Static section title header + category picker
        } else {
            newsAffordanceHeaderView.alpha = 0
            sectionTitleHeaderView.alpha = 1
            headerContainerView.transform = CGAffineTransform(
                translationX: 0,
                y: -pickerTranslationOffset()
            )
            storyCategoryPickerView.alpha = hasCategories ? 1 : 0
            storyCategoryPickerView.transform = .identity
        }

        headerContainerView.accessibilityLabel = transitionEnabled && progress < 0.5
            ? newsAffordanceHeaderView.accessibilityLabel
            : sectionTitleHeaderView.title
        storyCategoryPickerView.accessibilityElementsHidden = !hasCategories
        accessibilityElements = hasCategories ? [headerContainerView, storyCategoryPickerView] : [headerContainerView]
    }

    /// Map the overall scroll progress onto a delayed 0...1 range so the category
    /// picker begins revealing only after the header crossfade has started.
    private func pickerProgress(for progress: CGFloat) -> CGFloat {
        guard hasCategories else { return 0 }

        let start = UX.pickerTranslationStartProgress
        guard progress > start else { return 0 }
        return min(max((progress - start) / (1 - start), 0), 1)
    }

    /// Use the picker's height as the translation distance.
    /// Prefer the real laid-out bounds and falling back to a fitting measurement
    private func pickerTranslationOffset() -> CGFloat {
        guard hasCategories else { return 0 }

        if storyCategoryPickerView.bounds.height > 0 {
            return storyCategoryPickerView.bounds.height
        }

        let targetSize = CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let pickerSize = storyCategoryPickerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return pickerSize.height
    }
}
