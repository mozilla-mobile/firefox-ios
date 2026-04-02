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
    private lazy var sectionTitleHeaderView: LabelButtonHeaderView = {
        // This reusable view is embedded inside another supplementary view, so keep it frame-based instead of auto layout
        let view = LabelButtonHeaderView(frame: .zero)
        view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        return view
    }()

    private var progress: CGFloat = 0
    private var transitionEnabled = true
    private var newsAffordanceExpandedConstraints = [NSLayoutConstraint]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        updateViewState(forHeight: bounds.height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        progress = 0
        transitionEnabled = true
        sectionTitleHeaderView.prepareForReuse()
        updateViewState(forHeight: bounds.height)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        // Supplementary view sizing can change before `layoutSubviews` runs during rotation.
        // Sync the active affordance constraints from the incoming layout height immediately.
        updateViewState(forHeight: layoutAttributes.size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateViewState(forHeight: bounds.height)
        updateSectionTitleHeaderFrame()
    }

    func configure(
        sectionHeaderConfiguration: SectionHeaderConfiguration,
        textColor: UIColor?,
        theme: Theme,
        transitionEnabled: Bool = true
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
        updateSectionTitleHeaderFrame()
        updateViewState(forHeight: bounds.height)
    }

    func setTransitionProgress(_ progress: CGFloat) {
        self.progress = min(max(progress, 0), 1)
        updateViewState(forHeight: bounds.height)
    }

    func setTransitionEnabled(_ transitionEnabled: Bool) {
        guard self.transitionEnabled != transitionEnabled else { return }
        self.transitionEnabled = transitionEnabled
        updateViewState(forHeight: bounds.height)
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
        updateSectionTitleHeaderFrame()

        newsAffordanceExpandedConstraints = [
            newsAffordanceContentView.topAnchor.constraint(equalTo: topAnchor),
        ]

        NSLayoutConstraint.activate([
            newsAffordanceContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            newsAffordanceContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            newsAffordanceContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateViewState(forHeight height: CGFloat) {
        let shouldShowAffordance = transitionEnabled
        updateAffordanceConstraints(shouldShowAffordance: shouldShowAffordance)

        if shouldShowAffordance {
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

    private func updateAffordanceConstraints(shouldShowAffordance: Bool) {
        if shouldShowAffordance {
            NSLayoutConstraint.activate(newsAffordanceExpandedConstraints)
        } else {
            NSLayoutConstraint.deactivate(newsAffordanceExpandedConstraints)
        }
    }

    private func updateSectionTitleHeaderFrame() {
        guard bounds.width > 0, bounds.height > 0 else {
            sectionTitleHeaderView.frame = bounds
            return
        }

        // Measure the label header at its natural height, then pin that measured frame to the
        // bottom of the transition container so the crossfade matches the final resting position.
        let measuredHeight = sectionTitleHeaderView.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let headerHeight = min(bounds.height, measuredHeight)
        sectionTitleHeaderView.frame = CGRect(
            x: 0,
            y: bounds.height - headerHeight,
            width: bounds.width,
            height: headerHeight
        )
    }
}
