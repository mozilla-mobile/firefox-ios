// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// The possible transition types to animate presentation and dismissal of `QuickAnswersViewController`.
public enum QuickAnswersTransitionType: Equatable, Sendable {
    /// A custom cross dissolve that zooms the controller in from `sourceRect`.
    case crossDissolve(sourceRect: CGRect)
    /// A system form sheet presentation, used on iPad.
    case formSheet

    var modalPresentationStyle: UIModalPresentationStyle {
        switch self {
        case .crossDissolve:
            return .custom
        case .formSheet:
            return .formSheet
        }
    }
}

/// The animator for a custom cross dissolve presentation and dismissal.
/// It adds a zoom in and fade from the provided source rect when presenting.
/// The dismissal is a simple cross dissolve.
final class CrossDissolveTransitionAnimator: NSObject,
                                             UIViewControllerTransitioningDelegate,
                                             UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let springAnimationDuration: TimeInterval = 0.4
        static let springAnimationDamping: CGFloat = 0.8
        static let springAnimationVelocity: CGFloat = 1.0
        static let crossDissolveInitialScale: CGFloat = 0.2
    }
    private let themeManager: any ThemeManager
    private let windowUUID: WindowUUID
    /// The rect, in the container view's coordinate space, the cross dissolve presentation
    /// animation originates from.
    private let sourceRect: CGRect

    init(
        themeManager: any ThemeManager,
        windowUUID: WindowUUID,
        sourceRect: CGRect
    ) {
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.sourceRect = sourceRect
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return self
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // The duration is set to 0.0 since the transition implements its custom animation duration
        return 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresenting = transitionContext.viewController(forKey: .to) is QuickAnswersViewController
        guard isPresenting else {
            animateDismissal(transitionContext)
            return
        }
        animatePresentation(transitionContext)
    }

    // MARK: - Presentation
    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to) as? QuickAnswersViewController else {
            transitionContext.completeTransition(false)
            return
        }
//        UIApplication.shared.windows.first?.layer.speed = 0.1
        
        let button = AudioWaveformView()
        button.frame = sourceRect
        button.applyTheme(theme: LightTheme())
        button.startAnimating()

        let containerView = transitionContext.containerView
        let maxSize = max(containerView.bounds.width, containerView.bounds.height) * 2.3
        let view = UIView(
            frame: CGRect(
                origin: CGPoint(
                    x: -maxSize / 2.0 + sourceRect.midX,
                    y: -maxSize / 2.0 + sourceRect.midY
                ),
                size: CGSize(width: maxSize, height: maxSize)
            )
        )
        let mask = CAGradientLayer()
        mask.frame = view.bounds
        mask.type = .radial
        mask.startPoint = CGPoint(x: 0.5, y: 0.5) // Center
        mask.endPoint = CGPoint(x: 1.0, y: 1.0)   // Circular edge
        mask.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor,
        ]
        mask.locations = [0, 0.9, 1]
        view.layer.mask = mask
        view.backgroundColor = .red
        view.layer.cornerRadius = maxSize / 2.0

        containerView.addSubview(presentedController.view)
        presentedController.view.mask = view
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.frame = containerView.bounds
        containerView.addSubview(blur)
        containerView.addSubview(button)
        blur.alpha = 0.0
        
        view.transform = .init(scaleX: 0.01, y: 0.01)
        
        let transform = CGAffineTransform(translationX: 0.0, y: 30.0)
        
        presentedController.contentView.audioWaveform.alpha = 0.0
        presentedController.contentView.placeholderLabel.transform = transform
        presentedController.backgroundRecordEffect.transform = transform
        presentedController.closeButton.transform = CGAffineTransform(translationX: 0.0, y: -50.0)

        
        UIView.animateKeyframes(withDuration: 0.4, delay: 0.0) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                blur.alpha = 1.0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                view.transform = .identity
                button.frame = CGRect(
                    origin: CGPoint(
                        x: containerView.bounds.midX - 9,
                        y: 25/2 + 32 + 32 + presentedController.view.safeAreaInsets.top
                    ),
                    size: CGSize(width: 18.0, height: 25)
                )
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2) {
                blur.alpha = 0.0
                presentedController.contentView.audioWaveform.alpha = 1.0
                presentedController.contentView.placeholderLabel.transform = .identity
                presentedController.backgroundRecordEffect.transform = .identity
                presentedController.closeButton.transform = .identity
            }
            UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 0.1) {
                button.alpha = 0.0
            }
        } completion: { _ in
            button.removeFromSuperview()
            blur.removeFromSuperview()
            presentedController.view.mask = nil
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Dismissal
    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentingController = transitionContext.viewController(forKey: .to),
              // We can't add the presenting controller to the containerView since it is going to be removed
              // from its original superview, thus we need a snapshot.
                let snapshotView = presentingController.view.snapshotView(afterScreenUpdates: false) else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        let maxSize = max(containerView.bounds.width, containerView.bounds.height) * 2
        let view = UIView(
            frame: CGRect(
                origin: CGPoint(
                    x: -maxSize / 2.0 + sourceRect.midX,
                    y: -maxSize / 2.0 + sourceRect.midY
                ),
                size: CGSize(width: maxSize, height: maxSize)
            )
        )
        let mask = CAGradientLayer()
        mask.frame = view.bounds
        mask.type = .radial
        mask.startPoint = CGPoint(x: 0.5, y: 0.5) // Center
        mask.endPoint = CGPoint(x: 1.0, y: 1.0)   // Circular edge
        mask.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor,
        ]
        mask.locations = [0, 0.9, 1]
        view.layer.mask = mask
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.frame = presentingController.view.bounds
        presentingController.view.addSubview(blur)
        view.backgroundColor = .red
        view.layer.cornerRadius = maxSize / 2.0
        containerView.mask = view
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut) {
            view.transform = .init(scaleX: 0.01, y: 0.01)
        } completion: { _ in
            blur.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.1) {
            blur.alpha = 0.0
        }
    }
}

import Shared

// swiftlint: disable all
struct Tel: QuickAnswersTelemetry {
    func quickAnswersRequested(model: QuickAnswersModel) {
        
    }
    
    func recordingStarted() {
        
    }
    
    func recordingCompleted(outcome: Bool, errorType: String?) {
        
    }
    
    func resultsStarted() {
        
    }
    
    func resultsCompleted(outcome: Bool, errorType: String?, model: QuickAnswersModel) {
        
    }
    
    func permissionDenied(permission: QuickAnswersPermission) {
        
    }
    
    func citationTapped() {
        
    }
    
    func closed() {
            
    }
    
    func consentShown(agreed: Bool) {
        
    }
}

@available(iOS 26, *)
class Contr: UIViewController, QuickAnswersNavigationHandler {
    func dismissQuickAnswers(with navigationType: QuickAnswersNavigationType?) {
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        UIApplication.shared.windows.first?.layer.speed = 0.2
        let button = UIButton()
        button.configuration = .prominentClearGlass()
        button.configuration?.image = UIImage(systemName: "waveform")
        button.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16.0),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16.0)
        ])
        
        button.addAction(
            UIAction(
                handler: { _ in
                    let pref = MockProfilePrefs()
                    pref.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
                    let quickAnswer = QuickAnswersViewController(
                        navigationHandler: self,
                        viewModel: QuickAnswersViewModel(prefs: pref, telemetry: Tel()),
                        transitionType: .crossDissolve(sourceRect: button.frame),
                        windowUUID: .DefaultUITestingUUID,
                        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
                        learnMoreURL: nil,
                        stringsConfiguration: .init(
                            optIn: .init(
                                title: "",
                                description: "",
                                learnMore: "",
                                continueButton: ""
                            ),
                            contentView: .init(
                                placeholder: "Listening, ask a question",
                                answering: "",
                                footerFormat: "",
                                sources: ""
                            ),
                            errors: .init(
                                permissionAlertTitle: "",
                                microphonePermissionMessage: "",
                                speechRecognitionPermissionMessage: "",
                                openSettings: "",
                                cancel: "",
                                dailyLimitTitle: "",
                                dailyLimitMessage: "",
                                genericErrorTitle: "",
                                genericErrorMessage: "",
                                ok: ""
                            ),
                            closeAccessibilityLabel: "",
                            appName: ""
                        ),
                        notificationCenter: NotificationCenter.default
                    )
                
                    self.present(quickAnswer, animated: true)
            }),
            for: .allEvents
        )
    }
}

@available(iOS 26, *)
#Preview {
    Contr()
}
