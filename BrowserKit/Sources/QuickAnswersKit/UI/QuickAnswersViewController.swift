// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

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
        static let recordWaveEffectSize: CGFloat = 400.0
        static let recordWaveEffectBottomPadding = recordWaveEffectSize / 3.0
        static let contentViewTopPadding: CGFloat = 32.0
        static let contentViewBottomPadding: CGFloat = 12.0
        static let contentViewHorizontalPadding: CGFloat = 24.0
        static let privacyButtonContentInset = NSDirectionalEdgeInsets(
            top: 8.0,
            leading: 8.0,
            bottom: 8.0,
            trailing: 12.0
        )
        static let privacyButtonImagePadding: CGFloat = 4.0
        static let privacyButtonCornerRadius: CGFloat = 16.0
        static let privacyButtonImageName = "shield"
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
                self?.navigationHandler?.dismissQuickAnswers(with: nil)
            }),
            for: .touchUpInside
        )
    }
    private let contentView: QuickAnswersContentView = .build()
    private let transitionAnimator: CrossDissolveTransitionAnimator?

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol
    private weak var navigationHandler: QuickAnswersNavigationHandler?
    private let viewModel: QuickAnswersViewModel
    private let store: Store
    private lazy var errorHandler = ErrorHandler(
        presenter: self,
        navigationHandler: navigationHandler
    )

    public convenience init(
        navigationHandler: QuickAnswersNavigationHandler?,
        transitionType: QuickAnswersTransitionType,
        prefs: Prefs,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
    ) {
        self.init(
            navigationHandler: navigationHandler,
            viewModel: QuickAnswersViewModel(prefs: prefs),
            store: Store(prefs: prefs),
            transitionType: transitionType,
            windowUUID: windowUUID,
            themeManager: themeManager,
            notificationCenter: notificationCenter
        )
    }

    init(
        navigationHandler: QuickAnswersNavigationHandler?,
        viewModel: QuickAnswersViewModel,
        store: Store,
        transitionType: QuickAnswersTransitionType,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
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
        self.store = store
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
        startFlow()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        // if the optin is not completed at time of dismissal stopRecording triggers permission request, thus
        // we'd show a permission alert on dismissal which we don't want.
        if store.isOptInCompleted {
            // TODO: FXIOS-14880 - Possibly investigate a better way to call this via view model
            Task {
                try await viewModel.stopRecordingVoice()
            }
        }
        super.viewDidDisappear(animated)
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

    private func startFlow() {
        guard store.isOptInCompleted else {
            contentView.showOptIn()
            return
        }
        backgroundRecordEffect.startAnimating()
        contentView.startAudioWaveformAnimation()
        viewModel.startRecordingVoice()
    }

    private func registerCallbacks() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .recordVoice(let result, let error):
                if let error {
                    self?.errorHandler.handleSpeechError(error)
                } else {
                    self?.contentView.configureTranscript(result.text)
                }
            case .loadingSearchResult:
                self?.contentView.configureSearching()
            case .showSearchResult(let result, let error):
                if let error {
                    self?.errorHandler.handleSearchError(error)
                } else {
                    self?.contentView.configureAnswer(result.resultText)
                    self?.contentView.configureSources(result.sources)
                }
            case .initializationFailed:
                self?.errorHandler.handleInitializationError()
            }
        }
        contentView.configureOptIn(
            onContinue: { [weak self] in
                self?.store.setOptInCompleted()
                self?.contentView.hideOptIn()
                self?.startFlow()
            },
            onLearnMore: { [weak self] url in
                self?.navigationHandler?.dismissQuickAnswers(with: .url(url))
            }
        )
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        navigationHandler?.dismissQuickAnswers(with: nil)
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
