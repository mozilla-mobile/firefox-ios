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
        static let titleFadeDuration: TimeInterval = 0.1
        static let presentationNavigationBarOffset: CGFloat = -20.0
        static let backdropFadeDuration: TimeInterval = 0.2
    }

    // MARK: - Properties
    private lazy var backgroundEffectView = BackgroundEffectView(parentController: self)
    private lazy var closeButton: UIButton = .build { [weak self] in
        $0.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        $0.addAction(
            UIAction(handler: { _ in
                self?.dismiss(with: nil)
            }),
            for: .touchUpInside
        )
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.body.scaledFont()
        $0.adjustsFontForContentSizeCategory = true
        $0.alpha = 0.0
    }
    private let contentView: QuickAnswersContentView = .build()
    private let transitionDelegate: OptInTransitionAnimator

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let windowUUID: WindowUUID
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
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.stringsConfiguration = stringsConfiguration
        // The custom transition animator is only used for the source reveal transition; the form sheet
        // relies on the system presentation.
        var sourceRevealAnimator: SourceRevealTransitionAnimator?
        if case let .sourceReveal(sourceRect) = transitionType {
            sourceRevealAnimator = SourceRevealTransitionAnimator(
                sourceRect: sourceRect,
                isOptInVisible: { [weak viewModel] in
                    viewModel?.isOptInRequired ?? false
                }
            )
        }
        self.transitionDelegate = OptInTransitionAnimator(
            isOptInSheetPending: { [weak viewModel] in
                viewModel?.isOptInSheetRequired ?? false
            },
            fallback: sourceRevealAnimator
        )
        self.viewModel = viewModel
        self.learnMoreURL = learnMoreURL
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = transitionType.modalPresentationStyle
        transitioningDelegate = transitionDelegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.presentationController?.delegate = self
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
        view.addSubviews(
            backgroundEffectView,
            contentView,
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.titleView = titleLabel
        setContentScrollView(contentView.scrollView, for: .top)

        backgroundEffectView.pinToSuperview()

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func registerCallbacks() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .showOptIn:
                self?.showOptIn()
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
                    self?.backgroundEffectView.showResult()
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
        contentView.onTranscriptVisibilityChange = { [weak self] isTranscriptVisible, transcript in
            UIView.animate(withDuration: UX.titleFadeDuration) {
                self?.titleLabel.alpha = isTranscriptVisible ? 0.0 : 1.0
                self?.titleLabel.text = isTranscriptVisible ? nil : transcript
            }
        }
        contentView.configureOptIn(
            strings: stringsConfiguration.optIn,
            learnMoreURL: learnMoreURL,
            theme: themeManager.getCurrentTheme(for: windowUUID),
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

    // MARK: - Opt-in
    private func showOptIn() {
        guard viewModel.feature.isOptInRedesignEnabled else {
            contentView.showOptIn()
            return
        }
        let controller = OptInViewController(
            windowUUID: windowUUID,
            themeManager: themeManager,
            strings: stringsConfiguration.optInRedesign,
            closeAccessibilityLabel: stringsConfiguration.closeAccessibilityLabel,
            onContinue: { [weak self] in
                self?.presentedViewController?.dismiss(animated: true)
                self?.viewModel.completeOptIn()
            },
            onLearnMore: { [weak self] in
                self?.dismiss(with: self?.learnMoreURL)
            },
            onDismiss: { [weak self] in
                self?.dismiss(with: nil)
            }
        )
        present(controller, animated: true) { [weak self] in
            self?.revealBackdrop()
        }
    }

    /// Fades in this screen, which the presentation transition keeps hidden while the opt-in sheet slides up.
    private func revealBackdrop() {
        guard let backdropView = transitionDelegate.hiddenContainerView,
              let superview = backdropView.superview else { return }
        // Cross-dissolved rather than faded in, since the form sheet materials flash while an ancestor's alpha animates.
        UIView.transition(with: superview, duration: UX.backdropFadeDuration, options: .transitionCrossDissolve) {
            backdropView.isHidden = false
        }
    }

    // MARK: - Presentation transition
    func prepareForPresentationTransition(sourceRect: CGRect, isOptInVisible: Bool) {
        contentView.prepareForPresentationTransition(
            sourceRect: sourceRect,
            containerWidth: view.frame.width,
            topInset: navigationController?.navigationBar.frame.maxY ?? 0.0,
            isOptInVisible: isOptInVisible
        )
        backgroundEffectView.alpha = 0.0
        backgroundEffectView.prepareForPresentationTransition()
        navigationController?.navigationBar.transform = CGAffineTransform(
            translationX: 0.0,
            y: UX.presentationNavigationBarOffset
        )
        navigationController?.navigationBar.alpha = 0.0
    }

    func applyPresentationTransition(isOptInVisible: Bool) {
        contentView.applyPresentationTransition(isOptInVisible: isOptInVisible)
        backgroundEffectView.alpha = 1.0
        backgroundEffectView.applyPresentationTransition()
        navigationController?.navigationBar.alpha = 1.0
        navigationController?.navigationBar.transform = .identity
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
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.iconPrimary
        titleLabel.textColor = theme.colors.textPrimary
        contentView.applyTheme(theme: theme)
        backgroundEffectView.applyTheme(theme: theme)
    }
}
