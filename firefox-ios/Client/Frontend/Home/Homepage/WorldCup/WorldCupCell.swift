// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// A homepage cell that pages through an arbitrary set of subviews with a page-indicator.
/// The cell dynamically resizes its height to match the currently visible page.
/// When there is only one subview, scrolling is disabled and the page indicator is hidden.
final class WorldCupCell: UICollectionViewCell, UIScrollViewDelegate, ReusableCell, ThemeApplicable, Blurrable {
    private struct UX {
        static let rootContainerCornerRadius: CGFloat = 26
        static let padding: CGFloat = 16
        static let pageControlHeight: CGFloat = 6.0
        static let pageControlTopPadding: CGFloat = 4
    }

    // MARK: - UI Elements

    private let rootContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.rootContainerCornerRadius
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
    private var pageControlHeightConstraint: NSLayoutConstraint?
    private var currentPage = 0
    private var currentState: WorldCupSectionState?
    private var onHeightChange: ((_ animated: Bool) -> Void)?

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

    // MARK: - Public

    /// Configures the cell with the given state, displaying its pages as full-width subviews.
    /// The cell height adapts to the currently visible page's height.
    /// When there is a single page, scrolling is disabled and the page indicator is hidden.
    /// Subviews are only rebuilt when the state changes; theme is always reapplied.
    /// `onHeightChange` is invoked when the cell needs the parent collection view to relayout
    /// to reflect a new height.
    func configure(
        with state: WorldCupSectionState,
        theme: Theme,
        onHeightChange: @escaping (_ animated: Bool) -> Void
    ) {
        self.onHeightChange = onHeightChange
        if currentState != state {
            currentState = state
            rebuildPages(for: state)
        }
        applyTheme(theme: theme)
    }

    private func makeSubviews(for state: WorldCupSectionState) -> [UIView] {
        let view = UIView()
        view.backgroundColor = .red
        view.heightAnchor.constraint(equalToConstant: 200.0).isActive = true
        return [WorldCupTimerView(windowUUID: state.windowUUID), view]
    }

    private func rebuildPages(for state: WorldCupSectionState) {
        removePageViews()

        let subviews = makeSubviews(for: state)
        pageViews = subviews
        pageControl.numberOfPages = subviews.count
        scrollView.isScrollEnabled = subviews.count > 1
        pageControlHeightConstraint?.constant = subviews.count > 1 ? UX.pageControlHeight : 0

        var constraints: [NSLayoutConstraint] = []
        for view in subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
            pagesStack.addArrangedSubview(view)
            constraints.append(view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor))
        }
        NSLayoutConstraint.activate(constraints)
        pageConstraints = constraints

        scrollView.contentOffset = .zero
        pageControl.currentPage = 0
        currentPage = 0

        updateScrollViewHeight(for: 0, animated: false)
    }

    // MARK: - Layout

    private func setupLayout() {
        contentView.backgroundColor = .clear
        scrollView.addSubview(pagesStack)
        rootContainer.addSubviews(scrollView, pageControl)
        contentView.addSubview(rootContainer)

        let heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: 0)
        scrollViewHeightConstraint = heightConstraint

        let pageControlHeight = pageControl.heightAnchor.constraint(equalToConstant: UX.pageControlHeight)
        pageControlHeightConstraint = pageControlHeight

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                            constant: UX.padding),
            scrollView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor,
                                                constant: UX.padding),
            scrollView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor,
                                                 constant: -UX.padding),
            heightConstraint,

            pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor,
                                             constant: UX.pageControlTopPadding),
            pageControl.centerXAnchor.constraint(equalTo: rootContainer.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                constant: -UX.padding),
            pageControlHeight,

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

        onHeightChange?(animated)
    }

    private func removePageViews() {
        NSLayoutConstraint.deactivate(pageConstraints)
        pageConstraints.removeAll()
        pagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pageViews.removeAll()
    }

    // MARK: - UIScrollViewDelegate
    
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

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        pageControl.currentPageIndicatorTintColor = theme.colors.iconPrimary
        pageControl.pageIndicatorTintColor = theme.colors.iconSecondary
        adjustBlur(theme: theme)
        pageViews
            .compactMap { $0 as? ThemeApplicable }
            .forEach { $0.applyTheme(theme: theme) }
    }

    // MARK: - Blurrable

    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
    
    private func setupShadow(theme: Theme) {
        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.rootContainerCornerRadius
        ).cgPath
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
    }
}
