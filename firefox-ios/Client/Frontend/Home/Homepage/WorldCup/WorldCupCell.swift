// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

final class WorldCupCell: UICollectionViewCell, UIScrollViewDelegate, ReusableCell, ThemeApplicable, Blurrable {
    private struct UX {
        static let rootContainerCornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let pageControlHeight: CGFloat = 6.0
        static let pageControlTopPadding: CGFloat = 16.0
        static let heightChangeAnimationDuration: TimeInterval = 0.15
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

        let heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: 0)
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

    func configure(
        with state: WorldCupSectionState,
        theme: Theme,
        onHeightChange: @escaping () -> Void
    ) {
        self.onHeightChange = onHeightChange
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

        scrollView.contentOffset = .zero
        pageControl.currentPage = 0

        updateScrollViewHeight(for: 0, animated: false)
    }

    private func makePages(for state: WorldCupSectionState) -> [UIView] {
        let live = WorldCupInfoCardView(windowUUID: state.windowUUID)
        live.configure(with: .placeholderLive, theme: LightTheme())
        let schedule = WorldCupInfoCardView(windowUUID: state.windowUUID)
        schedule.configure(with: .placeholder, theme: LightTheme())
        let noUpcoming = WorldCupInfoCardView(windowUUID: state.windowUUID)
        noUpcoming.configure(with: .placeholderNoUpcoming, theme: LightTheme())
        let contents: [UIView] = [
            WorldCupTimerView(windowUUID: state.windowUUID),
            live,
            schedule,
            noUpcoming
        ]
        return contents.map { WorldCupPageContainer(content: $0) }
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
                delay: 0.0,
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
        [current - 1, current + 1].forEach { index in
            (pagesStack.arrangedSubviews[safe: index] as? WorldCupPageContainer)?.setContentAlpha(0)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        handleScrollEnd(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleScrollEnd(scrollView)
    }

    private func handleScrollEnd(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        guard pageWidth > 0 else { return }
        let newPage = Int(round(scrollView.contentOffset.x / pageWidth))
        let oldPage = pageControl.currentPage

        [oldPage - 1, oldPage + 1].forEach { index in
            if index != newPage,
               let container = pagesStack.arrangedSubviews[safe: index] as? WorldCupPageContainer {
                container.setContentAlpha(1)
            }
        }

        guard newPage != oldPage else { return }
        pageControl.currentPage = newPage

        updateScrollViewHeight(for: newPage, animated: true) { [weak self] in
            guard let self,
                  let container = self.pagesStack.arrangedSubviews[safe: newPage]
                    as? WorldCupPageContainer else { return }
            UIView.animate(
                withDuration: 0.1,
                delay: 0.0,
                options: [.allowUserInteraction],
                animations: { container.setContentAlpha(1) }
            )
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        contentView.backgroundColor = .clear
        pageControl.currentPageIndicatorTintColor = theme.colors.iconPrimary
        pageControl.pageIndicatorTintColor = theme.colors.iconSecondary
        adjustBlur(theme: theme)
        pagesStack.arrangedSubviews.forEach {
            ($0 as? WorldCupPageContainer)?.applyTheme(theme: theme)
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

private final class WorldCupPageContainer: UIView, ThemeApplicable {
    private static let spinnerSize: CGFloat = 24
    private static let rotationKey = "worldCupPageSpinnerRotation"

    private let content: UIView
    private let spinner: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ball"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    init(content: UIView) {
        self.content = content
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),
            spinner.widthAnchor.constraint(equalToConstant: Self.spinnerSize),
            spinner.heightAnchor.constraint(equalToConstant: Self.spinnerSize),
        ])
        startSpinning()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContentAlpha(_ value: CGFloat) {
        content.alpha = value
        spinner.alpha = value == 1.0 ? 0.0 : 1.0
    }

    func applyTheme(theme: Theme) {
        spinner.tintColor = theme.colors.iconPrimary
        (content as? ThemeApplicable)?.applyTheme(theme: theme)
    }

    private func startSpinning() {
        guard spinner.layer.animation(forKey: Self.rotationKey) == nil else { return }
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 2.0
        rotation.repeatCount = .infinity
        spinner.layer.add(rotation, forKey: Self.rotationKey)
    }
}
