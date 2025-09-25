// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit
import ComponentLibrary
import WebKit
import Down
import SwiftUI

public protocol SummarizeNavigationHandler: AnyObject {
    func openURL(url: URL)

    func dismissSummary()
}

public class SummarizeController: UIViewController, Themeable, CAAnimationDelegate {
    private struct UX {
        @MainActor // `CAMediaTimingFunction` is not Sendable, so isolate it to the main actor
        static let initialTransformTimingCurve = CAMediaTimingFunction(controlPoints: 1, 0, 0, 1)

        static let tabSnapshotInitialTransformPercentage: CGFloat = 0.5
        static let tabSnapshotFinalPositionBottomPadding: CGFloat = 110.0
        static let summaryViewEdgePadding: CGFloat = 12.0
        static let initialTransformAnimationDuration = 0.9
        static let infoViewAnimationDuration: CGFloat = 0.3
        static let panEndAnimationDuration: CGFloat = 0.3
        static let showSummaryAnimationDuration: CGFloat = 0.3
        static let streamingRevealDelay: TimeInterval = 4.0
        static let summaryLabelHorizontalPadding: CGFloat = 12.0
        static let panCloseSummaryVelocityThreshold: CGFloat = 600.0
        static let panCloseSummaryHeightPercentageThreshold: CGFloat = 0.25
        static let tabSnapshotBringToFrontAnimationDuration: CGFloat = 0.25
        static let tabSnapshotCornerRadius: CGFloat = 32.0
        static let tabSnapshotShadowRadius: CGFloat = 64.0
        static let tabSnapshotShadowOffset = CGSize(width: 0.0, height: -10.0)
        static let tabSnapshotShadowOpacity: Float = 1.0
        static let tabSnapshotTranslationKeyPath = "transform.translation.y"
        static let labelShimmeringColorAlpha: CGFloat = 0.5
    }

    private let configuration: SummarizeViewConfiguration
    private let viewModel: SummarizeViewModel
    private let webView: WKWebView
    private let onSummaryDisplayed: () -> Void
    private weak var navigationHandler: SummarizeNavigationHandler?

    // MARK: - Themeable
    public let themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var notificationCenter: any Common.NotificationProtocol
    public let currentWindowUUID: Common.WindowUUID?

    // MARK: - UI properties
    private let loadingLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.alpha = 0
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }
    private lazy var closeButton: UIButton = .build {
        $0.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        $0.addAction(UIAction(handler: { [weak self] _ in
            self?.triggerDismissingAnimation()
        }), for: .touchUpInside)
        $0.showsLargeContentViewer = true
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.body.systemFont()
        $0.showsLargeContentViewer = true
        $0.isUserInteractionEnabled = true
        $0.addInteraction(UILargeContentViewerInteraction())
        $0.alpha = 0.0
    }
    private let infoView: InfoView = .build {
        $0.alpha = 0
    }
    private let tabSnapshot: UIImageView = .build {
        $0.clipsToBounds = true
        $0.contentMode = .top
    }
    private let tabSnapshotContainer: UIView = .build {
        $0.layer.masksToBounds = false
        $0.layer.shadowOffset = UX.tabSnapshotShadowOffset
        $0.layer.shadowOpacity = UX.tabSnapshotShadowOpacity
        $0.layer.shadowRadius = UX.tabSnapshotShadowRadius
        $0.isUserInteractionEnabled = true
        $0.isAccessibilityElement = true
    }
    private var tabSnapshotTopConstraint: NSLayoutConstraint?
    private lazy var backgroundGradient = CAGradientLayer()
    private lazy var tabSnapshotPanGesture = UIPanGestureRecognizer(target: self, action: #selector(onTabSnapshotPan))

    /// Border overlay when loading the summary report
    private lazy var borderOverlayHostingController: UIHostingController<BorderView> = {
        let host = UIHostingController(rootView: BorderView(theme: themeManager.getCurrentTheme(for: currentWindowUUID)))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        return host
    }()
    private let summaryView: SummaryView = .build()

    // For the MVP only the portrait orientation is supported
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public init(
        windowUUID: WindowUUID,
        configuration: SummarizeViewConfiguration,
        viewModel: SummarizeViewModel,
        navigationHandler: SummarizeNavigationHandler?,
        webView: WKWebView,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        onSummaryDisplayed: @escaping () -> Void
    ) {
        self.currentWindowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.configuration = configuration
        self.viewModel = viewModel
        self.webView = webView
        self.navigationHandler = navigationHandler
        self.onSummaryDisplayed = onSummaryDisplayed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        configure()
        setupLayout()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        summarize()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        triggerImpactHaptics()
        view.layer.insertSublayer(backgroundGradient, at: 0)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateTabSnapshotToMidScreen()
        // Ensure that the layout is resolved before shimmering
        let textColor = themeManager.getCurrentTheme(for: currentWindowUUID).colors.textOnDark
        loadingLabel.startShimmering(light: textColor, dark: textColor.withAlphaComponent(UX.labelShimmeringColorAlpha))
    }

    private func configure() {
        loadingLabel.text = configuration.loadingLabel.loadingLabel
        loadingLabel.accessibilityIdentifier = configuration.loadingLabel.loadingA11yId
        loadingLabel.accessibilityLabel = configuration.loadingLabel.loadingA11yLabel

        tabSnapshotContainer.accessibilityIdentifier = configuration.tabSnapshot.tabSnapshotA11yId
        tabSnapshotContainer.accessibilityLabel = configuration.tabSnapshot.tabSnapshotA11yLabel

        titleLabel.largeContentTitle = webView.title
        closeButton.accessibilityIdentifier = configuration.closeButton.a11yIdentifier
        closeButton.accessibilityLabel = configuration.closeButton.a11yLabel
        closeButton.largeContentTitle = configuration.closeButton.a11yLabel

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.titleView = titleLabel

        setupTitleAnimation()
    }

    private func setupTitleAnimation() {
        summaryView.onDidChangeTitleCellVisibility = { [weak self] isShowingTitleCell in
            self?.titleLabel.alpha = isShowingTitleCell ? 0.0 : 1.0
            self?.titleLabel.text = isShowingTitleCell ? nil : self?.webView.title
        }
    }

    private func setupLayout() {
        setupLoadingBackgroundGradient()
        view.addSubviews(
            summaryView,
            loadingLabel,
            infoView,
            tabSnapshotContainer,
            borderOverlayHostingController.view
        )
        tabSnapshotContainer.addSubview(tabSnapshot)
        tabSnapshot.pinToSuperview()
        tabSnapshotTopConstraint = tabSnapshotContainer.topAnchor.constraint(equalTo: view.topAnchor)
        tabSnapshotTopConstraint?.isActive = true
        tabSnapshot.image = configuration.tabSnapshot.tabSnapshot
        tabSnapshotTopConstraint?.constant = configuration.tabSnapshot.tabSnapshotTopOffset

        let topHalfBoundGuide = UILayoutGuide()
        view.addLayoutGuide(topHalfBoundGuide)

        NSLayoutConstraint.activate([
            topHalfBoundGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topHalfBoundGuide.bottomAnchor.constraint(equalTo: view.centerYAnchor),
            topHalfBoundGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topHalfBoundGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            loadingLabel.topAnchor.constraint(greaterThanOrEqualTo: topHalfBoundGuide.topAnchor),
            loadingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                  constant: UX.summaryLabelHorizontalPadding),
            loadingLabel.centerYAnchor.constraint(equalTo: topHalfBoundGuide.centerYAnchor),
            loadingLabel.centerXAnchor.constraint(equalTo: topHalfBoundGuide.centerXAnchor),
            loadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                   constant: -UX.summaryLabelHorizontalPadding),
            loadingLabel.bottomAnchor.constraint(lessThanOrEqualTo: topHalfBoundGuide.bottomAnchor),

            infoView.centerXAnchor.constraint(equalTo: topHalfBoundGuide.centerXAnchor),
            infoView.centerYAnchor.constraint(equalTo: topHalfBoundGuide.centerYAnchor),
            infoView.topAnchor.constraint(greaterThanOrEqualTo: topHalfBoundGuide.topAnchor),
            infoView.bottomAnchor.constraint(lessThanOrEqualTo: topHalfBoundGuide.bottomAnchor),
            infoView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            infoView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),

            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryView.topAnchor.constraint(equalTo: view.topAnchor),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            tabSnapshotContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabSnapshotContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabSnapshotContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            borderOverlayHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderOverlayHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderOverlayHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            borderOverlayHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Notify the hosting controller that it has been moved to the current view controller.
        borderOverlayHostingController.didMove(toParent: self)
    }

    private func animateTabSnapshotToMidScreen() {
        let frameHeight = view.frame.height
        let transformAnimation = CABasicAnimation(keyPath: UX.tabSnapshotTranslationKeyPath)
        transformAnimation.fromValue = 0
        transformAnimation.toValue = frameHeight / 2
        transformAnimation.duration = UX.initialTransformAnimationDuration
        transformAnimation.timingFunction = UX.initialTransformTimingCurve
        transformAnimation.fillMode = .forwards
        transformAnimation.delegate = self
        transformAnimation.isRemovedOnCompletion = true
        tabSnapshotContainer.layer.add(transformAnimation, forKey: "translation")
        tabSnapshotContainer.transform = CGAffineTransform(translationX: 0.0,
                                                           y: view.frame.height * UX.tabSnapshotInitialTransformPercentage)
        UIView.animate(withDuration: UX.initialTransformAnimationDuration) {
            self.tabSnapshot.layer.cornerRadius = UX.tabSnapshotCornerRadius
            self.loadingLabel.alpha = 1.0
        } completion: { [weak self] _ in
            self?.viewModel.unblockSummarization()
        }
    }

    private func setupLoadingBackgroundGradient() {
        backgroundGradient.frame = view.bounds
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    private func summarize() {
        loadingLabel.alpha = 1.0
        let textColor = themeManager.getCurrentTheme(for: currentWindowUUID).colors.textOnDark
        loadingLabel.startShimmering(light: textColor, dark: textColor.withAlphaComponent(UX.labelShimmeringColorAlpha))
        infoView.alpha = 0.0
        viewModel.summarize(
            webView: webView,
            footNoteLabel: configuration.summaryFootnote,
            dateProvider: DefaultDateProvider()
        ) { [weak self] result in
            switch result {
            case .success(let summary):
                self?.showSummary(summary)
            case .failure(let failure):
                self?.showError(failure)
            }
        }
    }

    private func showSummary(_ summary: String) {
        tabSnapshotContainer.addGestureRecognizer(tabSnapshotPanGesture)

        let tabSnapshotOffset = tabSnapshotTopConstraint?.constant ?? 0.0
        let tabSnapshotYTransform = view.frame.height - UX.tabSnapshotFinalPositionBottomPadding - tabSnapshotOffset

        configureSummaryView(summary: summary)

        // show the summary and related animation only if summary wasn't showed yet
        guard summaryView.alpha == 0.0 else { return }
        triggerImpactHaptics()
        UIView.animate(withDuration: UX.showSummaryAnimationDuration) { [self] in
            removeBorderOverlayView()
            backgroundGradient.removeFromSuperlayer()
            tabSnapshotContainer.transform = CGAffineTransform(translationX: 0.0, y: tabSnapshotYTransform)
            summaryView.alpha = 1.0
            applyTheme()
            loadingLabel.alpha = 0.0
            loadingLabel.stopShimmering()
        } completion: { [weak self] _ in
            guard let tabSnapshotView = self?.tabSnapshotContainer else { return }
            UIView.animate(withDuration: UX.tabSnapshotBringToFrontAnimationDuration) {
                self?.onSummaryDisplayed()
                self?.view.bringSubviewToFront(tabSnapshotView)
            }
        }
    }

    private func configureSummaryView(summary: String) {
        let formatter = SummaryFormatter(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
        summaryView.configure(
            model: SummaryViewModel(
                title: webView.title,
                titleA11yId: configuration.titleLabelA11yId,
                compactTitleA11yId: configuration.compactTitleLabelA11yId,
                brandViewModel: configuration.brandView,
                summary: formatter.format(markdown: summary),
                summaryA11yId: configuration.summarizeViewA11yId,
                scrollContentBottomInset: UX.tabSnapshotFinalPositionBottomPadding
            )
        )
    }

    private func triggerImpactHaptics(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private func showError(_ error: SummarizerError) {
        if case .tosConsentMissing = error {
            viewModel.setConsentScreenShown()
        }
        let actionButtonLabel: String = switch error.shouldRetrySummarizing {
        case .acceptToS:
            configuration.errorMessages.acceptToSButtonLabel
        case .retry:
            configuration.errorMessages.retryButtonLabel
        case .close:
            configuration.errorMessages.closeButtonLabel
        }

        let formatter = SummarizeErrorFormatter(
            theme: themeManager.getCurrentTheme(for: currentWindowUUID),
            isAccessibilityCategoryEnabled: traitCollection.preferredContentSizeCategory.isAccessibilityCategory,
            viewModel: configuration
        )
        infoView.configure(
            viewModel: InfoViewModel(
                title: formatter.format(error: error),
                titleA11yId: configuration.errorMessages.errorLabelA11yId,
                actionButtonLabel: actionButtonLabel,
                actionButtonA11yId: configuration.errorMessages.errorButtonA11yId,
                actionButtonCallback: { [weak self] in
                    switch error.shouldRetrySummarizing {
                    case .retry:
                        self?.summarize()
                    case .close:
                        self?.dismissSummary()
                    case .acceptToS:
                        self?.viewModel.setConsentAccepted()
                        self?.summarize()
                    }
                }, linkCallback: { [weak self] url in
                    self?.triggerDismissingAnimation {
                        self?.navigationHandler?.openURL(url: url)
                    }
                }
            )
        )
        loadingLabel.alpha = 0.0
        tabSnapshotContainer.removeGestureRecognizer(tabSnapshotPanGesture)
        let shouldInsertBackgroundGradient = backgroundGradient.superlayer == nil
        UIView.animate(withDuration: UX.infoViewAnimationDuration) { [self] in
            onSummaryDisplayed()
            summaryView.alpha = 0.0
            infoView.alpha = 1.0
            tabSnapshotContainer.transform = .identity.translatedBy(x: 0.0, y: view.frame.height / 2)
            guard shouldInsertBackgroundGradient else { return }
            view.layer.insertSublayer(backgroundGradient, at: 0)
        } completion: { [weak self] _ in
            self?.applyTheme()
        }
    }

    private func removeBorderOverlayView() {
        borderOverlayHostingController.willMove(toParent: nil)
        borderOverlayHostingController.view.removeFromSuperview()
        borderOverlayHostingController.removeFromParent()
    }

    private func dismissSummary() {
        UIView.animate(withDuration: UX.panEndAnimationDuration) { [self] in
            infoView.alpha = 0.0
            loadingLabel.alpha = 0.0
            tabSnapshotContainer.transform = .identity
            tabSnapshot.layer.cornerRadius = 0.0
        } completion: { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        viewModel.closeSummarization()
        viewModel.logConsentStatus()
        navigationHandler?.dismissSummary()
        super.dismiss(animated: flag, completion: completion)
    }

    // MARK: - TabSnapshot Gesture

    @objc
    private func dismissSummaryFromGesture(_ gesture: UITapGestureRecognizer) {
        triggerDismissingAnimation()
    }

    private func triggerDismissingAnimation(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: UX.panEndAnimationDuration) { [weak self] in
            self?.tabSnapshotContainer.transform = .identity
            self?.tabSnapshot.layer.cornerRadius = 0.0
        } completion: { [weak self] _ in
            completion?()
            self?.dismiss(animated: true)
        }
    }

    @objc
    private func onTabSnapshotPan(_ gesture: UIPanGestureRecognizer) {
        let translationY = gesture.translation(in: view).y
        let tabSnapshotOffset = tabSnapshotTopConstraint?.constant ?? 0.0
        let tabSnapshotYTransform = view.frame.height - UX.tabSnapshotFinalPositionBottomPadding - tabSnapshotOffset
        let tabSnapshotTransform = CGAffineTransform(translationX: 0.0,
                                                     y: tabSnapshotYTransform)
        switch gesture.state {
        case .changed:
            handleTabPanChanged(tabSnapshotTransform: tabSnapshotTransform, translationY: translationY)
        case .ended, .cancelled, .failed:
            handleTabPanEnded(gesture, tabSnapshotTransform: tabSnapshotTransform)
        default:
            break
        }
    }

    private func handleTabPanChanged(tabSnapshotTransform: CGAffineTransform, translationY: CGFloat) {
        tabSnapshotContainer.transform = tabSnapshotTransform.translatedBy(x: 0.0, y: translationY)
        if translationY < 0, summaryView.alpha != 0.0 {
            let percentage = 1 - abs(translationY) / view.frame.height
            summaryView.alpha = percentage
        }
    }

    private func handleTabPanEnded(_ gesture: UIPanGestureRecognizer, tabSnapshotTransform: CGAffineTransform) {
        let panVelocityY = gesture.velocity(in: view).y
        let translationY = gesture.translation(in: view).y
        let shouldCloseSummary = abs(translationY) > view.frame.height * UX.panCloseSummaryHeightPercentageThreshold
                                 || panVelocityY > UX.panCloseSummaryVelocityThreshold
        if shouldCloseSummary {
            dismissSummary()
        } else {
            UIView.animate(withDuration: UX.panEndAnimationDuration) { [self] in
                summaryView.alpha = 1.0
                summaryView.transform = .identity
                tabSnapshotContainer.transform = tabSnapshotTransform
            }
        }
    }

    // MARK: - CAAnimationDelegate
    nonisolated public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag,
              let animation = anim as? CABasicAnimation,
              animation.keyPath == UX.tabSnapshotTranslationKeyPath else { return }

        ensureMainThread {
            self.setupDismissGestures()
        }
    }

    /// Sets up gestures that allow the user to dismiss the summary.
    /// - Adds a tap gesture on the tab snapshot to close.
    /// - Adds a swipe-up gesture on the tab snapshot to close.
    ///
    /// Both gestures call `dismissSummaryFromGesture`, which handles the dismissal animation.
    private func setupDismissGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSummaryFromGesture))
        tabSnapshotContainer.addGestureRecognizer(tap)

        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(dismissSummaryFromGesture))
        swipeUp.direction = .up
        tabSnapshotContainer.addGestureRecognizer(swipeUp)
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer1
        summaryView.backgroundColor = .clear
        summaryView.applyTheme(theme: theme)
        titleLabel.textColor = theme.colors.textPrimary
        loadingLabel.textColor = theme.colors.textOnDark
        tabSnapshotContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
        backgroundGradient.colors = theme.colors.layerGradientSummary.cgColors
        closeButton.tintColor = summaryView.alpha == 0 ? theme.colors.iconOnColor : theme.colors.iconPrimary
        infoView.applyTheme(theme: theme)
    }
}
