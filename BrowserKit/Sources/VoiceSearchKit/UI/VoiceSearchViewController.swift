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
    private let transitionAnimator: TransitionAnimator

    public let themeManager: any ThemeManager
    public var currentWindowUUID: WindowUUID?
    public var themeListenerCancellable: Any?
    private let notificationCenter: NotificationProtocol

    public init(
        presentationTransitionType: VoiceSearchTransitionType = .crossDissolve,
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
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
        applyTheme()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
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
