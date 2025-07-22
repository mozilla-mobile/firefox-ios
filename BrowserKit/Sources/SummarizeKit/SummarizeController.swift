// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit
import ComponentLibrary
import MarkdownKit

// swiftlint:disable all
let dummyText = """
# This is header 1
## This is header 2
### This is header 3

**This text is bold**
*This text is italic*

### 31 Things to Do in Barcelona With Kids — tl;dr

- **Family-friendly attractions:** Parks, beaches, Sagrada Família, etc. Kids still like the “adult” highlights.  
- **Where to stay:** Family-friendly hotels (e.g. Hotel Barcelona Catedral) or regulated apartments.  

1. **Getting around:** Cable cars, open-top buses, and standard transit are all kid-manageable.  
2. **Food:** Tapas bars + markets like La Boqueria work great with kids.  
3. **Packing tips:** Dress for the climate and activities; think sun, walking, and water play.

This is a **Markdown link** that must not render:  
[Cute Cat Image](https://picsum.photos/200/300)

This is a **Markdown image** that must not render:  
![Cute Cat Image](https://picsum.photos/200/300 "A placeholder cat")

This is a **Markdown video** that must not render:  
<video src="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4" controls width="480"></video>

Overall: cultural hits + plenty of kid breaks = happy trip.
"""
// swiftlint:enable all

public struct SummarizeViewModel {
    let loadingLabel: String
    let loadingA11yLabel: String
    let loadingA11yId: String
    let summarizeTextViewA11yLabel: String
    let summarizeTextViewA11yId: String

    let closeButtonModel: CloseButtonViewModel
    let tabSnapshot: UIImage
    let tabSnapshotTopOffset: CGFloat

    let onDismiss: @MainActor () -> Void
    let onShouldShowTabSnapshot: @MainActor () -> Void

    public init(
        loadingLabel: String,
        loadingA11yLabel: String,
        loadingA11yId: String,
        summarizeTextViewA11yLabel: String,
        summarizeTextViewA11yId: String,
        closeButtonModel: CloseButtonViewModel,
        tabSnapshot: UIImage,
        tabSnapshotTopOffset: CGFloat,
        onDismiss: @escaping @MainActor () -> Void,
        onShouldShowTabSnapshot: @escaping @MainActor () -> Void
    ) {
        self.loadingLabel = loadingLabel
        self.loadingA11yLabel = loadingA11yLabel
        self.loadingA11yId = loadingA11yId
        self.summarizeTextViewA11yLabel = summarizeTextViewA11yLabel
        self.summarizeTextViewA11yId = summarizeTextViewA11yId
        self.closeButtonModel = closeButtonModel
        self.tabSnapshot = tabSnapshot
        self.onDismiss = onDismiss
        self.onShouldShowTabSnapshot = onShouldShowTabSnapshot
        self.tabSnapshotTopOffset = tabSnapshotTopOffset
    }
}

public class SummarizeController: UIViewController, Themeable {
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
    }

    private let viewModel: SummarizeViewModel

    // MARK: - Themeable
    public let themeManager: any Common.ThemeManager
    public var themeObserver: (any NSObjectProtocol)?
    public var notificationCenter: any Common.NotificationProtocol
    public let currentWindowUUID: Common.WindowUUID?

    // MARK: - UI properties
    private let loadingLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.alpha = 0
        $0.numberOfLines = 0
    }
    private let closeButton: UIButton = .build {
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
        $0.alpha = 0
    }
    private let tabSnapshot: UIImageView = .build {
        $0.clipsToBounds = true
        $0.contentMode = .top
    }
    private var tabSnapshotTopConstraint: NSLayoutConstraint?
    private lazy var gradient = AnimatedGradientOutlineView(frame: view.bounds)
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
    }

    public init(
        windowUUID: WindowUUID,
        viewModel: SummarizeViewModel,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.currentWindowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()

        applyTheme()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        gradient.startAnimating { [weak self] in
            self?.view.backgroundColor = theme.colors.layerSummary
            self?.viewModel.onShouldShowTabSnapshot()
            self?.embedSnapshot()
        }
    }

    private func setupSubviews() {
        view.addSubviews(tabSnapshot, gradient, closeButton, summaryView, loadingLabel)

        loadingLabel.text = viewModel.loadingLabel
        loadingLabel.accessibilityIdentifier = viewModel.loadingA11yId
        loadingLabel.accessibilityLabel = viewModel.loadingA11yLabel

        closeButton.accessibilityIdentifier = viewModel.closeButtonModel.a11yIdentifier
        closeButton.accessibilityLabel = viewModel.closeButtonModel.a11yLabel
        closeButton.setImage(UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
                             for: .normal)
        closeButton.addAction(
            UIAction(handler: { [weak self] _ in
                UIView.animate(withDuration: UX.panEndAnimationDuration) {
                    self?.tabSnapshot.transform = .identity
                    self?.tabSnapshot.layer.cornerRadius = 0.0
                } completion: { _ in
                    self?.dismiss(animated: true)
                }
            }),
            for: .touchUpInside
        )
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        let baseFont = FXFontStyles.Regular.body.scaledFont()
        let headerFont = FXFontStyles.Regular.title1.scaledFont()
        let baseColor = theme.colors.textPrimary
        let markdownParser = MarkdownParser(font: baseFont, color: baseColor)
        /// NOTE: The content is produced by an LLM; generated links may be unsafe or unreachable.
        /// To keep the MVP safe, link rendering is disabled.
        markdownParser.enabledElements =  .all.subtracting([.link, .automaticLink])
        markdownParser.header.font = headerFont
        summaryView.attributedText = markdownParser.parse(dummyText)
        summaryView.accessibilityIdentifier = viewModel.summarizeTextViewA11yId
        summaryView.accessibilityLabel = viewModel.summarizeTextViewA11yLabel

        tabSnapshotTopConstraint = tabSnapshot.topAnchor.constraint(equalTo: view.topAnchor)
        tabSnapshotTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            loadingLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                  constant: UX.summaryLabelHorizontalPadding),
            loadingLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                   constant: -UX.summaryLabelHorizontalPadding),

            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: UX.closeButtonEdgePadding),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonEdgePadding),

            summaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.summaryViewEdgePadding),
            summaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.summaryViewEdgePadding),
            summaryView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: UX.summaryViewEdgePadding),
            summaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            tabSnapshot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabSnapshot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabSnapshot.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func embedSnapshot() {
        tabSnapshot.image = viewModel.tabSnapshot
        tabSnapshotTopConstraint?.constant = viewModel.tabSnapshotTopOffset

        let frameHeight = view.frame.height
        loadingLabel.transform = CGAffineTransform(translationX: 0.0, y: frameHeight * 0.25)
        loadingLabel.startShimmering(light: .white, dark: .white.withAlphaComponent(0.1))

        let transformAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        transformAnimation.fromValue = 0
        transformAnimation.toValue = frameHeight / 2
        transformAnimation.duration = UX.initialTransformAnimationDuration
        transformAnimation.timingFunction = UX.initialTransformTimingCurve
        transformAnimation.fillMode = .forwards
        tabSnapshot.layer.add(transformAnimation, forKey: "translation")
        tabSnapshot.transform = CGAffineTransform(translationX: 0.0,
                                                  y: view.frame.height * UX.tabSnapshotInitialTransformPercentage)

        gradient.animatePositionChange(animationCurve: UX.initialTransformTimingCurve)

        UIView.animate(withDuration: UX.initialTransformAnimationDuration, delay: 0.0, options: [], animations: {
            self.tabSnapshot.layer.cornerRadius = UX.tabSnapshotCornerRadius
            self.loadingLabel.alpha = 1.0
        }) { _ in
            // TODO: - FXIOS-12858 replace this demo code with the actual backend API
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.showSummary()
            }
        }
    }

    private func showSummary() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        tabSnapshot.isUserInteractionEnabled = true
        tabSnapshot.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onTabSnapshotPan)))
        let tabSnapshotOffset = tabSnapshotTopConstraint?.constant ?? 0.0
        let tabSnapshotYTransform = view.frame.height - UX.tabSnapshotFinalPositionBottomPadding - tabSnapshotOffset

        UIView.animate(withDuration: UX.showSummaryAnimationDuration) { [self] in
           gradient.alpha = 0.0
           tabSnapshot.transform = CGAffineTransform(translationX: 0.0, y: tabSnapshotYTransform)
           loadingLabel.alpha = 0.0
           summaryView.alpha = 1.0
           closeButton.alpha = 1.0
           view.backgroundColor = theme.colors.layer1
        } completion: { [weak self] _ in
            guard let tabSnapshotView = self?.tabSnapshot else { return }
            UIView.animate(withDuration: UX.tabSnapshotBringToFrontAnimationDuration) {
                self?.view.bringSubviewToFront(tabSnapshotView)
            }
        }
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        viewModel.onDismiss()
        super.dismiss(animated: flag, completion: completion)
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

    private func handleTabPanChanged(tabSnapshotTransform: CGAffineTransform, translationY: CGFloat) {
        tabSnapshot.transform = tabSnapshotTransform.translatedBy(x: 0.0, y: translationY)
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
            UIView.animate(withDuration: UX.panEndAnimationDuration) { [self] in
                tabSnapshot.transform = .identity
                tabSnapshot.layer.cornerRadius = 0.0
            } completion: { [weak self] _ in
                self?.dismiss(animated: true)
            }
        } else {
            UIView.animate(withDuration: UX.panEndAnimationDuration) { [self] in
                summaryView.alpha = 1.0
                summaryView.transform = .identity
                tabSnapshot.transform = tabSnapshotTransform
            }
        }
    }

    // MARK: - Themeable

    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        summaryView.textColor = theme.colors.textPrimary
        summaryView.backgroundColor = .clear
        view.backgroundColor = .clear
        closeButton.tintColor = theme.colors.textPrimary
        gradient.applyTheme(theme: theme)
    }
}
