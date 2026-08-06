// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
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
        static let recordWaveEffectSize: CGFloat = 450.0
        static let recordWaveEffectBottomPadding = 150.0
        static let recordWaveEffectResultOpacity: CGFloat = 0.3
        static let contentViewTopPadding: CGFloat = 32.0
        static let contentViewBottomPadding: CGFloat = 12.0
        static let contentViewHorizontalPadding: CGFloat = 24.0
    }

    // MARK: - Properties
    private let backgroundBlur: UIVisualEffectView = .build {
        $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }
    private let backgroundRecordEffect: GradientCircleView = .build()
    private lazy var closeButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.closeButtonContentInset
        $0.addAction(
            UIAction(handler: { [weak self] _ in
                self?.dismiss(with: nil)
            }),
            for: .touchUpInside
        )
        // TODO: - FXIOS-14720 add Strings
        $0.accessibilityLabel = "Close"
    }
    private let contentView: QuickAnswersContentView = .build()
    private let transitionAnimator: CrossDissolveTransitionAnimator?

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol
    private weak var navigationHandler: QuickAnswersNavigationHandler?
    private let viewModel: QuickAnswersViewModel
    private let learnMoreURL: URL?
    private lazy var errorHandler = ErrorHandler(
        presenter: self,
        onDismiss: { [weak self] in
            self?.dismiss(with: nil)
        }
    )
    private var hasAppeared = false

    public convenience init(
        navigationHandler: QuickAnswersNavigationHandler?,
        transitionType: QuickAnswersTransitionType,
        prefs: Prefs,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher,
        learnMoreURL: URL?,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
    ) {
        self.init(
            navigationHandler: navigationHandler,
            viewModel: QuickAnswersViewModel(prefs: prefs, telemetry: telemetry, configFetcher: configFetcher),
            transitionType: transitionType,
            windowUUID: windowUUID,
            themeManager: themeManager,
            learnMoreURL: learnMoreURL,
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
        notificationCenter: NotificationProtocol
    ) {
        self.navigationHandler = navigationHandler
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        // The custom transition animator is only used for the cross dissolve transition; the form sheet
        // relies on the system presentation.
        if case let .crossDissolve(sourceRect) = transitionType {
            self.transitionAnimator = CrossDissolveTransitionAnimator(
                themeManager: themeManager,
                windowUUID: windowUUID,
                sourceRect: sourceRect
            )
        } else {
            self.transitionAnimator = nil
        }
        self.viewModel = viewModel
        self.learnMoreURL = learnMoreURL
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
        view.addSubviews(
            backgroundRecordEffect,
            backgroundBlur,
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

            backgroundRecordEffect.widthAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.heightAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundRecordEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                           constant: UX.recordWaveEffectBottomPadding),
        ])
        backgroundBlur.pinToSuperview()
    }

    private func registerCallbacks() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .showOptIn:
                self?.contentView.showOptIn()
            case .recordingStarted:
                self?.backgroundRecordEffect.startAnimating()
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
                    self?.backgroundRecordEffect.alpha = UX.recordWaveEffectResultOpacity
                    self?.contentView.configureAnswer(result.resultText, modelName: self?.viewModel.modelDisplayName ?? "")
                    self?.contentView.configureSources(result.sources) { [weak self] url in
                        self?.viewModel.recordCitationTapped()
                        self?.dismiss(with: url)
                    }
                }
            }
        }
        contentView.configureOptIn(
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
        view.backgroundColor = theme.colors.layer2
        closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
        closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        backgroundRecordEffect.applyTheme(theme: theme)
        contentView.applyTheme(theme: theme)
    }
}
