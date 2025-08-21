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

public class SummarizeController: UIViewController, Themeable, Notifiable, CAAnimationDelegate {
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
        static let closeButtonEdgePadding: CGFloat = 16.0
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
    private let titleLabel: UILabel = .build {
        let isFontInAccessibilityCategory = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        $0.numberOfLines = isFontInAccessibilityCategory ? 2 : 3
        $0.font = FXFontStyles.Regular.title2.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.showsLargeContentViewer = true
        $0.isUserInteractionEnabled = true
        $0.addInteraction(UILargeContentViewerInteraction())
        $0.accessibilityTraits.insert(.header)
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
    private let closeButton: UIButton = .build {
        // This checks for Xcode 26 sdk availability thus we can compile on older Xcode version too
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        }
        #else
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        #endif
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
        $0.alpha = 0.0
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
    private lazy var gradient = AnimatedGradientOutlineView(frame: view.bounds)
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

    private func removeBorderOverlayView() {
        borderOverlayHostingController.willMove(toParent: nil)
        borderOverlayHostingController.view.removeFromSuperview()
        borderOverlayHostingController.removeFromParent()
    }

    /// Background gradient when loading summarizer
    private func setupLoadingBackgroundGradient() {
        backgroundGradient.frame = view.bounds
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 0.5, y: 1.0)
    }

    private let summaryView: UITextView = .build {
        $0.font = FXFontStyles.Regular.headline.scaledFont()
        $0.alpha = 0.0
        $0.showsVerticalScrollIndicator = false
        $0.contentInset = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: UX.tabSnapshotFinalPositionBottomPadding,
            right: 0.0
        )
        $0.adjustsFontForContentSizeCategory = true
        $0.isEditable = false
    }

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
        view.backgroundColor = .clear
        applyTheme()
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()

        gradient.startAnimating { [weak self] in
            guard let self else { return }
            self.closeButton.alpha = 1.0
            self.view.layer.insertSublayer(backgroundGradient, at: 0)
            self.viewModel.onShouldShowTabSnapshot()
            self.embedSnapshot()
        }
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

    private func configure() {
        titleLabel.accessibilityIdentifier = viewModel.titleLabelA11yId
        loadingLabel.text = viewModel.loadingLabel
        loadingLabel.accessibilityIdentifier = viewModel.loadingA11yId
        loadingLabel.accessibilityLabel = viewModel.loadingA11yLabel

        tabSnapshotContainer.accessibilityIdentifier = viewModel.tabSnapshotA11yId
        tabSnapshotContainer.accessibilityLabel = viewModel.tabSnapshotA11yLabel

        closeButton.accessibilityIdentifier = viewModel.closeButtonModel.a11yIdentifier
        closeButton.accessibilityLabel = viewModel.closeButtonModel.a11yLabel
        closeButton.setImage(UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
                             for: .normal)
        closeButton.addAction(
            UIAction(handler: { [weak self] _ in
                self?.triggerDismissingAnimation()
            }),
            for: .touchUpInside
        )
        summaryView.accessibilityIdentifier = viewModel.summarizeTextViewA11yId
        summaryView.accessibilityLabel = viewModel.summarizeTextViewA11yLabel
    }

    private func setupLayout() {
        gradient.isUserInteractionEnabled = false
        setupLoadingBackgroundGradient()
        view.addSubviews(
            tabSnapshotContainer,
            borderOverlayHostingController.view,
            gradient,
            titleLabel,
            closeButton,
            summaryView,
            loadingLabel,
            errorView
        )
        tabSnapshotContainer.addSubview(tabSnapshot)
        tabSnapshot.pinToSuperview()
        tabSnapshotTopConstraint = tabSnapshotContainer.topAnchor.constraint(equalTo: view.topAnchor)
        tabSnapshotTopConstraint?.isActive = true
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let topHalfBoundGuide = UILayoutGuide()
        view.addLayoutGuide(topHalfBoundGuide)

        NSLayoutConstraint.activate([
            topHalfBoundGuide.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
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

            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                            constant: UX.closeButtonEdgePadding),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                 constant: -UX.summaryViewEdgePadding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                constant: UX.summaryViewEdgePadding),

            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeButtonEdgePadding),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonEdgePadding),

            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.summaryViewEdgePadding),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.summaryViewEdgePadding),
            summaryView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.summaryViewEdgePadding),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            tabSnapshotContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabSnapshotContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabSnapshotContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            borderOverlayHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderOverlayHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderOverlayHostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            borderOverlayHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        /// Notify the hosting controller that it has been moved to the current view controller.
        borderOverlayHostingController.didMove(toParent: self)
    }

    private func embedSnapshot() {
        tabSnapshot.image = viewModel.tabSnapshot
        tabSnapshotTopConstraint?.constant = viewModel.tabSnapshotTopOffset

        let frameHeight = view.frame.height
        loadingLabel.startShimmering(light: .white, dark: .white.withAlphaComponent(0.5))

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

        gradient.animatePositionChange(animationCurve: UX.initialTransformTimingCurve)

        UIView.animate(withDuration: UX.initialTransformAnimationDuration) {
            self.tabSnapshot.layer.cornerRadius = UX.tabSnapshotCornerRadius
            self.loadingLabel.alpha = 1.0
        }
    }

    private func showSummary(_ summary: String) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onTabSnapshotPan))
        self.tabSnapshotContainer.addGestureRecognizer(panGesture)

        let tabSnapshotOffset = tabSnapshotTopConstraint?.constant ?? 0.0
        let tabSnapshotYTransform = view.frame.height - UX.tabSnapshotFinalPositionBottomPadding - tabSnapshotOffset

        let brandedSummary = """
        ###### \(viewModel.brandLabel)

        \(summary)

        ##### \(viewModel.summaryNote)
        """
        titleLabel.text = webView.title
        titleLabel.largeContentTitle = webView.title
        summaryView.attributedText = parse(markdown: brandedSummary)
        UIView.animate(withDuration: UX.showSummaryAnimationDuration) { [self] in
            gradient.alpha = 0.0
            removeBorderOverlayView()
            backgroundGradient.removeFromSuperlayer()
            tabSnapshotContainer.transform = CGAffineTransform(translationX: 0.0, y: tabSnapshotYTransform)
            loadingLabel.alpha = 0.0
            summaryView.alpha = 1.0
            titleLabel.alpha = 1.0
            view.backgroundColor = theme.colors.layer1
        } completion: { [weak self] _ in
            guard let tabSnapshotView = self?.tabSnapshotContainer else { return }
            UIView.animate(withDuration: UX.tabSnapshotBringToFrontAnimationDuration) {
                self?.onSummaryDisplayed()
                self?.view.bringSubviewToFront(tabSnapshotView)
            }
        }
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

        var configuration = configuration
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

    private var configuration: DownStylerConfiguration {
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

    // MARK: - CAAnimationDelegate
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag,
              let animation = anim as? CABasicAnimation,
              animation.keyPath == UX.tabSnapshotTranslationKeyPath else { return }
        setupDismissGestures()
        summarize()
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

    // MARK: - Notifiable
    public nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        DispatchQueue.main.async { [weak self] in
            let isFontInAccessibilityCategory = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
            self?.titleLabel.numberOfLines = isFontInAccessibilityCategory ? 2 : 3
        }
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        summaryView.backgroundColor = .clear
        titleLabel.textColor = theme.colors.textPrimary
        loadingLabel.textColor = theme.colors.textOnDark
        tabSnapshotContainer.layer.shadowColor = theme.colors.shadowStrong.cgColor
        if #unavailable(iOS 26) {
            closeButton.configuration?.baseBackgroundColor = theme.colors.actionTabActive
        }
        closeButton.configuration?.baseForegroundColor = theme.colors.textPrimary
        backgroundGradient.colors = theme.colors.layerGradientSummary.cgColors
        gradient.applyTheme(theme: theme)
        errorView.applyTheme(theme: theme)
    }
}
