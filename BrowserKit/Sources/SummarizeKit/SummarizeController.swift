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

class CustomStyler: DownStyler {
    // NOTE: The content is produced by an LLM; generated links may be unsafe or unreachable.
    // To keep the MVP safe, link rendering is disabled.
    override func style(link str: NSMutableAttributedString, title: String?, url: String?) {}

    override func style(image str: NSMutableAttributedString, title: String?, url: String?) {}
}

public protocol SummarizeNavigationHandler: AnyObject {
    func openURL(url: URL)

    func acceptToSConsent()

    func denyToSConsent()

    func dismissSummary()
}

public class SummarizeController: UIViewController, Themeable, CAAnimationDelegate {
    private struct UX {
        @MainActor // `CAMediaTimingFunction` is not Sendable, so isolate it to the main actor
        static let initialTransformTimingCurve = CAMediaTimingFunction(controlPoints: 1, 0, 0, 1)

        static let tabSnapshotInitialTransformPercentage: CGFloat = 0.5
        static let tabSnapshotFinalPositionBottomPadding: CGFloat = 110.0
        static let summaryViewEdgePadding: CGFloat = 12.0
        static let initialTransformAnimationDuration = 1.25
        static let infoViewAnimationDuration: CGFloat = 0.3
        static let panEndAnimationDuration: CGFloat = 0.3
        static let showSummaryAnimationDuration: CGFloat = 0.3
        static let streamingRevealDelay: TimeInterval = 4.0
        static let summaryLabelHorizontalPadding: CGFloat = 12.0
        static let panCloseSummaryVelocityThreshold: CGFloat = 1000.0
        static let panCloseSummaryHeightPercentageThreshold: CGFloat = 0.25
        static let tabSnapshotBringToFrontAnimationDuration: CGFloat = 0.25
        static let tabSnapshotCornerRadius: CGFloat = 32.0
        static let tabSnapshotShadowRadius: CGFloat = 64.0
        static let tabSnapshotShadowOffset = CGSize(width: 0.0, height: -10.0)
        static let tabSnapshotShadowOpacity: Float = 1.0
        static let tabSnapshotTranslationKeyPath = "transform.translation.y"
    }

    private let viewModel: SummarizeViewModel
    private let summarizerService: SummarizerService
    private let webView: WKWebView
    private var isTosAccepted: Bool
    private var tosPanelWasShown = false
    private let onSummaryDisplayed: () -> Void
    private weak var navigationHandler: SummarizeNavigationHandler?
    private var animationDoneContinuation: CheckedContinuation<Void, Never>?
    private var animationDone = false

    // MARK: - Themeable
    public let themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var notificationCenter: any Common.NotificationProtocol
    public let currentWindowUUID: Common.WindowUUID?

    // MARK: - UI properties
    private var parserConfiguration: DownStylerConfiguration {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        let textColor = theme.colors.textPrimary
        return DownStylerConfiguration(
            fonts: StaticFontCollection(
                heading1: FXFontStyles.Regular.title1.scaledFont(),
                heading2: FXFontStyles.Regular.title2.scaledFont(),
                heading3: FXFontStyles.Regular.title3.scaledFont(),
                heading4: FXFontStyles.Regular.headline.scaledFont(),
                heading5: FXFontStyles.Regular.footnote.scaledFont(),
                heading6: FXFontStyles.Regular.caption2.scaledFont(),
                body: FXFontStyles.Regular.body.scaledFont(),
                code: FXFontStyles.Regular.body.monospacedFont(),
                listItemPrefix: FXFontStyles.Regular.body.scaledFont()
            ),
            colors: StaticColorCollection(
                heading1: textColor,
                heading2: textColor,
                heading3: textColor,
                heading4: textColor,
                heading5: theme.colors.textSecondary,
                heading6: theme.colors.textSecondary,
                body: textColor,
                code: textColor,
                link: textColor,
                quote: textColor,
                quoteStripe: textColor,
                thematicBreak: textColor,
                listItemPrefix: textColor,
                codeBlockBackground: .clear
            ),
            listItemOptions: ListItemOptions(
                spacingAbove: 2,
                spacingBelow: 4
            )
        )
    }
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
        viewModel: SummarizeViewModel,
        summarizerService: SummarizerService,
        navigationHandler: SummarizeNavigationHandler?,
        webView: WKWebView,
        isTosAccepted: Bool,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        onSummaryDisplayed: @escaping () -> Void
    ) {
        self.currentWindowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.viewModel = viewModel
        self.summarizerService = summarizerService
        self.webView = webView
        self.navigationHandler = navigationHandler
        self.isTosAccepted = isTosAccepted
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
        setupTabSnapshot()
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
        // Ensure that the layout is resolved before shimmering
        loadingLabel.startShimmering(light: .white, dark: .white.withAlphaComponent(0.5))
    }

    private func configure() {
        loadingLabel.text = viewModel.loadingLabelViewModel.loadingLabel
        loadingLabel.accessibilityIdentifier = viewModel.loadingLabelViewModel.loadingA11yId
        loadingLabel.accessibilityLabel = viewModel.loadingLabelViewModel.loadingA11yLabel

        tabSnapshotContainer.accessibilityIdentifier = viewModel.tabSnapshotViewModel.tabSnapshotA11yId
        tabSnapshotContainer.accessibilityLabel = viewModel.tabSnapshotViewModel.tabSnapshotA11yLabel

        titleLabel.largeContentTitle = webView.title
        closeButton.accessibilityIdentifier = viewModel.closeButtonModel.a11yIdentifier
        closeButton.accessibilityLabel = viewModel.closeButtonModel.a11yLabel
        closeButton.largeContentTitle = viewModel.closeButtonModel.a11yLabel

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

    private func setupTabSnapshot() {
        tabSnapshot.image = viewModel.tabSnapshotViewModel.tabSnapshot
        tabSnapshotTopConstraint?.constant = viewModel.tabSnapshotViewModel.tabSnapshotTopOffset

        let frameHeight = view.frame.height
        let transformAnimation = CABasicAnimation(keyPath: UX.tabSnapshotTranslationKeyPath)
        transformAnimation.fromValue = 0
        transformAnimation.toValue = frameHeight / 2
        transformAnimation.duration = UX.initialTransformAnimationDuration
        transformAnimation.timingFunction = UX.initialTransformTimingCurve
        transformAnimation.fillMode = .forwards
        transformAnimation.delegate = self
        tabSnapshotContainer.layer.add(transformAnimation, forKey: "translation")
        tabSnapshotContainer.transform = CGAffineTransform(translationX: 0.0,
                                                           y: view.frame.height * UX.tabSnapshotInitialTransformPercentage)
        UIView.animate(withDuration: UX.initialTransformAnimationDuration) {
            self.tabSnapshot.layer.cornerRadius = UX.tabSnapshotCornerRadius
            self.loadingLabel.alpha = 1.0
        } completion: { [weak self] _ in
            self?.animationDone = true
            self?.animationDoneContinuation?.resume()
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
        infoView.alpha = 0.0
        Task { @MainActor [weak self] in
            await self?.summarizeTask()
        }
    }

    private func summarizeTask() async {
        do {
            guard isTosAccepted else {
                throw SummarizerError.tosConsentMissing
            }
            let stream = summarizerService.summarizeStreamed(from: webView)
            try await showStreamWithDelay(stream, delay: UX.streamingRevealDelay)
        } catch {
            let summaryError: SummarizerError = if let error = error as? SummarizerError {
                error
            } else {
                .unknown(error)
            }
            showError(summaryError)
        }
    }

    private func showStreamWithDelay(_ stream: AsyncThrowingStream<String, Error>, delay: TimeInterval) async throws {
        let startRevealingAt = Date().addingTimeInterval(delay)
        var lastChunk = ""
        var revealed = false
        do {
            /// NOTE1: By design the APIs send aggregated tokens instead of individual chunks.
            /// We don't need to accumulate them.
            /// NOTE2: Wait for the specified delay before revealing the summary. 
            /// This is done to provide a smoother user experience and avoid sudden changes.
            for try await aggregatedChunk in stream {
                lastChunk = aggregatedChunk
                guard Date() >= startRevealingAt || enoughWords(aggregatedChunk) else { continue }
                await withCheckedContinuation { continuation in
                    if self.animationDone {
                        continuation.resume()
                    } else {
                        self.animationDoneContinuation = continuation
                    }
                }
                revealed = true
                showSummary(aggregatedChunk)
            }
            /// NOTE: Streaming especially from a request that was cached can be faster than `delay`.
            /// This is to make sure when that happens we show the summary immediately.
            if !revealed {
                await withCheckedContinuation { continuation in
                    if self.animationDone {
                        continuation.resume()
                    } else {
                        self.animationDoneContinuation = continuation
                    }
                }
                showSummary(lastChunk)
            }

            let summaryWithNote = """
            \(lastChunk)

            ##### \(viewModel.summaryFootnote)
            """
            showSummary(summaryWithNote)
        } catch {
            guard revealed else { throw error }
            return
        }
    }

    private func enoughWords(_ text: String) -> Bool {
        return text.count > 2000
    }

    private func showSummary(_ summary: String) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onTabSnapshotPan))
        tabSnapshotContainer.addGestureRecognizer(panGesture)

        let tabSnapshotOffset = tabSnapshotTopConstraint?.constant ?? 0.0
        let tabSnapshotYTransform = view.frame.height - UX.tabSnapshotFinalPositionBottomPadding - tabSnapshotOffset

        closeButton.tintColor = themeManager.getCurrentTheme(for: currentWindowUUID).colors.iconPrimary
        configureSummaryView(summary: summary)

        // show the summary and related animation only if summary wasn't showed yet
        guard summaryView.alpha == 0.0 else { return }
        triggerImpactHaptics()
        UIView.animate(withDuration: UX.showSummaryAnimationDuration) { [self] in
            removeBorderOverlayView()
            backgroundGradient.removeFromSuperlayer()
            tabSnapshotContainer.transform = CGAffineTransform(translationX: 0.0, y: tabSnapshotYTransform)
            loadingLabel.alpha = 0.0
            summaryView.alpha = 1.0
            loadingLabel.stopShimmering()
            loadingLabel.removeFromSuperview()
        } completion: { [weak self] _ in
            guard let tabSnapshotView = self?.tabSnapshotContainer else { return }
            UIView.animate(withDuration: UX.tabSnapshotBringToFrontAnimationDuration) {
                self?.onSummaryDisplayed()
                self?.view.bringSubviewToFront(tabSnapshotView)
            }
        }
    }

    private func configureSummaryView(summary: String) {
        summaryView.configure(
            model: SummaryViewModel(
                title: webView.title,
                titleA11yId: viewModel.titleLabelA11yId,
                compactTitleA11yId: viewModel.compactTitleLabelA11yId,
                brandViewModel: viewModel.brandViewModel,
                summary: parse(markdown: summary),
                summaryA11yId: viewModel.summarizeViewA11yId,
                scrollContentBottomInset: UX.tabSnapshotFinalPositionBottomPadding
            )
        )
    }

    private func showError(_ error: SummarizerError) {
        if case .tosConsentMissing = error {
            tosPanelWasShown = true
        }
        let actionButtonLabel: String = switch error.shouldRetrySummarizing {
        case .acceptToS:
            viewModel.errorMessages.acceptToSButtonLabel
        case .retry:
            viewModel.errorMessages.retryButtonLabel
        case .close:
            viewModel.errorMessages.closeButtonLabel
        }
        let formatter = SummarizeErrorFormatter(
            theme: themeManager.getCurrentTheme(for: currentWindowUUID),
            isAccessibilityCategoryEnabled: traitCollection.preferredContentSizeCategory.isAccessibilityCategory,
            viewModel: viewModel
        )
        infoView.configure(
            viewModel: InfoViewModel(
                title: formatter.format(error: error),
                titleA11yId: viewModel.errorMessages.errorLabelA11yId,
                actionButtonLabel: actionButtonLabel,
                actionButtonA11yId: viewModel.errorMessages.errorButtonA11yId,
                actionButtonCallback: { [weak self] in
                    switch error.shouldRetrySummarizing {
                    case .retry:
                        self?.summarize()
                    case .close:
                        self?.dismissSummary()
                    case .acceptToS:
                        self?.navigationHandler?.acceptToSConsent()
                        self?.isTosAccepted = true
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
        UIView.animate(withDuration: UX.infoViewAnimationDuration) { [self] in
            onSummaryDisplayed()
            infoView.alpha = 1.0
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
        summarizerService.closeStream()
        if tosPanelWasShown && !isTosAccepted {
            navigationHandler?.denyToSConsent()
        }
        navigationHandler?.dismissSummary()
        super.dismiss(animated: flag, completion: completion)
    }

    private func parse(markdown: String) -> NSAttributedString? {
        let parser = Down(markdownString: markdown)

        // Apply custom paragraph styling with centering to header level 5 (######)
        let centeredParagraphStyle = NSMutableParagraphStyle()
        centeredParagraphStyle.alignment = .center
        centeredParagraphStyle.paragraphSpacingBefore = 16

        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.paragraphSpacing = 8

        let heading6Style = NSMutableParagraphStyle()
        heading6Style.paragraphSpacing = 16
        heading6Style.paragraphSpacingBefore = 0

        let heading2Style = NSMutableParagraphStyle()
        heading2Style.paragraphSpacing = 16
        heading2Style.paragraphSpacingBefore = 8

        var configuration = parserConfiguration
        var paragraphStyles = StaticParagraphStyleCollection()
        paragraphStyles.heading5 = centeredParagraphStyle
        paragraphStyles.heading6 = heading6Style
        paragraphStyles.heading2 = heading2Style
        paragraphStyles.body = bodyStyle
        configuration.paragraphStyles = paragraphStyles

        return try? parser.toAttributedString(
            styler: CustomStyler(configuration: configuration)
        )
    }

    // MARK: - PanGesture
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

    private func handleTabPanChanged(tabSnapshotTransform: CGAffineTransform, translationY: CGFloat) {
        tabSnapshotContainer.transform = tabSnapshotTransform.translatedBy(x: 0.0, y: translationY)
        if translationY < 0 {
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

    private func triggerImpactHaptics(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
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
