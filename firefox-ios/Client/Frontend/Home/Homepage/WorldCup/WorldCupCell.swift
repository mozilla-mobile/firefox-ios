// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

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

    private let content: UIView
    private let loadingImageView: UIImageView = .build { image in
        image.image = UIImage(named: UX.loadingImage)
        image.isAccessibilityElement = false
        image.contentMode = .scaleAspectFit
    }

    init(content: UIView) {
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
        startSpinning()
    }

    /// Sets the Content visibility and hides the loading image in case the `isVisible` is set to true.
    func setContentVisibility(_ isVisible: Bool) {
        content.alpha = isVisible ? UX.visibleAlpha : UX.hiddenAlpha
        loadingImageView.alpha = isVisible ? UX.hiddenAlpha : UX.visibleAlpha
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
        static let heightChangeAnimationDuration: TimeInterval = 0.1
        static let contentFadeInDuration: TimeInterval = 0.05
        static let initialScrollViewHeight: CGFloat = 0
        static let animationDelay: TimeInterval = 0.0
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
    }

    private let pagesStack: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.alignment = .center
    }

    private let pageControl: UIPageControl = .build { control in
        control.hidesForSinglePage = true
        control.isUserInteractionEnabled = false
    }

    private var pageConstraints: [NSLayoutConstraint] = []
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    private var pageControlHeightConstraint: NSLayoutConstraint?
    private var pageControlTopConstraint: NSLayoutConstraint?
    private var currentState: WorldCupSectionState?
    private var onHeightChange: (() -> Void)?
    private var lastScrollViewWidth: CGFloat = 0
    private var currentTheme: Theme?
    private weak var matchesCardView: WorldCupMatchCardView?
    private var matchesFetchTask: Task<Void, Never>?
    private let apiClient: WorldCupAPIClientProtocol? = try? WorldCupAPIClient()

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
        contentView.addSubview(rootContainer)

        let heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: UX.initialScrollViewHeight)
        scrollViewHeightConstraint = heightConstraint

        let pageControlHeight = pageControl.heightAnchor.constraint(equalToConstant: UX.pageControlHeight)
        pageControlHeightConstraint = pageControlHeight
        let pageControlTopConstraint = pageControl.topAnchor.constraint(equalTo: scrollView.bottomAnchor,
                                                                        constant: UX.pageControlTopPadding)
        self.pageControlTopConstraint = pageControlTopConstraint

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).priority(.defaultHigh),

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
        updateScrollViewHeight(for: pageControl.currentPage, animated: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // If the content view has changed width (i.e during rotation) then we need to sync the scrollView content offset
        // to the proper location, otherwise it will look of centered.
        // We get the width on the content view because the scrollView width is the same and it gets updated
        // in delay.
        guard lastScrollViewWidth != contentView.frame.width else { return }
        lastScrollViewWidth = contentView.frame.width
        scrollView.setContentOffset(
            CGPoint(x: CGFloat(pageControl.currentPage) * lastScrollViewWidth, y: 0.0),
            animated: false
        )
    }

    func configure(
        with state: WorldCupSectionState,
        theme: Theme,
        onHeightChange: @escaping () -> Void
    ) {
        self.onHeightChange = onHeightChange
        self.currentTheme = theme
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

        goToPage(0)
    }

    private func makePages(for state: WorldCupSectionState) -> [UIView] {
        guard state.isMilestone2 else {
            let timerView = WorldCupTimerView(windowUUID: state.windowUUID)
            timerView.configure(state: state)
            return [PageContainer(content: timerView)]
        }
        let card = WorldCupMatchCardView(windowUUID: state.windowUUID)
        card.configure(with: Self.emptyMatches, theme: currentTheme ?? LightTheme())
        matchesCardView = card
        scheduleMatchesFetch()
        let timerView = WorldCupTimerView(windowUUID: state.windowUUID)
        timerView.configure(state: state)
        let contents: [UIView] = [
            timerView,
            card
        ]
        return contents.map { PageContainer(content: $0) }
    }

    /// Empty state shown while the merino fetch is in flight — no live pill,
    /// no matches. Replaced on first successful fetch.
    private static let emptyMatches = WorldCupMatches(
        phaseTitle: String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel,
        isLive: false,
        featuredMatch: [],
        upcomingMatches: []
    )

    /// Kicks off a real merino fetch via `WorldCupAPIClient` and reconfigures the
    /// matches card when there is data. 
    private func scheduleMatchesFetch() {
        matchesFetchTask?.cancel()
        guard let apiClient = self.apiClient else { return }
        matchesFetchTask = Task { [weak self, apiClient] in
            let result = await apiClient.loadMatches(query: .matches, team: nil)
            guard case .success(let response) = result,
                  let response,
                  !Task.isCancelled,
                  let self,
                  let card = self.matchesCardView else { return }
            let matches = WorldCupMatches(response: response)
            card.configure(with: matches, theme: self.currentTheme ?? LightTheme())
        }
    }

    private func updateScrollViewHeight(for page: Int, animated: Bool, completion: (() -> Void)? = nil) {
        guard let view = pagesStack.arrangedSubviews[safe: page] else {
            completion?()
            return
        }

        let targetHeight = view.systemLayoutSizeFitting(
            CGSize(width: scrollView.frame.width > 0 ? scrollView.frame.width : bounds.width,
                   height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        guard scrollViewHeightConstraint?.constant != targetHeight else {
            completion?()
            return
        }

        if animated {
            UIView.animate(
                withDuration: UX.heightChangeAnimationDuration,
                delay: UX.animationDelay,
                options: [.allowUserInteraction],
                animations: {
                    self.scrollViewHeightConstraint?.constant = targetHeight
                    self.contentView.layoutIfNeeded()
                    self.onHeightChange?()
                },
                completion: { _ in completion?() }
            )
        } else {
            scrollViewHeightConstraint?.constant = targetHeight
            onHeightChange?()
            completion?()
        }
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

        scrollView.setContentOffset(CGPoint(x: CGFloat(next) * pageWidth, y: 0), animated: true)
        goToPage(next)
        return true
    }

    private func goToPage(_ page: Int) {
        pageControl.currentPage = page
        updatePageAccessibility()
        updateScrollViewHeight(for: page, animated: true) { [weak self] in
            guard let container = self?.pagesStack.arrangedSubviews[safe: page] as? PageContainer else { return }
            UIView.animate(
                withDuration: UX.contentFadeInDuration,
                delay: UX.animationDelay,
                options: [.allowUserInteraction],
                animations: { container.setContentVisibility(true) },
                completion: { _ in
                    UIAccessibility.post(notification: .screenChanged, argument: container)
                }
            )
        }
    }

    private func updatePageAccessibility() {
        let current = pageControl.currentPage
        for (index, page) in pagesStack.arrangedSubviews.enumerated() {
            (page as? PageContainer)?.setAccessibilityEnabled(index == current)
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = .clear
        pageControl.currentPageIndicatorTintColor = theme.colors.iconPrimary
        pageControl.pageIndicatorTintColor = theme.colors.iconSecondary
        adjustBlur(theme: theme)
        pagesStack.arrangedSubviews.forEach {
            ($0 as? PageContainer)?.applyTheme(theme: theme)
        }
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
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageUX.shadowOpacity
        contentView.layer.shadowOffset = HomepageUX.shadowOffset
        contentView.layer.shadowRadius = HomepageUX.shadowRadius
    }
}
