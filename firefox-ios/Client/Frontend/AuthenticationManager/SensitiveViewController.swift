// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class SensitiveViewController: UIViewController {
    private enum VisibilityState {
        case active
        case inactive
        case backgrounded
    }

    private var backgroundBlurView: UIVisualEffectView?
    private var isAuthenticated = false
    private var visibilityState: VisibilityState = .active
    private var sceneWillEnterForegroundObserver: NSObjectProtocol?
    private var didEnterBackgroundObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?
    private var didBecomeActiveObserver: NSObjectProtocol?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sceneWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willEnterForegroundNotification,
            object: nil,
            queue: .main,
            using: { [weak self] notification in
                guard Thread.isMainThread else {
                    assertionFailure("This must be called main thread")
                    return
                }

                // Parse out anything we need from non-Sendable `Notification`
                let notificationScene = notification.object as? UIWindowScene

                // We have set the queue to `.main` on the observer, so theoretically this is safe to call here
                MainActor.assumeIsolated {
                    guard let self,
                          let sensitiveWindowScene = self.view.window?.windowScene,
                          let notificationScene = notificationScene,
                          sensitiveWindowScene === notificationScene else { return }
                    self.visibilityState = .active
                    self.handleCheckAuthentication()
                }
            }
        )

        didEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main,
            using: { [weak self] notification in
                guard Thread.isMainThread else {
                    assertionFailure("This must be called main thread")
                    return
                }

                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.visibilityState = .backgrounded
                    self.isAuthenticated = false
                    self.installBlurredOverlay()
                }
            }
        )

        willResignActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main,
            using: { [weak self] notification in
                guard Thread.isMainThread else {
                    assertionFailure("This must be called main thread")
                    return
                }

                MainActor.assumeIsolated {
                    guard let self else { return }
                    if self.visibilityState == .active {
                        self.visibilityState = .inactive
                        self.installBlurredOverlay()
                    }
                }
            }
        )

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: { [weak self] notification in
                guard Thread.isMainThread else {
                    assertionFailure("This must be called main thread")
                    return
                }

                MainActor.assumeIsolated {
                    guard let self else { return }
                    if self.visibilityState == .inactive {
                        self.visibilityState = .active
                        self.removedBlurredOverlay()
                    }
                }
            }
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        [sceneWillEnterForegroundObserver,
         didEnterBackgroundObserver,
         didBecomeActiveObserver,
         willResignActiveObserver].forEach {
            guard let observer = $0 else { return }
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Utility func

//    private func observe(_ notification: Notification.Name,
//                         with closure: @escaping ((Notification) -> Void)) -> NSObjectProtocol? {
//        return NotificationCenter.default.addObserver(forName: notification, object: nil, queue: .main, using: closure)
//    }

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
}

extension SensitiveViewController {
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
