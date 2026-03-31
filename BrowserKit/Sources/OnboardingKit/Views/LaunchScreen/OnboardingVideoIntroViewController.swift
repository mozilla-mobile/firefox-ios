// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Common
import UIKit
import ComponentLibrary

public final class OnboardingVideoIntroViewController: UIViewController, Themeable, Notifiable {
    private struct UX {
        static let buttonHorizontalPadding: CGFloat = 24
        static let buttonBottomPadding: CGFloat = 16
        static let introVideoTitle = "IntroVideo"
        static let introVideoExtension = "mp4"
    }

    public var themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: Common.WindowUUID?
    private var player: AVPlayer?
    private let notificationCenter: NotificationProtocol
    private lazy var continueButton: PrimaryRoundedGlassButton = .build {
        $0.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.dismiss(animated: true)
                }),
            for: .touchUpInside
        )
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerLayer()
        setupLayout()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
    }

    private func setupPlayerLayer() {
        guard let url = Bundle.module.url(forResource: UX.introVideoTitle, withExtension: UX.introVideoExtension) else {
            dismiss(animated: false)
            return
        }

        player = AVPlayer(url: url)
        player?.isMuted = true
        player?.actionAtItemEnd = .none
        player?.play()

        let layer = AVPlayerLayer(player: player)
        layer.frame = view.bounds
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.AVPlayerItemDidPlayToEndTime, UIApplication.willEnterForegroundNotification]
        )
    }

    private func setupLayout() {
        view.addSubview(continueButton)
        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                    constant: UX.buttonHorizontalPadding),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -UX.buttonHorizontalPadding),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                   constant: -UX.buttonBottomPadding)
        ])
    }

    public func configure(buttonModel: PrimaryRoundedButtonViewModel) {
        continueButton.configure(viewModel: buttonModel)
    }

    // MARK: - Notifiable
    nonisolated public func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .AVPlayerItemDidPlayToEndTime:
            DispatchQueue.main.async { [weak self] in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        case UIApplication.willEnterForegroundNotification:
            DispatchQueue.main.async { [weak self] in
                self?.player?.play()
            }
        default:
            break
        }
    }

    // MARK: - ThemeApplicable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = .systemBackground
        continueButton.applyTheme(theme: theme)
    }
}
