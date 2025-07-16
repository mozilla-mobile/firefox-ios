// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit
import ComponentLibrary

// swiftlint:disable line_length
let dummyText = """
<h1>This is the header</h1>

<h3>The article '31 Things to Do in Barcelona With Kids' from Bridges and Balloons offers a comprehensive guide for families visiting Barcelona. Authored by Victoria, who has lived in Barcelona and visited multiple times with her children, the guide combines personal experiences with practical advice. bridgesandballoons.com Highlights from the Guide: Family-Friendly Attractions: The guide lists 31 activities suitable for children, ranging from park visits and beach outings to exploring architectural marvels like the Sagrada Familia. It emphasizes that many of Barcelona's classic tourist spots are also appealing to kids.  Accommodation Recommendations: Suggestions include family-friendly hotels like Hotel Barcelona Catedral and advice on apartment rentals, noting the city's regulations on short-term rentals. bridgesandballoons.com Transportation Tips: Insights on navigating the city with children, including the use of cable cars and open-top buses, are provided to help families plan their movements efficiently. bridgesandballoons.com Dining with Kids: The guide discusses child-friendly dining options, highlighting the abundance of tapas bars and markets like La Boqueria where families can enjoy local cuisine. Packing Advice: Practical tips on what to pack when traveling to Barcelona with children, considering the city's climate and activities, are included to assist in preparation. Overall, the guide serves as a valuable resource for families seeking to explore Barcelona, offering a blend of cultural experiences and child-friendly activities.</h3>
"""
// swiftlint: enable line_length

public struct SummarizeViewModel {
    let summarizeLabel: String
    let summarizeA11yLabel: String
    let summarizeTextViewA11yLabel: String

    let closeButtonModel: CloseButtonViewModel
    let tabSnapshot: UIImage
    let tabSnapshotTopOffset: CGFloat

    let onDismiss: @MainActor () -> Void
    let onShouldShowTabSnapshot: @MainActor () -> Void

    public init(
        summarizeLabel: String,
        summarizeA11yLabel: String,
        summarizeTextViewA11yLabel: String,
        closeButtonModel: CloseButtonViewModel,
        tabSnapshot: UIImage,
        tabSnapshotTopOffset: CGFloat,
        onDismiss: @escaping @MainActor () -> Void,
        onShouldShowTabSnapshot: @escaping @MainActor () -> Void
    ) {
        self.summarizeLabel = summarizeLabel
        self.summarizeA11yLabel = summarizeA11yLabel
        self.summarizeTextViewA11yLabel = summarizeTextViewA11yLabel
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
    }

    private let viewModel: SummarizeViewModel

    // MARK: - Themeable
    public let themeManager: any Common.ThemeManager
    public var themeObserver: (any NSObjectProtocol)?
    public var notificationCenter: any Common.NotificationProtocol
    public let currentWindowUUID: Common.WindowUUID?

    // MARK: - UI properties
    private let loadingLabel: UILabel = .build {
        $0.adjustsFontSizeToFitWidth = true
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.alpha = 0
        $0.numberOfLines = 0
    }
    private let closeButton: CloseButton = .build {
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
    private var screenCornerRadius: CGFloat {
        return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0.0
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
        gradient.startAnimating { [weak self] in
            self?.view.backgroundColor = GradientColors.red
            self?.viewModel.onShouldShowTabSnapshot()
            self?.embedSnapshot()
        }
    }

    private func setupSubviews() {
        view.addSubviews(tabSnapshot, gradient, closeButton, summaryView, loadingLabel)

        loadingLabel.text = viewModel.summarizeLabel
        closeButton.configure(viewModel: viewModel.closeButtonModel)
        closeButton.addAction(
            UIAction(handler: { [weak self] _ in
                UIView.animate(withDuration: UX.panEndAnimationDuration) {
                    self?.tabSnapshot.transform = .identity
                    self?.tabSnapshot.layer.cornerRadius = 0.0
                } completion: { _ in
                    self?.viewModel.onDismiss()
                    self?.dismiss(animated: true)
                }
            }),
            for: .touchUpInside
        )

        let document = try? NSAttributedString(
            data: Data(dummyText.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        )
        if let document {
            let mutable = NSMutableAttributedString(attributedString: document)
            mutable.beginEditing()
            mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
                if let oldFont = value as? UIFont {
                    let newDescriptor = FXFontStyles.Regular.body.scaledFont().fontDescriptor
                        .withSymbolicTraits(oldFont.fontDescriptor.symbolicTraits)
                    if let newDescriptor {
                        let newFont = UIFont(descriptor: newDescriptor, size: oldFont.pointSize)
                        mutable.addAttribute(.font, value: newFont, range: range)
                    }
                }
            }
            mutable.endEditing()
            summaryView.attributedText = mutable
        }

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
            self.tabSnapshot.layer.cornerRadius = self.screenCornerRadius
            self.loadingLabel.alpha = 1.0
        }) { _ in
            // This is here just to show case the full animation
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
            if let snapshot = self?.tabSnapshot {
                UIView.animate(withDuration: 0.2) {
                    self?.view.bringSubviewToFront(snapshot)
                }
            }
        }
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
                self?.viewModel.onDismiss()
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
    }
}
