// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

private final class PageContainer: UIView, ThemeApplicable {
    private struct UX {
        static let loadingImageSize: CGFloat = 24
        static let rotationKey = "worldCupPageSpinnerRotation"
        static let loadingImage = "ball"
        static let rotationAnimationDuration: CFTimeInterval = 1.0
        static let rotationAnimationFromValue: CGFloat = 0
        static let rotationAnimationToValue: CGFloat = .pi * 2
        static let visibleAlpha: CGFloat = 1.0
        static let hiddenAlpha: CGFloat = 0.0
    }

    let content: WorldCupPagerView
    private let loadingImageView: UIImageView = .build { image in
        image.image = UIImage(named: UX.loadingImage)
        image.isAccessibilityElement = false
        image.contentMode = .scaleAspectFit
        image.isHidden = true
    }

    init(content: WorldCupPagerView) {
        self.content = content
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingImageView)
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),

            loadingImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingImageView.widthAnchor.constraint(equalToConstant: UX.loadingImageSize),
            loadingImageView.heightAnchor.constraint(equalToConstant: UX.loadingImageSize),
        ])
    }

    /// Sets the Content visibility and hides the loading image in case the `isVisible` is set to true.
    func setContentVisibility(_ isVisible: Bool) {
        content.alpha = isVisible ? UX.visibleAlpha : UX.hiddenAlpha
        loadingImageView.isHidden = isVisible
        if isVisible {
            stopSpinning()
        } else {
            startSpinning()
        }
    }

    func setAccessibilityEnabled(_ isEnabled: Bool) {
        accessibilityElementsHidden = !isEnabled
    }

    func applyTheme(theme: Theme) {
        (content as? ThemeApplicable)?.applyTheme(theme: theme)
    }

    private func startSpinning() {
        guard loadingImageView.layer.animation(forKey: UX.rotationKey) == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = UX.rotationAnimationFromValue
        rotation.toValue = UX.rotationAnimationToValue
        rotation.duration = UX.rotationAnimationDuration
        rotation.repeatCount = .infinity
        loadingImageView.layer.add(rotation, forKey: UX.rotationKey)
    }

    private func stopSpinning() {
        loadingImageView.layer.removeAnimation(forKey: UX.rotationKey)
    }
}

final class WorldCupCell: UICollectionViewCell, UIScrollViewDelegate, ReusableCell, ThemeApplicable, Blurrable {
    private struct UX {
        static let rootContainerCornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let pageControlHeight: CGFloat = 6.0
        static let pageControlTopPadding: CGFloat = 16.0
        static let contentConstraintsChangeAnimationDuration: TimeInterval = 0.1
        static let contentFadeInDuration: TimeInterval = 0.05
        static let initialScrollViewHeight: CGFloat = 100
        static let animationDelay: TimeInterval = 0.0
        static let rootContainerWinnerViewInset: CGFloat = 8.0
    }

    // MARK: - UI Elements

    private let rootContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.rootContainerCornerRadius
        view.clipsToBounds = true
    }

    private lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bounces = false
        scrollView.clipsToBounds = true
        scrollView.delegate = self
        scrollView.semanticContentAttribute = .forceLeftToRight
    }

    private let pagesStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
        stack.semanticContentAttribute = .forceLeftToRight
    }

    private let pageControl: UIPageControl = .build { control in
        control.hidesForSinglePage = true
        control.isUserInteractionEnabled = false
        control.semanticContentAttribute = .forceLeftToRight
    }

    private let winnerBackgroundView: WorldCupWinnerBackgroundView = .build {
        $0.alpha = 0.0
    }

    private var pageConstraints: [NSLayoutConstraint] = []
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    private var pageControlHeightConstraint: NSLayoutConstraint?
    private var pageControlTopConstraint: NSLayoutConstraint?
    private var rootContainerTopConstraint: NSLayoutConstraint?
    private var rootContainerLeadingConstraint: NSLayoutConstraint?
    private var rootContainerTrailingConstraint: NSLayoutConstraint?
    private var rootContainerBottomConstraint: NSLayoutConstraint?
    private var currentState: WorldCupSectionState?
    private var onHeightChange: ((CGFloat) -> Void)?
    /// Called the first time a card is shown after the cell is configured.
    /// The closure should record the section-level impression as a side effect
    /// and return `true` only the first time it's called per homepage session.
    private var isCardImpression: (() -> Bool)?
    private var lastScrollViewWidth: CGFloat = 0
    private var theme: Theme?
    private let telemetry = WorldCupTelemetry()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        scrollView.addSubview(pagesStack)
        rootContainer.addSubviews(scrollView, pageControl)
        contentView.addSubview(winnerBackgroundView)
        contentView.addSubview(rootContainer)

        let heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: UX.initialScrollViewHeight)
        scrollViewHeightConstraint = heightConstraint

        let pageControlHeight = pageControl.heightAnchor.constraint(equalToConstant: UX.pageControlHeight)
        pageControlHeightConstraint = pageControlHeight
        let pageControlTopConstraint = pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor,
                                                                        constant: UX.pageControlTopPadding)
        self.pageControlTopConstraint = pageControlTopConstraint

        let rootTopConstraint = rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor)
        rootContainerTopConstraint = rootTopConstraint

        let rootLeadingConstraint = rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        rootContainerLeadingConstraint = rootLeadingConstraint
        let rootTrailingConstraint = rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        rootContainerTrailingConstraint = rootTrailingConstraint

        let rootBottomConstraint = rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        rootContainerBottomConstraint = rootBottomConstraint

        NSLayoutConstraint.activate([
            winnerBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            winnerBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            winnerBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            winnerBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            rootTopConstraint,
            rootLeadingConstraint,
            rootTrailingConstraint,
            rootBottomConstraint,

            scrollView.topAnchor.constraint(equalTo: rootContainer.topAnchor,
                                            constant: UX.padding),
            scrollView.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor),
            heightConstraint,

            pageControlTopConstraint,
            pageControl.centerXAnchor.constraint(equalTo: rootContainer.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor,
                                                constant: -UX.padding),
            pageControl.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: UX.padding),
            pageControl.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor, constant: -UX.padding),
            pageControlHeight,

            pagesStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // Pin stack height to the scroll view's visible frame to prevent vertical scrolling.
            pagesStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        goToPage(pageControl.currentPage, recordTelemetry: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // If the content view has changed width (i.e during rotation) then we need to sync the scrollView content offset
        // to the proper location, otherwise it will look of centered.
        // We get the width on the content view because the scrollView width is the same and it gets updated
        // in delay, unless the background view is visible add an offset since the background view insets the root container.
        guard lastScrollViewWidth != contentView.frame.width else { return }
        lastScrollViewWidth = contentView.frame.width
        let offset = winnerBackgroundView.alpha == 1.0 ? UX.rootContainerWinnerViewInset * 2.0 : 0.0
        scrollView.setContentOffset(
            CGPoint(x: CGFloat(pageControl.currentPage) * (lastScrollViewWidth - offset), y: 0.0),
            animated: false
        )
    }

    func configure(
        with state: WorldCupSectionState,
        theme: Theme,
        onHeightChange: @escaping (CGFloat) -> Void,
        isCardImpression: @escaping () -> Bool
    ) {
        // apply the blur suddenly to avoid any lags when showing the cell on the background blur
        adjustBlur(theme: theme)
        self.onHeightChange = onHeightChange
        self.isCardImpression = isCardImpression
        if currentState != state {
            currentState = state
            rebuildPages(for: state)
        }
        applyTheme(theme: theme)
    }

    private func rebuildPages(for state: WorldCupSectionState) {
        removePageViews()

        let pages = makePages(for: state)
        pageControl.numberOfPages = pages.count
        scrollView.isScrollEnabled = pages.count > 1
        pageControlHeightConstraint?.constant = pages.count > 1 ? UX.pageControlHeight : 0
        pageControlTopConstraint?.constant = pages.count > 1 ? UX.pageControlTopPadding : 0

        var constraints: [NSLayoutConstraint] = []
        for view in pages {
            view.translatesAutoresizingMaskIntoConstraints = false
            pagesStack.addArrangedSubview(view)
            constraints.append(view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor))
        }
        NSLayoutConstraint.activate(constraints)
        pageConstraints = constraints

        goToPage(initialPage(for: state, pageCount: pages.count))
    }

    /// Resolves which page the swipe view should display first. The middleware
    /// hands us the page index directly via `state.defaultMatchIndex`; we just
    /// clamp it into the valid page range.
    private func initialPage(for state: WorldCupSectionState, pageCount: Int) -> Int {
        guard pageCount > 0 else { return 0 }
        return min(max(state.defaultMatchIndex, 0), pageCount - 1)
    }

    private func makePages(for state: WorldCupSectionState) -> [PageContainer] {
        let views = WorldCupCellFactory.makePages(from: state)
        return views.map { PageContainer(content: $0) }
    }

    private func removePageViews() {
        NSLayoutConstraint.deactivate(pageConstraints)
        pageConstraints.removeAll()
        pagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let current = pageControl.currentPage
        for (index, page) in pagesStack.arrangedSubviews.enumerated() {
            guard index != current else { continue }
            (page as? PageContainer)?.setContentVisibility(false)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        let newPage = Int(round(scrollView.contentOffset.x / pageWidth))
        guard newPage != pageControl.currentPage else { return }
        goToPage(newPage)
    }

    // MARK: - Accessibility

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        let total = pagesStack.arrangedSubviews.count
        let pageWidth = scrollView.frame.width
        guard total > 1, pageWidth > 0 else { return false }

        let current = pageControl.currentPage
        let next: Int
        switch direction {
        case .left:
            next = current + 1
        case .right:
            next = current - 1
        default:
            return false
        }

        goToPage(next)
        return true
    }

    private func goToPage(_ page: Int, recordTelemetry: Bool = true) {
        pageControl.currentPage = page
        updatePageAccessibility()
        let (isShowingWinnerView, applyWinnerChanges) = getWinnerStatusForCurrentPage()
        let offset = isShowingWinnerView ? UX.rootContainerWinnerViewInset * 2.0 : 0.0
        let (scrollViewHeight, contentViewHeight) = getContentsHeight(for: page, isShowingWinnerView: isShowingWinnerView)
        applyWinnerChanges()
        scrollViewHeightConstraint?.constant = scrollViewHeight
        if recordTelemetry {
            recordSwipeTelemetry(forPage: page)
        }
        UIView.animate(
            withDuration: UX.contentConstraintsChangeAnimationDuration,
            delay: UX.animationDelay,
            options: [.allowUserInteraction],
            animations: {
                self.winnerBackgroundView.alpha = isShowingWinnerView ? 1.0 : 0.0
                self.onHeightChange?(contentViewHeight)
                self.contentView.layoutIfNeeded()
                self.scrollView.setContentOffset(
                    CGPoint(x: CGFloat(page) * (self.bounds.width - offset), y: 0),
                    animated: false
                )
            },
            completion: { [weak self] _ in
                if let theme = self?.theme {
                    self?.adjustBlur(theme: theme)
                }
                guard let container = self?.pagesStack.arrangedSubviews[safe: page] as? PageContainer else { return }
                UIView.animate(
                    withDuration: UX.contentFadeInDuration,
                    delay: UX.animationDelay,
                    options: [.allowUserInteraction],
                    animations: {
                        container.setContentVisibility(true)
                    },
                    completion: { _ in
                        UIAccessibility.post(notification: .screenChanged, argument: container)
                    }
                )
            }
        )
    }

    private func recordSwipeTelemetry(forPage page: Int) {
        guard let container = pagesStack.arrangedSubviews[safe: page] as? PageContainer,
              let viewName = container.content.telemetryValue else { return }
        let isImpression = isCardImpression?() ?? false
        telemetry.cardSwiped(view: viewName, isImpression: isImpression)
    }

    private func getContentsHeight(
        for page: Int,
        isShowingWinnerView: Bool = false,
    ) -> (scrollViewHeight: CGFloat, contentViewHeight: CGFloat) {
        guard let view = pagesStack.arrangedSubviews[safe: page] else {
            return (scrollView.frame.height, contentView.frame.height)
        }

        let fittingWidth = isShowingWinnerView
            ? bounds.width - UX.rootContainerWinnerViewInset * 2
            : bounds.width
        let scrollViewHeight = view.systemLayoutSizeFitting(
            CGSize(width: fittingWidth,
                   height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let pageControlSpacing = pageControlTopConstraint?.constant ?? 0
        let pageControlHeight = pageControlHeightConstraint?.constant ?? 0
        let winnerContribution = winnerHeightContribution(isShowingWinnerView: isShowingWinnerView)
        let contentHeight = winnerContribution
            + UX.padding + scrollViewHeight + pageControlSpacing + pageControlHeight + UX.padding

        return (scrollViewHeight, contentHeight)
    }

    private func winnerHeightContribution(isShowingWinnerView: Bool) -> CGFloat {
        guard isShowingWinnerView else { return 0 }
        let width = bounds.width > 0 ? bounds.width : contentView.bounds.width
        return winnerBackgroundView.contentBottomOffset(fittingWidth: width)
            + UX.rootContainerWinnerViewInset
    }

    /// Queries from the current card the winner status
    /// (Only final or third place are going to be shown the winner background view)
    /// return a tuple containing a boolean indicating whether the background view
    /// is going to be shown and a closure to apply the constraints changes
    private func getWinnerStatusForCurrentPage() -> (isShowing: Bool, applyChanges: () -> Void) {
        let current = pageControl.currentPage
        let container = pagesStack.arrangedSubviews[safe: current] as? PageContainer
        let card = container?.content as? WorldCupMatchCardView
        let winner = card?.getWinnerThirdPlaceOrFinal()
        let shouldShowWinner = winner != nil

        if let winner {
            winnerBackgroundView.configure(teamName: winner.teamKey, subtitle: winner.winnerLabel)
        }

        let applyChanges = { [weak self] in
            guard let self else { return }
            rootContainerTopConstraint?.isActive = false
            if shouldShowWinner {
                rootContainerTopConstraint = rootContainer.topAnchor
                    .constraint(equalTo: winnerBackgroundView.contentViewBottomAnchor)
                rootContainerLeadingConstraint?.constant = UX.rootContainerWinnerViewInset
                rootContainerTrailingConstraint?.constant = -UX.rootContainerWinnerViewInset
                rootContainerBottomConstraint?.constant = -UX.rootContainerWinnerViewInset
            } else {
                rootContainerTopConstraint = rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor)
                rootContainerLeadingConstraint?.constant = 0
                rootContainerTrailingConstraint?.constant = 0
                rootContainerBottomConstraint?.constant = 0
            }
            rootContainerTopConstraint?.isActive = true
        }

        return (shouldShowWinner, applyChanges)
    }

    private func updatePageAccessibility() {
        let current = pageControl.currentPage
        for (index, page) in pagesStack.arrangedSubviews.enumerated() {
            (page as? PageContainer)?.setAccessibilityEnabled(index == current)
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme
        contentView.backgroundColor = .clear
        pageControl.currentPageIndicatorTintColor = theme.colors.iconPrimary
        pageControl.pageIndicatorTintColor = theme.colors.iconSecondary
        adjustBlur(theme: theme)
        winnerBackgroundView.applyTheme(theme: theme)
        pagesStack.arrangedSubviews.forEach {
            ($0 as? PageContainer)?.applyTheme(theme: theme)
        }
    }

    // MARK: - Blurrable

    func adjustBlur(theme: Theme) {
        if winnerBackgroundView.alpha == 1.0 {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = .clear
            return
        }
        if shouldApplyWallpaperBlur {
            rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            rootContainer.removeVisualEffectView()
            rootContainer.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
    }
}
