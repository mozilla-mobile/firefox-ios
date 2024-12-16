// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class PullRefreshView: UIView,
                       ThemeApplicable {
    private struct UX {
        static let blinkProgressViewStandardThreshold: CGFloat = 80.0
        static let progressViewPadding: CGFloat = 28.0
        static let progressViewSize: CGFloat = 40.0
        static let progressViewAnimatedBackgroundSize: CGFloat = 30.0
        static let progressViewAnimatedBackgroundBlinkTransform = CGAffineTransform(scaleX: 2.1, y: 2.1)
        static let progressViewAnimatedBackgroundFinalAnimationTransform = CGAffineTransform(scaleX: 15.0, y: 15.0)
        static let defaultAnimationDuration: CGFloat = 0.3
        static let rotateProgressViewAnimationDuration: CGFloat = 0.1
        static let blinkAnimation = (duration: defaultAnimationDuration, damping: 6.0, initialVelocity: 10.0)
        static let reloadAnimation = (duration: 0.1, option: UIView.AnimationOptions.curveEaseOut)
        static let easterEggSize = CGSize(width: 80.0, height: 100.0)
        static let easterEggDelayInSeconds: CGFloat = 4.0
    }

    private let onRefreshCallback: VoidReturnCallback
    private lazy var progressView: UIImageView = .build { view in
        view.image = UIImage(named: StandardImageIdentifiers.Large.arrowClockwise)?.withRenderingMode(.alwaysTemplate)
        view.contentMode = .scaleAspectFit
    }
    private lazy var progressContainerView: UIView = .build { view in
        view.layer.cornerRadius = UX.progressViewAnimatedBackgroundSize / 2.0 * self.computeShrinkingFactor()
        view.backgroundColor = .clear
    }
    private weak var scrollView: UIScrollView?
    private var scrollObserver: NSKeyValueObservation?
    private var currentTheme: Theme?
    private var refreshIconHasFocus = false
    private lazy var easterEggGif: UIImageView? = .build { view in
        view.image = .gifFromBundle(named: "easterEggGif")
        view.isHidden = true
        view.contentMode = .scaleAspectFill
    }
    private var easterEggTimer: DispatchSourceTimer?
    private var isIpad: Bool {
        return traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular
    }

    init(parentScrollView: UIScrollView?,
         isPotraitOrientation: Bool,
         onRefreshCallback: @escaping VoidReturnCallback) {
        self.scrollView = parentScrollView
        self.onRefreshCallback = onRefreshCallback
        super.init(frame: .zero)
        // This is needed otherwise the final pull refresh flash would go out of bounds
        clipsToBounds = true
        setupEasterEgg(isPotrait: isPotraitOrientation)
        setupSubviews()
        startObservingContentScroll()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEasterEgg(isPotrait: Bool) {
        guard let easterEggGif else { return }
        addSubview(easterEggGif)
        let shrinkFactor = computeShrinkingFactor()
        let easterEggSize = UX.easterEggSize.applying(CGAffineTransform(scaleX: shrinkFactor, y: shrinkFactor))
        let layoutBuilder = EasterEggViewLayoutBuilder(easterEggSize: easterEggSize)
        layoutBuilder.layoutEasterEggView(easterEggGif, superview: self, isPortrait: isPotrait, isIpad: isIpad)
    }

    private func setupSubviews() {
        addSubviews(progressContainerView, progressView)
        let shrinkFactor = computeShrinkingFactor()
        let progressContainerViewPadding = UX.progressViewPadding * shrinkFactor
        let progressContainerViewSize = UX.progressViewAnimatedBackgroundSize * shrinkFactor

        if let scrollView, scrollView.contentOffset.y != 0 {
            let threshold = UX.blinkProgressViewStandardThreshold * shrinkFactor
            let initialRotationAngle = -(scrollView.contentOffset.y) / threshold
            progressView.transform = CGAffineTransform(rotationAngle: initialRotationAngle)
        }

        NSLayoutConstraint.activate([
            progressContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -progressContainerViewPadding),
            progressContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressContainerView.heightAnchor.constraint(equalToConstant: progressContainerViewSize),
            progressContainerView.widthAnchor.constraint(equalToConstant: progressContainerViewSize),

            progressView.centerYAnchor.constraint(equalTo: progressContainerView.centerYAnchor),
            progressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressView.heightAnchor.constraint(equalToConstant: UX.progressViewSize * shrinkFactor),
            progressView.widthAnchor.constraint(equalToConstant: UX.progressViewSize * shrinkFactor)
        ])
    }

    /// Starts observing the `UIScrollView` content offset so the refresh can react to content change and show
    /// the correct state of the pull to refresh view.
    func startObservingContentScroll() {
        scrollObserver = scrollView?.observe(\.contentOffset) { [weak self] _, _ in
            guard let scrollView = self?.scrollView, scrollView.isDragging else {
                guard let refreshHasFocus = self?.refreshIconHasFocus, refreshHasFocus else { return }
                self?.refreshIconHasFocus = false
                self?.easterEggGif?.removeFromSuperview()
                self?.easterEggGif = nil
                self?.scrollObserver?.invalidate()
                self?.triggerReloadAnimation()
                return
            }

            let threshold = (self?.computeShrinkingFactor() ?? 1.0) * UX.blinkProgressViewStandardThreshold

            if scrollView.contentOffset.y < -threshold {
                self?.blinkBackgroundProgressViewIfNeeded()
                self?.scheduleEasterEgg()
            } else if scrollView.contentOffset.y != 0.0 {
                self?.easterEggTimer?.cancel()
                self?.easterEggTimer = nil
                // This check prevents progressView re blink when scrolling the pull refresh before the web view is loaded
                self?.restoreBackgroundProgressViewIfNeeded()
                let rotationAngle = -(scrollView.contentOffset.y) / threshold

                UIView.animate(withDuration: UX.rotateProgressViewAnimationDuration) {
                    self?.progressView.transform = CGAffineTransform(rotationAngle: rotationAngle * 1.5)
                }
            }
        }
    }

    private func triggerReloadAnimation() {
        UIView.animate(withDuration: UX.reloadAnimation.duration,
                       delay: 0,
                       options: UX.reloadAnimation.option,
                       animations: {
            self.progressContainerView.transform = UX.progressViewAnimatedBackgroundFinalAnimationTransform
        }, completion: { [weak self] _ in
            self?.progressContainerView.backgroundColor = .clear
            self?.progressContainerView.transform = .identity
            self?.progressView.transform = .identity
            self?.onRefreshCallback()
        })
    }

    private func blinkBackgroundProgressViewIfNeeded() {
        guard !refreshIconHasFocus else { return }
        refreshIconHasFocus = true

        let shrinkFactor = computeShrinkingFactor()
        let blinkTransform = UX.progressViewAnimatedBackgroundBlinkTransform

        UIView.animate(withDuration: UX.blinkAnimation.duration,
                       delay: 0,
                       usingSpringWithDamping: UX.blinkAnimation.damping,
                       initialSpringVelocity: UX.blinkAnimation.initialVelocity,
                       animations: {
            self.progressContainerView.transform = blinkTransform.scaledBy(x: shrinkFactor,
                                                                           y: shrinkFactor)
            self.progressContainerView.backgroundColor = self.currentTheme?.colors.layer4
        }, completion: { _ in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        })
    }

    private func restoreBackgroundProgressViewIfNeeded() {
        guard refreshIconHasFocus else { return }
        refreshIconHasFocus = false
        UIView.animate(withDuration: UX.defaultAnimationDuration) {
            self.progressContainerView.transform = .identity
            self.progressContainerView.backgroundColor = .clear
        }
    }

    private func scheduleEasterEgg() {
        guard easterEggTimer == nil else { return }
        easterEggTimer = DispatchSource.makeTimerSource(queue: .main)
        easterEggTimer?.schedule(deadline: .now() + UX.easterEggDelayInSeconds)
        easterEggTimer?.setEventHandler { [weak self] in
            self?.showEasterEgg()
        }
        easterEggTimer?.activate()
    }

    private func showEasterEgg() {
        guard let easterEggGif else { return }
        TelemetryWrapper.shared.recordEvent(category: .action, method: .detect, object: .showPullRefreshEasterEgg)
        easterEggGif.isHidden = false
        let angle = atan2(easterEggGif.transform.b, easterEggGif.transform.a)
        UIView.animate(withDuration: UX.defaultAnimationDuration) {
            easterEggGif.transform = .identity.rotated(by: angle)
        }
    }

    /// Computes the shrinking factor to apply to all the pull refresh view content.
    ///
    /// The calculation is pure empirical.
    /// It compares the smaller scroll view dimension with the blink threshold that is also
    /// the limit above a pull refresh can happen. 
    /// That dimension is divided by 4.0 because on small devices those dimension becomes comparable
    /// and a shrink factor is needed otherwise pull to refresh wouldn't be possible,
    /// since the content offset of the scroll view wouldn't be enough to go above the threshold.
    private func computeShrinkingFactor() -> CGFloat {
        guard let scrollView else { return 1.0 }
        let minDimension = min(scrollView.frame.height, scrollView.frame.width)
        if minDimension / 4.0 > UX.blinkProgressViewStandardThreshold {
            return 1
        }
        return 0.8
    }

    func stopObservingContentScroll() {
        scrollObserver?.invalidate()
        scrollObserver = nil
    }

    func updateEasterEggForOrientationChange(isPotrait: Bool) {
        guard let easterEggGif else { return }
        easterEggGif.removeFromSuperview()
        insertSubview(easterEggGif, at: 0)
        let shrinkFactor = computeShrinkingFactor()
        let easterEggSize = UX.easterEggSize.applying(CGAffineTransform(scaleX: shrinkFactor, y: shrinkFactor))
        let layoutBuilder = EasterEggViewLayoutBuilder(easterEggSize: easterEggSize)
        layoutBuilder.layoutEasterEggView(easterEggGif, superview: self, isPortrait: isPotrait, isIpad: isIpad)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        backgroundColor = theme.colors.layer1
        progressView.tintColor = theme.colors.iconPrimary
    }

    deinit {
        easterEggTimer?.cancel()
        easterEggTimer = nil
        scrollObserver?.invalidate()
        scrollObserver = nil
    }
}

struct EasterEggViewLayoutBuilder {
    private struct UX {
        static let sidePadding: CGFloat = 32.0
        /// The max height that we are considering a device a small one.
        /// This screen height refers to iPhone SE 2/3 rd gen, 6,7,8.
        ///
        /// https://www.appmysite.com/blog/the-complete-guide-to-iphone-screen-resolutions-and-sizes/
        static let smallDevicesMaxScreenHeight: CGFloat = 667.0
    }

    let easterEggSize: CGSize

    func layoutEasterEggView(_ view: UIView, superview: UIView, isPortrait: Bool, isIpad: Bool) {
        var isPortrait = isPortrait
        if let screenHeight = UIWindow.keyWindow?.windowScene?.screen.bounds.height,
           screenHeight <= UX.smallDevicesMaxScreenHeight {
            // Force landscape layout so the easter egg shows only bottom sides and doesn't render clipped for small devices
            isPortrait = false
        }
        if isPortrait || isIpad {
            layoutEasterEggView(view, superview: superview, position: randomPortraitLayoutPosition())
        } else {
            layoutEasterEggView(view, superview: superview, position: randomLandscapeIphoneLayoutPosition())
        }
    }

    private func layoutEasterEggView(_ view: UIView, superview: UIView, position: NSRectAlignment) {
        let constraints: [NSLayoutConstraint] = switch position {
        case .leading:
            [
                view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -easterEggSize.height / 2.0)
            ]
        case .bottomLeading:
            [
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor,
                                              constant: UX.sidePadding)
            ]
        case .bottomTrailing:
            [
                view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor,
                                               constant: -UX.sidePadding),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ]
        case .trailing:
            [
                view.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -easterEggSize.height / 2.0)
            ]
        default:
            []
        }
        view.transform = easterEggTransformation(for: position)
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: easterEggSize.height),
            view.widthAnchor.constraint(equalToConstant: easterEggSize.width)
        ] + constraints)
    }

    func easterEggTransformation(for alignment: NSRectAlignment) -> CGAffineTransform {
        return switch alignment {
        case .topLeading:
            CGAffineTransform(translationX: 0, y: -easterEggSize.height).rotated(by: .pi)
        case .leading:
            CGAffineTransform(translationX: -easterEggSize.height, y: 0).rotated(by: .pi / 2)
        case .bottomLeading:
            CGAffineTransform(translationX: 0, y: easterEggSize.height)
        case .bottomTrailing:
            CGAffineTransform(translationX: 0, y: easterEggSize.height)
        case .trailing:
            CGAffineTransform(translationX: easterEggSize.height, y: 0).rotated(by: -.pi / 2)
        case .topTrailing:
            CGAffineTransform(translationX: 0, y: -easterEggSize.height).rotated(by: .pi)
        default:
            .identity
        }
    }

    private func randomPortraitLayoutPosition() -> NSRectAlignment {
        let allowedPositions: [NSRectAlignment] = [
            .bottomLeading,
            .bottomTrailing,
            .leading,
            .trailing
        ]
        return allowedPositions.randomElement() ?? .bottomLeading
    }

    private func randomLandscapeIphoneLayoutPosition() -> NSRectAlignment {
        // For iphone only allows this position since the other don't work properly
        let allowedPositions: [NSRectAlignment] = [
            .bottomLeading,
            .bottomTrailing
        ]
        return allowedPositions.randomElement() ?? .bottomLeading
    }
}
