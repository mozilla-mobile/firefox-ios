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
    private lazy var followUpButton: QuickAnswersEntryPointButton = .build(nil) { [weak self] in
        QuickAnswersEntryPointButton {
            self?.startFollowUp()
        }
    }
    /// Keeps the follow-up button collapsed to its icon while the title is hidden.
    private lazy var followUpButtonCollapsedWidth = followUpButton.widthAnchor.constraint(
        equalToConstant: UX.followUpButtonSize
    )
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
        view.addSubviews(
            backgroundEffectView,
            contentView,
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        navigationItem.titleView = titleLabel
        setContentScrollView(contentView.scrollView, for: .top)

        backgroundEffectView.pinToSuperview()

        backgroundEffectView.pinToSuperview()

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupFollowUpToolbar() {
        followUpButton.accessibilityLabel = stringsConfiguration.followUpAccessibilityLabel
        // TODO: localize the follow-up title.
        followUpButton.configuration?.title = "Ask a follow-up"
        followUpButton.configuration?.imagePadding = UX.followUpButtonImagePadding
        followUpButton.configuration?.contentInsets = UX.followUpButtonContentInsets
        followUpButton.contentHorizontalAlignment = .leading
        followUpButton.clipsToBounds = true
        followUpButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = FXFontStyles.Bold.body.scaledFont()
            return attributes
        }
        NSLayoutConstraint.activate([
            followUpButtonCollapsedWidth,
            followUpButton.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.followUpButtonSize),
            followUpButton.heightAnchor.constraint(equalToConstant: UX.followUpButtonSize),
        ])
        let followUpItem = UIBarButtonItem(customView: followUpButton)
        if #available(iOS 26, *) {
            followUpItem.hidesSharedBackground = true
        }
        toolbarItems = [.flexibleSpace(), followUpItem, .flexibleSpace()]
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
                    self?.backgroundEffectView.showResult()
                    self?.showResultBackground()
                    self?.showFollowUpButton()
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
    func prepareForPresentationTransition(sourceRect: CGRect, isOptInVisible: Bool) {
        contentView.prepareForPresentationTransition(
            sourceRect: sourceRect,
            containerWidth: view.frame.width,
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

    private func showFollowUpButton() {
        navigationController?.setToolbarHidden(false, animated: true)
        guard followUpButton.configuration?.title != nil else { return }
        animateFollowUpTitle(isVisible: true, delay: UX.followUpTitleRevealDelay) { [weak self] in
            self?.animateFollowUpTitle(isVisible: false, delay: UX.followUpTitleVisibleDuration) {
                self?.followUpButton.configuration?.title = nil
            }
        }
    }

    private func animateFollowUpTitle(isVisible: Bool, delay: TimeInterval, completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: UX.followUpTitleRevealDuration,
            delay: delay,
            usingSpringWithDamping: UX.followUpTitleRevealDamping,
            initialSpringVelocity: 0.0
        ) { [self] in
            followUpButtonCollapsedWidth.isActive = !isVisible
            navigationController?.toolbar.layoutIfNeeded()
        } completion: { _ in
            completion()
        }
    }

    private func startFollowUp() {
        navigationController?.setToolbarHidden(true, animated: true)
        withAnimation(.easeInOut(duration: UX.followUpFadeOutDuration)) {
            backgroundEffectState.isShowingResult = false
        }
        UIView.animate(withDuration: UX.followUpFadeOutDuration, delay: 0.0, options: .curveEaseIn) { [self] in
            titleLabel.alpha = 0.0
        }
        contentView.hideForFollowUp(duration: UX.followUpFadeOutDuration) { [weak self] in
            self?.restartFlow()
        }
    }

    private func restartFlow() {
        titleLabel.text = nil
        transcript = ""
        contentView.resetForFollowUp()
        followUpButton.configuration?.title = nil
        viewModel.startFollowUp()
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
        closeButton.tintColor = theme.colors.iconPrimary
        titleLabel.textColor = theme.colors.textPrimary
        followUpButton.configure(theme: theme, shouldStartGlowing: false)
        followUpButton.configuration?.baseForegroundColor = theme.colors.textPrimary
        contentView.applyTheme(theme: theme)
        backgroundEffectView.applyTheme(theme: theme)
    }
}
