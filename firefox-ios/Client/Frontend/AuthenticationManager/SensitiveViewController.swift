// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class SensitiveViewController: UIViewController, Notifiable {
    private enum VisibilityState {
        case active
        case inactive
        case backgrounded
    }

    private var backgroundBlurView: UIVisualEffectView?
    private var isAuthenticated = false
    private var visibilityState: VisibilityState = .active
    private let notificationCenter: NotificationProtocol

    init(notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIScene.willEnterForegroundNotification,
                        UIApplication.didEnterBackgroundNotification,
                        UIApplication.willResignActiveNotification,
                        UIApplication.didBecomeActiveNotification]
        )
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIScene.willEnterForegroundNotification:
            guard let notificationScene = notification.object as? UIWindowScene else { return }
            ensureMainThread { [weak self] in
                guard let self,
                      let sensitiveWindowScene = self.view.window?.windowScene,
                      sensitiveWindowScene === notificationScene else { return }
                self.visibilityState = .active
                self.handleCheckAuthentication()
            }
        case UIApplication.didEnterBackgroundNotification:
            ensureMainThread { [weak self] in
                guard let self else { return }
                self.visibilityState = .backgrounded
                self.isAuthenticated = false
                self.installBlurredOverlay()
            }
        case UIApplication.willResignActiveNotification:
            ensureMainThread { [weak self] in
                guard let self else { return }
                if self.visibilityState == .active {
                    self.visibilityState = .inactive
                    self.installBlurredOverlay()
                }
            }
        case UIApplication.didBecomeActiveNotification:
            ensureMainThread { [weak self] in
                guard let self else { return }
                if self.visibilityState == .inactive {
                    self.visibilityState = .active
                    self.removedBlurredOverlay()
                }
            }

        default: break
        }
    }

    private func handleCheckAuthentication() {
        guard !isAuthenticated else { return }
        AppAuthenticator().authenticateWithDeviceOwnerAuthentication { [self] result in
            switch result {
            case .success:
                isAuthenticated = false
                removedBlurredOverlay()
            case .failure:
                isAuthenticated = false
                navigationController?.dismiss(animated: true, completion: nil)
                dismiss(animated: true)
            }
        }
    }

    // MARK: - Blur management

    private func installBlurredOverlay() {
        guard backgroundBlurView == nil else { return }
        let blur = UIBlurEffect(style: .systemMaterialDark)
        let backgroundBlurView = IntensityVisualEffectView(effect: blur, intensity: 0.2)
        view.addSubview(backgroundBlurView)
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.backgroundBlurView = backgroundBlurView
    }

    private func removedBlurredOverlay() {
        backgroundBlurView?.removeFromSuperview()
        backgroundBlurView = nil
    }
}
