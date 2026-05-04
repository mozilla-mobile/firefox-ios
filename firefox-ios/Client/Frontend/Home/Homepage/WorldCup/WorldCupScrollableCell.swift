// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// A homepage cell that pages through an arbitrary set of subviews with a page-indicator.
/// The cell dynamically resizes its height to match the currently visible page.
/// When there is only one subview, scrolling is disabled and the page indicator is hidden.
final class WorldCupScrollableCell: UICollectionViewCell, ReusableCell, ThemeApplicable, Blurrable {
    private struct UX {
        static let generalCornerRadius: CGFloat = 16
        static let contentInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let pageControlHeight: CGFloat = 20
        static let pageControlBottomSpacing: CGFloat = 4
    }

    // MARK: - UI Elements

    private let rootContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.generalCornerRadius
        view.clipsToBounds = true
    }

    private let scrollView: UIScrollView = .build { scrollView in
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bounces = false
        scrollView.clipsToBounds = true
    }

    private let pagesStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.spacing = 0
    }

    private let pageControl: UIPageControl = .build { control in
        control.currentPage = 0
        control.hidesForSinglePage = true
        control.isUserInteractionEnabled = false
    }

    // MARK: - State

    private var pageViews: [UIView] = []
    private var pageConstraints: [NSLayoutConstraint] = []
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    private var currentPage = 0

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = false

        scrollView.delegate = self
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removePageViews()
        scrollView.contentOffset = .zero
        pageControl.currentPage = 0
        currentPage = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.generalCornerRadius
        ).cgPath
    }

    // MARK: - Public

    /// Replaces the current content with the given subviews, displayed as full-width pages.
    /// The cell height adapts to the currently visible page's height.
    /// When there is a single subview, scrolling is disabled and the page indicator is hidden.
    func configure(with subviews: [UIView], theme: Theme) {
        removePageViews()
        scrollView.contentOffset = .zero
        pageControl.currentPage = 0
        currentPage = 0

        pageViews = subviews
        pageControl.numberOfPages = subviews.count
        scrollView.isScrollEnabled = subviews.count > 1

        var constraints: [NSLayoutConstraint] = []
        for view in subviews {
            pagesStack.addArrangedSubview(view)
            constraints.append(view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor))
        }
        NSLayoutConstraint.activate(constraints)
        pageConstraints = constraints

        // Set initial scroll view height to first page
        updateScrollViewHeight(for: 0, animated: false)

        applyTheme(theme: theme)
    }

    // MARK: - Layout

    private func setupLayout() {
        contentView.backgroundColor = .clear
        scrollView.addSubview(pagesStack)
        rootContainer.addSubviews(scrollView, pageControl)
        contentView.addSubview(rootContainer)

        let heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: 0)
        scrollViewHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                            constant: UX.contentInsets.top),
            scrollView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                                constant: UX.contentInsets.left),
            scrollView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                 constant: -UX.contentInsets.right),
            heightConstraint,

            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor,
                                             constant: UX.pageControlBottomSpacing),
            pageControl.centerXAnchor.constraint(equalTo: rootContainer.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                constant: -UX.contentInsets.bottom),
            pageControl.heightAnchor.constraint(equalToConstant: UX.pageControlHeight),

            pagesStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Pin stack height to the scroll view's visible frame to prevent vertical scrolling.
            pagesStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    private func updateScrollViewHeight(for page: Int, animated: Bool) {
        guard let view = pageViews[safe: page] else { return }

        let targetHeight = view.systemLayoutSizeFitting(
            CGSize(width: scrollView.frame.width > 0 ? scrollView.frame.width : bounds.width,
                   height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard scrollViewHeightConstraint?.constant != targetHeight else { return }
        scrollViewHeightConstraint?.constant = targetHeight

        guard let collectionView = superview as? UICollectionView else { return }

        if animated {
            collectionView.performBatchUpdates(nil)
        } else {
            UIView.performWithoutAnimation {
                collectionView.performBatchUpdates(nil)
            }
        }
    }

    private func removePageViews() {
        NSLayoutConstraint.deactivate(pageConstraints)
        pageConstraints.removeAll()
        pagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.generalCornerRadius
        ).cgPath
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        pageControl.currentPageIndicatorTintColor = theme.colors.iconPrimary
        pageControl.pageIndicatorTintColor = theme.colors.iconSecondary
        adjustBlur(theme: theme)
    }

    // MARK: - Blurrable

    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            rootContainer.layoutIfNeeded()
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension WorldCupScrollableCell: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        let newPage = Int(round(scrollView.contentOffset.x / pageWidth))
        guard newPage != currentPage else { return }
        currentPage = newPage
        pageControl.currentPage = newPage
        updateScrollViewHeight(for: newPage, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        pageControl.currentPage = Int(round(scrollView.contentOffset.x / pageWidth))
    }
}
