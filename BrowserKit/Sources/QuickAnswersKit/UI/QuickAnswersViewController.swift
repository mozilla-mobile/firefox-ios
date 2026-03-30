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
        static let responseViewTopPadding: CGFloat = 32.0
        static let responseViewBottomPadding: CGFloat = 12.0
        static let responseViewHorizontalPadding: CGFloat = 24.0
    }

    // MARK: - Properties
    private let backgroundBlur: UIVisualEffectView = .build {
        $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }
    private let backgroundRecordEffect: GradientCircleView = .build()
    private let audioWaveform: AudioWaveformView = .build()
    private let closeButton: UIButton = .build {
        if #available(iOS 26, *) {
            $0.configuration = .prominentGlass()
        } else {
            $0.configuration = .filled()
        }
        $0.configuration?.cornerStyle = .capsule
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        $0.configuration?.contentInsets = UX.closeButtonContentInset
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

    private func setupSubviews() {
        view.addSubviews(backgroundRecordEffect, backgroundBlur, audioWaveform, contentView, closeButton)

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
                                             constant: UX.responseViewTopPadding),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                 constant: UX.responseViewHorizontalPadding),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.responseViewHorizontalPadding),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                constant: -UX.responseViewBottomPadding),

            backgroundRecordEffect.widthAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.heightAnchor.constraint(equalToConstant: UX.recordWaveEffectSize),
            backgroundRecordEffect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundRecordEffect.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                           constant: UX.recordWaveEffectBottomPadding),
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
        backgroundRecordEffect.applyTheme(theme: theme)
        audioWaveform.applyTheme(theme: theme)
        contentView.applyTheme(theme: theme)
    }
}
