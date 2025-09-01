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

public class SummarizeController: UIViewController, Themeable, CAAnimationDelegate {
    private struct UX {
        static let tabSnapshotInitialTransformPercentage: CGFloat = 0.5
        static let tabSnapshotFinalPositionBottomPadding: CGFloat = 110.0
        static let summaryViewEdgePadding: CGFloat = 12.0
        static let initialTransformTimingCurve = CAMediaTimingFunction(controlPoints: 1, 0, 0, 1)
        static let initialTransformAnimationDuration = 1.25
        static let panEndAnimationDuration: CGFloat = 0.3
        static let showSummaryAnimationDuration: CGFloat = 0.3
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

    private let onSummaryDisplayed: () -> Void

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
    private let errorView: ErrorView = .build {
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
        webView: WKWebView,
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
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        triggerImpactHaptics()
        view.layer.insertSublayer(backgroundGradient, at: 0)
        setupTabSnapshot()
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
        summaryView.configureCloseButton(model: viewModel.closeButtonModel) { [weak self] in
            self?.triggerDismissingAnimation()
        }
    }

    private func setupLayout() {
        setupLoadingBackgroundGradient()
        view.addSubviews(
            tabSnapshotContainer,
            borderOverlayHostingController.view,
            summaryView,
            loadingLabel,
            errorView
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

            errorView.centerXAnchor.constraint(equalTo: topHalfBoundGuide.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: topHalfBoundGuide.centerYAnchor),
            errorView.topAnchor.constraint(greaterThanOrEqualTo: topHalfBoundGuide.topAnchor),
            errorView.bottomAnchor.constraint(lessThanOrEqualTo: topHalfBoundGuide.bottomAnchor),
            errorView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),

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
            self?.summarize()
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
        errorView.alpha = 0.0
        Task { [weak self] in
            await self?.summarizeTask()
        }
    }

    private func summarizeTask() async {
        do {
            let summary = try await summarizerService.summarize(from: webView)
            await MainActor.run {
                showSummary(summary)
            }
        } catch {
            let summaryError: SummarizerError = if let error = error as? SummarizerError {
                error
            } else {
                .unknown(error)
            }
            await MainActor.run {
                showError(summaryError)
            }
        }
    }

    private func showSummary(_ summary: String) {
        triggerImpactHaptics()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onTabSnapshotPan))
        tabSnapshotContainer.addGestureRecognizer(panGesture)

        let tabSnapshotOffset = tabSnapshotTopConstraint?.constant ?? 0.0
        let tabSnapshotYTransform = view.frame.height - UX.tabSnapshotFinalPositionBottomPadding - tabSnapshotOffset

        configureSummaryView(summary: summary)

        UIView.animate(withDuration: UX.showSummaryAnimationDuration) { [self] in
            removeBorderOverlayView()
            backgroundGradient.removeFromSuperlayer()
            tabSnapshotContainer.transform = CGAffineTransform(translationX: 0.0, y: tabSnapshotYTransform)
            loadingLabel.alpha = 0.0
            summaryView.showContent()
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
        let summaryWithNote = """
        \(summary)

        ##### \(viewModel.summaryFootnote)
        """
        // The summary view is constrained to the edge of the screen. In order to have title animation and to scroll
        // under the status bar, a custom offset is needed so the summary view doesn't overlay the bottom tab snapshot and
        // the safe area.
        let summaryContentInset = UIEdgeInsets(
            top: view.safeAreaInsets.top,
            left: 0.0,
            bottom: UX.tabSnapshotFinalPositionBottomPadding,
            right: 0.0
        )
        summaryView.configure(
            model: SummaryViewModel(
                title: webView.title,
                titleA11yId: viewModel.titleLabelA11yId,
                compactTitleA11yId: viewModel.compactTitleLabelA11yId,
                brandViewModel: viewModel.brandViewModel,
                summary: parse(markdown: summaryWithNote),
                summaryA11yId: viewModel.summarizeViewA11yId,
                scrollContentInsets: summaryContentInset
            )
        )
    }

    private func showError(_ error: SummarizerError) {
        let actionButtonLabel: String = if error.shouldRetrySummarizing {
            viewModel.errorMessages.retryButtonLabel
        } else {
            viewModel.errorMessages.closeButtonLabel
        }
        errorView.configure(
            viewModel: ErrorViewModel(
                title: error.description(for: viewModel.errorMessages),
                titleA11yId: viewModel.errorMessages.errorLabelA11yId,
                actionButtonLabel: actionButtonLabel,
                actionButtonA11yId: viewModel.errorMessages.errorButtonA11yId,
                actionButtonCallback: { [weak self] in
                    if error.shouldRetrySummarizing {
                        self?.summarize()
                    } else {
                        self?.dismissSummary()
                    }
                }
            )
        )
        loadingLabel.alpha = 0.0
        UIView.animate(withDuration: UX.initialTransformAnimationDuration) { [self] in
            self.onSummaryDisplayed()
            errorView.alpha = 1.0
        }
    }

    private func removeBorderOverlayView() {
        borderOverlayHostingController.willMove(toParent: nil)
        borderOverlayHostingController.view.removeFromSuperview()
        borderOverlayHostingController.removeFromParent()
    }

    private func dismissSummary() {
        UIView.animate(withDuration: UX.panEndAnimationDuration) { [self] in
            errorView.alpha = 0.0
            loadingLabel.alpha = 0.0
            tabSnapshotContainer.transform = .identity
            tabSnapshot.layer.cornerRadius = 0.0
        } completion: { [weak self] _ in
            self?.dismiss(animated: true)
        }
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        viewModel.onDismiss()
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

    private func triggerDismissingAnimation() {
        UIView.animate(withDuration: UX.panEndAnimationDuration) { [weak self] in
            self?.tabSnapshotContainer.transform = .identity
            self?.tabSnapshot.layer.cornerRadius = 0.0
        } completion: { [weak self] _ in
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
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag,
              let animation = anim as? CABasicAnimation,
              animation.keyPath == UX.tabSnapshotTranslationKeyPath else { return }
        setupDismissGestures()
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
        loadingLabel.textColor = theme.colors.textOnDark
        tabSnapshotContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
        backgroundGradient.colors = theme.colors.layerGradientSummary.cgColors
        errorView.applyTheme(theme: theme)
    }
}
