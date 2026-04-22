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
    }

    private lazy var newsAffordanceContentView: NewsAffordanceHeaderView = .build()
    private lazy var sectionTitleHeaderView: LabelButtonHeaderView = .build()
    private lazy var storyCategoryPickerView: StoryCategoryPickerView = .build()
    private lazy var sectionTitleStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
    }

    private var progress: CGFloat = 0
    private var transitionEnabled = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityTraits = .header
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
        sectionTitleHeaderView.prepareForReuse()
        updateViewState()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let affordanceSize = newsAffordanceContentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
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
        return CGSize(
            width: affordanceSize.width,
            height: max(affordanceSize.height, headerSize.height + pickerSize.height)
        )
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
        onSelection: (@MainActor @Sendable (String?) -> Void)? = nil
    ) {
        self.transitionEnabled = transitionEnabled
        newsAffordanceContentView.applyTheme(theme: theme)
        sectionTitleHeaderView.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            moreButtonAction: nil,
            textColor: textColor,
            theme: theme
        )
        sectionTitleHeaderView.moreButton.isHidden = true
        storyCategoryPickerView.configure(
            categories: categories,
            selectedNewsfeedCategoryID: selectedNewsfeedCategoryID,
            newsfeedCategoryPickerOffsetX: newsfeedCategoryPickerOffsetX,
            onScroll: onCategoryPickerScroll,
            onSelection: onSelection
        )
        storyCategoryPickerView.applyTheme(theme: theme)

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
        newsAffordanceContentView.applyTheme(theme: theme)
        sectionTitleHeaderView.applyTheme(theme: theme)
        storyCategoryPickerView.applyTheme(theme: theme)
    }

    private func setupLayout() {
        clipsToBounds = false

        sectionTitleStackView.addArrangedSubview(sectionTitleHeaderView)
        sectionTitleStackView.addArrangedSubview(storyCategoryPickerView)

        addSubview(newsAffordanceContentView)
        addSubview(sectionTitleStackView)

        NSLayoutConstraint.activate([
            newsAffordanceContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newsAffordanceContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newsAffordanceContentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            sectionTitleStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionTitleStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sectionTitleStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateViewState() {
        if transitionEnabled {
            newsAffordanceContentView.alpha = 1 - progress
            sectionTitleStackView.alpha = progress
            accessibilityLabel = progress < 0.5
                ? newsAffordanceContentView.accessibilityLabel
                : sectionTitleHeaderView.title
        } else {
            newsAffordanceContentView.alpha = 0
            sectionTitleStackView.alpha = 1
            accessibilityLabel = sectionTitleHeaderView.title
        }
    }
}
