// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// Firefox homepage stories header that fades between the news affordance and section title.
final class NewsTransitionHeaderView: UICollectionReusableView,
                                      ReusableCell,
                                      ThemeApplicable {
    struct UX {
        /// The scroll distance of the homepage over which the headers will crossfade
        static let transitionDistance: CGFloat = 96
    }

    private lazy var newsAffordanceHeaderView: NewsAffordanceHeaderView = .build()
    private lazy var sectionTitleHeaderView: LabelButtonHeaderView = .build()

    private var progress: CGFloat = 0
    private var transitionEnabled = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        updateViewState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progress = 0
        sectionTitleHeaderView.prepareForReuse()
        updateViewState()
    }

    func configure(
        state: SectionHeaderConfiguration,
        textColor: UIColor?,
        theme: Theme,
        transitionEnabled: Bool
    ) {
        self.transitionEnabled = transitionEnabled
        newsAffordanceHeaderView.configure(theme: theme)
        sectionTitleHeaderView.configure(
            state: state,
            moreButtonAction: nil,
            textColor: textColor,
            theme: theme
        )
        sectionTitleHeaderView.moreButton.isHidden = true
        updateViewState()
    }

    func setTransitionProgress(_ progress: CGFloat) {
        self.progress = min(max(progress, 0), 1)
        updateViewState()
    }

    func setTransitionEnabled(_ transitionEnabled: Bool) {
        self.transitionEnabled = transitionEnabled
        updateViewState()
    }

    func applyTheme(theme: Theme) {
        newsAffordanceHeaderView.applyTheme(theme: theme)
        sectionTitleHeaderView.applyTheme(theme: theme)
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let measuredView: UIView = transitionEnabled ? newsAffordanceHeaderView : sectionTitleHeaderView
        return measuredView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }

    private func setupLayout() {
        addSubview(newsAffordanceHeaderView)
        addSubview(sectionTitleHeaderView)

        NSLayoutConstraint.activate([
            newsAffordanceHeaderView.topAnchor.constraint(equalTo: topAnchor),
            newsAffordanceHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newsAffordanceHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newsAffordanceHeaderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            sectionTitleHeaderView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            sectionTitleHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionTitleHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sectionTitleHeaderView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateViewState() {
        if transitionEnabled {
            newsAffordanceHeaderView.alpha = 1 - progress
            newsAffordanceHeaderView.accessibilityElementsHidden = progress >= 0.5

            sectionTitleHeaderView.alpha = progress
            sectionTitleHeaderView.accessibilityElementsHidden = progress < 0.5
        } else {
            newsAffordanceHeaderView.alpha = 0
            newsAffordanceHeaderView.accessibilityElementsHidden = true

            sectionTitleHeaderView.alpha = 1
            sectionTitleHeaderView.accessibilityElementsHidden = false
        }
    }
}
