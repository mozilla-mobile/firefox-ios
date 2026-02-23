// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

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
        static let engineToggleTopPadding: CGFloat = 16.0
        static let engineToggleLabelSpacing: CGFloat = 8.0
        static let contentViewTopPadding: CGFloat = 16.0
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
    private let engineToggleContainer: UIStackView = .build {
        $0.axis = .horizontal
        $0.spacing = UX.engineToggleLabelSpacing
        $0.alignment = .center
    }
    private let engineToggleLabel: UILabel = .build {
        $0.text = "Use New API (iOS 26+)"
        $0.font = .preferredFont(forTextStyle: .subheadline)
    }
    private let engineToggleSwitch: UISwitch = .build {
        if #available(iOS 26.0, *) {
            $0.isOn = false
        } else {
            $0.isOn = false
            $0.isEnabled = false
        }
    }
    private let contentView: VoiceSearchContentView = .build()
    private let transitionAnimator: TransitionAnimator

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol
    private let viewModel: VoiceSearchViewModel
    private weak var navigationHandler: VoiceSearchNavigationHandler?

    public init(
        navigationHandler: VoiceSearchNavigationHandler?,
        presentationTransitionType: VoiceSearchTransitionType = .crossDissolve,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.viewModel = VoiceSearchViewModel(service: DefaultVoiceSearchService())
        self.navigationHandler = navigationHandler
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.transitionAnimator = TransitionAnimator(
            presentationTransitionType: presentationTransitionType,
            themeManager: themeManager,
            windowUUID: windowUUID
        )
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
        configureButtons()
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        viewModel.onStateChange = { [weak self] in
            self?.onStateChange(state: $0)
        }
        viewModel.startRecordingVoice()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        backgroundRecordEffect.startAnimating()
        audioWaveform.startAnimating()
    }

    private func setupSubviews() {
        let leadingButtonContainerSpacer = UIView()
        let trailingButtonContainerSpacer = UIView()
        buttonsContainer.addArrangedSubview(leadingButtonContainerSpacer)
        buttonsContainer.addArrangedSubview(recordButton)
        buttonsContainer.addArrangedSubview(closeButton)
        buttonsContainer.addArrangedSubview(trailingButtonContainerSpacer)

        engineToggleContainer.addArrangedSubview(engineToggleLabel)
        engineToggleContainer.addArrangedSubview(engineToggleSwitch)

        view.addSubviews(
            backgroundRecordEffect,
            backgroundBlur,
            contentView,
            audioWaveform,
            engineToggleContainer,
            buttonsContainer
        )

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

            engineToggleContainer.topAnchor.constraint(equalTo: audioWaveform.bottomAnchor,
                                                       constant: UX.engineToggleTopPadding),
            engineToggleContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            contentView.topAnchor.constraint(equalTo: engineToggleContainer.bottomAnchor,
                                             constant: UX.contentViewTopPadding),
            contentView.bottomAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            buttonsContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -UX.buttonsContainerBottomPadding),
            buttonsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Make spacer views expand equally to center the buttons in the button container
            leadingButtonContainerSpacer.widthAnchor.constraint(equalTo: trailingButtonContainerSpacer.widthAnchor)
        ])
        backgroundBlur.pinToSuperview()
    }

    private func configureButtons() {
        recordButton.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.audioWaveform.startAnimating()
                    self?.viewModel.startAndStopVoiceRecord()
                }),
            for: .touchUpInside
        )
        closeButton.addAction(
            UIAction(
                handler: { [weak self] _ in
                    Task {
                        await self?.viewModel.stopRecordingVoice()
                        self?.dismiss(animated: true)
                    }
                }),
            for: .touchUpInside
        )
        engineToggleSwitch.addAction(
            UIAction(
                handler: { [weak self] _ in
                    guard let self = self else { return }
                    Task {
                        await self.viewModel.stopRecordingVoice()
                        self.audioWaveform.stopAnimating()
                        await self.viewModel.switchEngine(useNewAPI: self.engineToggleSwitch.isOn)
                    }
                }),
            for: .valueChanged
        )
    }

    private func onStateChange(state: VoiceSearchViewModel.State) {
        switch state {
        case .recordVoice(let speechResult, _):
            contentView.setSpeechResult(text: speechResult.text)
        case .loadingSearchResult:
            audioWaveform.stopAnimating()
            contentView.setIsLoadingSearchResult()
        case .showSearchResult(let searchResult, _):
            contentView.setSearchResult(
                title: searchResult.title,
                body: searchResult.body,
                url: searchResult.url
            )
        }
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
        engineToggleLabel.textColor = theme.colors.textPrimary
        engineToggleSwitch.onTintColor = theme.colors.actionPrimary
        contentView.applyTheme(theme: theme)
    }
}
