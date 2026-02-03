// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// MARK: - Custom Presentation Animation
final class VoiceSearchPresentationAnimator: NSObject,
                                             UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let transitionDuration: TimeInterval = 2.0
        static let presentationAnimationSpringDumping: CGFloat = 0.8
        static let presentationAnimationSpringVelocity: CGFloat = 1.0
        static let buttonsContainerInitialTranslationY: CGFloat = 100.0
        static let scrimAlpha: CGFloat = 0.25
        static let dismissalTranslationFactor: CGFloat = 0.25
        @MainActor
        static var screenCornerRadius: CGFloat {
            return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0.0
        }
    }
    private let theme: any Theme
    /// Wether the dismiss is done via cross dissolve transition.
    /// If set to false the dismiss animation presents the presenting controller sliding it from left to right.
    var dismissWithCrossDissolveTransition = false

    init(theme: any Theme) {
        self.theme = theme
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return self
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return UX.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresenting = transitionContext.viewController(forKey: .to) is VoiceSearchViewController
        guard isPresenting else {
            if dismissWithCrossDissolveTransition {
                animateDismissalViaCrossDissolve(transitionContext)
            } else {
                animateDismissalViaSliding(transitionContext)
            }
            return
        }
        animatePresentation(transitionContext)
    }

    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let voiceSearchController = transitionContext.viewController(forKey: .to) as? VoiceSearchViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(voiceSearchController.view)

        voiceSearchController.view.frame = containerView.bounds
        voiceSearchController.view.alpha = 0.0
        voiceSearchController.buttonsContainer.transform = .identity.translatedBy(x: 0.0, y: UX.buttonsContainerInitialTranslationY)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: UX.presentationAnimationSpringDumping,
            initialSpringVelocity: UX.presentationAnimationSpringVelocity,
            options: .curveEaseOut,
            animations: {
                voiceSearchController.view.alpha = 1.0
                voiceSearchController.buttonsContainer.transform = .identity
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            }
        )
    }
    
    private func animateDismissalViaCrossDissolve(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to),
              let snapshotView = presentedController.view.snapshotView(afterScreenUpdates: false),
              let dismissedController = transitionContext.viewController(forKey: .from) as? VoiceSearchViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        snapshotView.alpha = 0.0
        
        containerView.addSubview(dismissedController.view)
        containerView.addSubview(snapshotView)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: UX.presentationAnimationSpringDumping,
            initialSpringVelocity: UX.presentationAnimationSpringVelocity,
            options: .curveEaseOut,
            animations: {
                snapshotView.alpha = 1.0
                dismissedController.buttonsContainer.transform = CGAffineTransform(
                    translationX: 0.0,
                    y: UX.buttonsContainerInitialTranslationY
                )
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            }
        )
    }

    private func animateDismissalViaSliding(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to),
              let snapshotView = presentedController.view.snapshotView(afterScreenUpdates: false),
              let dismissedController = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        snapshotView.layer.cornerRadius = UX.screenCornerRadius
        snapshotView.layer.masksToBounds = true
        snapshotView.transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)
        
        let scrimView = UIView(frame: containerView.bounds)
        scrimView.backgroundColor = theme.colors.layerScrim.withAlphaComponent(UX.scrimAlpha)
    
        containerView.addSubview(dismissedController.view)
        containerView.addSubview(scrimView)
        containerView.addSubview(snapshotView)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            options: .curveEaseOut
        ) {
            snapshotView.transform = .identity
            dismissedController.view.transform = CGAffineTransform(
                translationX: -containerView.bounds.width * UX.dismissalTranslationFactor,
                y: 0.0
            )
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
    }
}

public final class VoiceSearchViewController: UIViewController, Themeable {
    private struct UX {
        static let buttonPadding: CGFloat = 26.0
        static let buttonContentInset = NSDirectionalEdgeInsets(
            top: UX.buttonPadding,
            leading: UX.buttonPadding,
            bottom: UX.buttonPadding,
            trailing: UX.buttonPadding
        )
        static let buttonsSpacing: CGFloat = 11.0
        static let buttonsContainerBottomPadding: CGFloat = 12.0
        static let recordWaveEffectSize: CGFloat = 400.0
        static let recordWaveEffectBottomPadding = recordWaveEffectSize / 3.0
        static let audioWaveformTopPadding: CGFloat = 37.0
        static let audioWaveformSize = CGSize(width: 18.0, height: 35)
    }

    // MARK: - Properties
    private let backgroundBlur: UIVisualEffectView = .build {
        $0.effect = UIBlurEffect(style: .systemMaterial)
    }
    private let backgroundRecordEffect: GradientCircleView = .build()
    private let audioWaveform: AudioWaveformView = .build()
    private let recordButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.microphone)?
            .withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.buttonContentInset
    }
    private let closeButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.buttonContentInset
    }
    let buttonsContainer: UIStackView = .build {
        $0.axis = .horizontal
        $0.spacing = UX.buttonsSpacing
    }
    private lazy var transitionAnimator = VoiceSearchPresentationAnimator(theme: themeManager.getCurrentTheme(for: currentWindowUUID))

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol

    public init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionAnimator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        backgroundRecordEffect.startAnimating()
        audioWaveform.startAnimating()
        closeButton.addAction(UIAction(handler: { [weak self] _ in
            self?.transitionAnimator.dismissWithCrossDissolveTransition = false
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        
        recordButton.addAction(UIAction(handler: { [weak self] _ in
            self?.transitionAnimator.dismissWithCrossDissolveTransition = true
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
    }

    private func setupSubviews() {
        let leadingButtonContainerSpacer = UIView()
        let trailingButtonContainerSpacer = UIView()
        buttonsContainer.addArrangedSubview(leadingButtonContainerSpacer)
        buttonsContainer.addArrangedSubview(recordButton)
        buttonsContainer.addArrangedSubview(closeButton)
        buttonsContainer.addArrangedSubview(trailingButtonContainerSpacer)
        view.addSubviews(backgroundRecordEffect, backgroundBlur, audioWaveform, buttonsContainer)

        NSLayoutConstraint.activate([
            audioWaveform.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                               constant: UX.audioWaveformTopPadding),
            audioWaveform.heightAnchor.constraint(equalToConstant: UX.audioWaveformSize.height),
            audioWaveform.widthAnchor.constraint(equalToConstant: UX.audioWaveformSize.width),
            audioWaveform.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            backgroundRecordEffect.widthAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.heightAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundRecordEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                           constant: UX.recordWaveEffectBottomPadding),

            buttonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -UX.buttonsContainerBottomPadding),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Make spacer views expand equally to center the buttons in the button container
            leadingButtonContainerSpacer.widthAnchor.constraint(equalTo: trailingButtonContainerSpacer.widthAnchor)
        ])
        backgroundBlur.pinToSuperview()
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer2
        recordButton.configuration?.baseBackgroundColor = theme.colors.iconPrimary
        recordButton.configuration?.baseForegroundColor = theme.colors.layer2
        closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
        closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        backgroundRecordEffect.applyTheme(theme: theme)
        audioWaveform.applyTheme(theme: theme)
    }
}

@available(iOS 17, *)
#Preview {
    class MockPresentingViewController: UIViewController {
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            view.backgroundColor = .cyan
            let voiceSearchVC = VoiceSearchViewController(
                windowUUID: .XCTestDefaultUUID,
                themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
            )
            present(voiceSearchVC, animated: true)
        }
    }

    return MockPresentingViewController()
}
