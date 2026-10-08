// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Shared

// TODO: - FXIOS-16295 improve VoiceOver by adding notification announcement before and after recording.
public final class QuickAnswersViewController: UIViewController,
                                               UIAdaptivePresentationControllerDelegate,
                                               Themeable {
    private struct UX {
        static let closeButtonSidePadding: CGFloat = 16.0
        static let closeButtonPadding: CGFloat = 13.0
        static let closeButtonContentInset = NSDirectionalEdgeInsets(
            top: UX.closeButtonPadding,
            leading: UX.closeButtonPadding,
            bottom: UX.closeButtonPadding,
            trailing: UX.closeButtonPadding
        )
        static let recordWaveEffectResultOpacity: CGFloat = 0.4
        static let recordWaveEffectFadeDuration: TimeInterval = 0.3
        static let recordWaveEffectFadeDelay: TimeInterval = 0.2
        static let contentViewTopPadding: CGFloat = 32.0
        static let contentViewBottomPadding: CGFloat = 12.0
        static let contentViewHorizontalPadding: CGFloat = 24.0
        static let presentationSlideOffset: CGFloat = 50.0
        static let presentationCloseButtonOffset: CGFloat = -20.0
    }

    // MARK: - Properties
    private let backgroundRecordEffect: UIHostingController<BackgroundEffectView>
    private lazy var closeButton: UIButton = .build { [weak self] in
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.closeButtonContentInset
        $0.addAction(
            UIAction(handler: { _ in
                self?.dismiss(with: nil)
            }),
            for: .touchUpInside
        )
    }
    private let contentView: QuickAnswersContentView = .build()
    private let transitionAnimator: SourceRevealTransitionAnimator?

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol
    private weak var navigationHandler: QuickAnswersNavigationHandler?
    private let viewModel: QuickAnswersViewModel
    private let learnMoreURL: URL?
    private let stringsConfiguration: QuickAnswersViewConfiguration
    private lazy var errorHandler = ErrorHandler(
        presenter: self,
        strings: stringsConfiguration.errors,
        onDismiss: { [weak self] in
            self?.dismiss(with: nil)
        }
    )
    private var hasAppeared = false
    private lazy var privacyTipPresenter = QuickAnswersPrivacyTipPresenter(
        presenter: self,
        strings: stringsConfiguration.privacyBanner
    )

    public convenience init(
        navigationHandler: QuickAnswersNavigationHandler?,
        transitionType: QuickAnswersTransitionType,
        prefs: Prefs,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher,
        learnMoreURL: URL?,
        stringsConfiguration: QuickAnswersViewConfiguration,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
    ) {
        self.init(
            navigationHandler: navigationHandler,
            viewModel: QuickAnswersViewModel(prefs: prefs, telemetry: telemetry, configFetcher: configFetcher),
            transitionType: transitionType,
            windowUUID: windowUUID,
            themeManager: themeManager,
            learnMoreURL: learnMoreURL,
            stringsConfiguration: stringsConfiguration,
            notificationCenter: notificationCenter
        )
    }

    init(
        navigationHandler: QuickAnswersNavigationHandler?,
        viewModel: QuickAnswersViewModel,
        transitionType: QuickAnswersTransitionType,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        learnMoreURL: URL?,
        stringsConfiguration: QuickAnswersViewConfiguration,
        notificationCenter: NotificationProtocol
    ) {
        self.navigationHandler = navigationHandler
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.stringsConfiguration = stringsConfiguration
        // The custom transition animator is only used for the source reveal transition; the form sheet
        // relies on the system presentation.
        if case let .sourceReveal(sourceRect) = transitionType {
            self.transitionAnimator = SourceRevealTransitionAnimator(
                sourceRect: sourceRect,
                isOptInVisible: viewModel.isOptInRequired
            )
        } else {
            self.transitionAnimator = nil
        }
        self.viewModel = viewModel
        self.learnMoreURL = learnMoreURL
        self.backgroundRecordEffect = UIHostingController(
            rootView: BackgroundEffectView(windowUUID: windowUUID, themeManager: themeManager)
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = transitionType.modalPresentationStyle
        transitioningDelegate = transitionAnimator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        setupSubviews()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        registerCallbacks()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Workaround for iPad: with formSheet presentation, viewWillAppear can fire twice when the
        // user attempts to dismiss the sheet but the dismissal fails, so guard the one-time flow start.
        guard !hasAppeared else { return }
        hasAppeared = true
        viewModel.startFlow()
    }

    private func setupSubviews() {
        closeButton.accessibilityLabel = stringsConfiguration.closeAccessibilityLabel
        contentView.configureStrings(stringsConfiguration.contentView)
        setupBackgroundEffect()
        view.addSubviews(
            contentView,
            closeButton,
        )

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonSidePadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeButtonSidePadding),

            contentView.topAnchor.constraint(equalTo: closeButton.bottomAnchor,
                                             constant: UX.contentViewTopPadding),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                 constant: UX.contentViewHorizontalPadding),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -UX.contentViewHorizontalPadding),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                constant: -UX.contentViewBottomPadding),
        ])
    }

    private func setupBackgroundEffect() {
        addChild(backgroundRecordEffect)
        backgroundRecordEffect.view.translatesAutoresizingMaskIntoConstraints = false
        backgroundRecordEffect.view.backgroundColor = .clear
        view.addSubview(backgroundRecordEffect.view)
        backgroundRecordEffect.view.pinToSuperview()
        backgroundRecordEffect.didMove(toParent: self)
    }

    private func registerCallbacks() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .showOptIn:
                self?.contentView.showOptIn()
            case .recordingStarted:
                self?.contentView.startAudioWaveformAnimation()
            case .speechResult(let result, let error):
                if let error {
                    self?.errorHandler.handleSpeechError(error)
                } else {
                    self?.contentView.configureTranscript(result.text)
                }
            case .loadingSearchResult:
                UIAccessibility.post(notification: .screenChanged, argument: self?.contentView)
                self?.triggerHaptic()
                self?.contentView.configureSearching()
            case .showSearchResult(let result, let error):
                if let error {
                    self?.errorHandler.handleSearchError(error)
                } else {
                    self?.triggerHaptic()
                    self?.fadeBackgroundEffectForResult()
                    self?.contentView.configureResult(
                        result.resultText,
                        modelName: self?.viewModel.modelDisplayName ?? "",
                        sources: result.sources
                    ) { [weak self] url in
                        self?.viewModel.recordCitationTapped()
                        self?.dismiss(with: url)
                    }
                }
            }
        }
        contentView.configureOptIn(
            strings: stringsConfiguration.optIn,
            learnMoreURL: learnMoreURL,
            theme: themeManager.getCurrentTheme(for: currentWindowUUID),
            onContinue: { [weak self] in
                self?.contentView.hideOptIn()
                self?.viewModel.completeOptIn()
            },
            onLearnMore: { [weak self] url in
                self?.dismiss(with: url)
            }
        )
        if #available(iOS 17.0, *) {
            contentView.configurePrivacyLink { [weak self] in
                self?.presentPrivacyTip()
            }
        }
    }

    @available(iOS 17.0, *)
    private func presentPrivacyTip() {
        privacyTipPresenter.present(
            from: contentView.privacyTipSourceView,
            iconColor: themeManager.getCurrentTheme(for: currentWindowUUID).colors.textSecondary
        )
    }

    // MARK: - Presentation transition
    func prepareForPresentationTransition() {
        contentView.prepareForPresentationTransition()
        backgroundRecordEffect.view.alpha = 0.0
        backgroundRecordEffect.view.transform = CGAffineTransform(translationX: 0.0,
                                                                  y: UX.presentationSlideOffset)
        closeButton.transform = CGAffineTransform(translationX: 0.0, y: UX.presentationCloseButtonOffset)
        closeButton.alpha = 0.0
    }

    func applyPresentationTransition(isOptInVisible: Bool) {
        contentView.applyPresentationTransition(isOptInVisible: isOptInVisible)
        backgroundRecordEffect.view.alpha = 1.0
        backgroundRecordEffect.view.transform = .identity
        closeButton.alpha = 1.0
        closeButton.transform = .identity
    }

    private func fadeBackgroundEffectForResult() {
        UIView.animate(withDuration: UX.recordWaveEffectFadeDuration,
                       delay: UX.recordWaveEffectFadeDelay) { [self] in
            backgroundRecordEffect.view.alpha = UX.recordWaveEffectResultOpacity
        }
    }

    private func dismiss(with url: URL?) {
        triggerHaptic()
        viewModel.dismiss()
        navigationHandler?.dismissQuickAnswers(with: url.flatMap(QuickAnswersNavigationType.url))
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismiss(with: nil)
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer1
        closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
        closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        contentView.applyTheme(theme: theme)
    }
}
