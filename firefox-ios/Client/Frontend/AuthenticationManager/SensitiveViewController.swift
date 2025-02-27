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

        sceneWillEnterForegroundObserver = observe(UIScene.willEnterForegroundNotification) { [weak self] notification in
            guard let self,
                  let sensitiveWindowScene = self.view.window?.windowScene,
                  let notificationScene = notification.object as? UIWindowScene,
                  sensitiveWindowScene === notificationScene else { return }
            visibilityState = .active
            handleCheckAuthentication()
        }

        didEnterBackgroundObserver = observe(UIApplication.didEnterBackgroundNotification) { [weak self] notification in
            guard let self else { return }
            visibilityState = .backgrounded
            isAuthenticated = false
            installBlurredOverlay()
        }

        willResignActiveObserver = observe(UIApplication.willResignActiveNotification) { [weak self] notification in
            guard let self else { return }
            if visibilityState == .active {
                visibilityState = .inactive
                installBlurredOverlay()
            }
        }

        didBecomeActiveObserver = observe(UIApplication.didBecomeActiveNotification) { [weak self] notification in
            guard let self else { return }
            if visibilityState == .inactive {
                visibilityState = .active
                removedBlurredOverlay()
            }
        }
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

    private func observe(_ notification: Notification.Name,
                         with closure: @escaping ((Notification) -> Void)) -> NSObjectProtocol? {
        return NotificationCenter.default.addObserver(forName: notification, object: nil, queue: .main, using: closure)
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
