// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public final class QuickAnswersViewController: UIViewController, Themeable {
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
        static let audioWaveformSize = CGSize(width: 18.0, height: 25.0)
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
    private let audioWaveform: AudioWaveformView = .build()
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
    private let privacyButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.image = UIImage(
            named: UX.privacyButtonImageName,
            in: .module,
            with: nil
        )
        // TODO: - FXIOS-14720 Add Strings and accessibility ids
        $0.configuration?.attributedTitle = AttributedString(
            "Protected by Firefox",
            attributes: AttributeContainer([.font: FXFontStyles.Regular.body.scaledFont()])
        )
        $0.configuration?.imagePadding = UX.privacyButtonImagePadding
        $0.configuration?.contentInsets = UX.privacyButtonContentInset
        $0.configuration?.cornerStyle = .fixed
        $0.configuration?.background.cornerRadius = UX.privacyButtonCornerRadius
    }
    private let contentView: QuickAnswersContentView = .build()
    private let transitionAnimator: TransitionAnimator

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol
    private weak var navigationHandler: QuickAnswersNavigationHandler?
    private let viewModel: QuickAnswersViewModel

    public convenience init(
        navigationHandler: QuickAnswersNavigationHandler?,
        presentationTransitionType: QuickAnswersTransitionType = .crossDissolve,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.init(
            navigationHandler: navigationHandler,
            // TODO: - FXIOS-15245 Add real QuickAnswersService instead of MockQuickAnswersService
            viewModel: QuickAnswersViewModel(service: MockQuickAnswersService()),
            presentationTransitionType: presentationTransitionType,
            windowUUID: windowUUID,
            themeManager: themeManager,
            notificationCenter: notificationCenter
        )
    }

    init(
        navigationHandler: QuickAnswersNavigationHandler?,
        viewModel: QuickAnswersViewModel,
        presentationTransitionType: QuickAnswersTransitionType,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol
    ) {
        self.navigationHandler = navigationHandler
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.transitionAnimator = TransitionAnimator(
            presentationTransitionType: presentationTransitionType,
            themeManager: themeManager,
            windowUUID: windowUUID
        )
        self.viewModel = viewModel
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
        registerViewModelUpdates()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.adjustBottomInsets(for: privacyButton.frame.height)
    }

    private func setupSubviews() {
        view.addSubviews(
            backgroundRecordEffect,
            backgroundBlur,
            audioWaveform,
            contentView,
            closeButton,
            privacyButton
        )

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonSidePadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeButtonSidePadding),

            audioWaveform.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
            audioWaveform.heightAnchor.constraint(equalToConstant: UX.audioWaveformSize.height),
            audioWaveform.widthAnchor.constraint(equalToConstant: UX.audioWaveformSize.width),
            audioWaveform.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            contentView.topAnchor.constraint(equalTo: audioWaveform.bottomAnchor,
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

            privacyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            privacyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            privacyButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                   constant: UX.closeButtonSidePadding),
            privacyButton.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                    constant: -UX.closeButtonSidePadding),
        ])
        backgroundBlur.pinToSuperview()
    }

    private func registerViewModelUpdates() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case .recordVoice(let result, _):
                self?.contentView.configureTranscript(result.text)
            case .loadingSearchResult:
                self?.audioWaveform.stopAnimating()
                self?.contentView.configureSearching()
            case .showSearchResult(let result, _):
                self?.contentView.configureAnswer(result.body)
            }
        }
        viewModel.startRecordingVoice()
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = theme.colors.layer2
        closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
        closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        privacyButton.configuration?.baseBackgroundColor = theme.colors.layerAccentPrivateNonOpaque
        privacyButton.configuration?.baseForegroundColor = theme.colors.textPrimary
        backgroundRecordEffect.applyTheme(theme: theme)
        audioWaveform.applyTheme(theme: theme)
        contentView.applyTheme(theme: theme)
    }
}
