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

    private lazy var newsAffordanceContentView: NewsAffordanceHeaderView = .build()
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
        transitionEnabled = true
        sectionTitleHeaderView.prepareForReuse()
        updateViewState()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        updateViewState()
    }

    func configure(state: SectionHeaderConfiguration, textColor: UIColor?, theme: Theme, transitionEnabled: Bool = true) {
        self.transitionEnabled = transitionEnabled
        newsAffordanceContentView.applyTheme(theme: theme)
        sectionTitleHeaderView.configure(state: state, moreButtonAction: nil, textColor: textColor, theme: theme)
        sectionTitleHeaderView.moreButton.isHidden = true
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

    func applyTheme(theme: Theme) {
        newsAffordanceContentView.applyTheme(theme: theme)
        sectionTitleHeaderView.applyTheme(theme: theme)
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let measuredView: UIView = transitionEnabled ? newsAffordanceContentView : sectionTitleHeaderView
        return measuredView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }

    private func setupLayout() {
        clipsToBounds = true

        addSubview(newsAffordanceContentView)
        addSubview(sectionTitleHeaderView)

        NSLayoutConstraint.activate([
            newsAffordanceContentView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            newsAffordanceContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newsAffordanceContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newsAffordanceContentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            sectionTitleHeaderView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            sectionTitleHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionTitleHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sectionTitleHeaderView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

    }

    private func updateViewState() {
        if transitionEnabled {
            newsAffordanceContentView.alpha = 1 - progress
            newsAffordanceContentView.accessibilityElementsHidden = progress >= 0.5

            sectionTitleHeaderView.alpha = progress
            sectionTitleHeaderView.accessibilityElementsHidden = progress < 0.5
        } else {
            newsAffordanceContentView.alpha = 0
            newsAffordanceContentView.accessibilityElementsHidden = true

            sectionTitleHeaderView.alpha = 1
            sectionTitleHeaderView.accessibilityElementsHidden = false
        }
    }
}
