// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common

/// The `SensitiveHostingController` blurs the nested view on backgrounding and asks to authenticate before foregrounding.
///
/// "Sensitive" refers to a screen with sensitive user data. Typically, this data is hidden behind `LocalAuthentication` and
/// a user must authenticate each time.
class SensitiveHostingController<Content>: UIHostingController<Content> where Content: View {
    private var appAuthenticator: AppAuthenticationProtocol?
    private var blurredOverlay: UIImageView?
    private var isAuthenticated = false
    var notificationCenter: NotificationProtocol?
    
    init(rootView: Content,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         localAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        super.init(rootView: rootView)
        
        self.notificationCenter = notificationCenter
        self.appAuthenticator = localAuthenticator
        
        setupNotifications(forObserver: self, observing: [UIApplication.didEnterBackgroundNotification,
                                                          UIApplication.willEnterForegroundNotification])
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter?.removeObserver(self)
    }

    // MARK: - Private helpers

    private func addBlurredOverlay() {
        guard blurredOverlay == nil, let snapshot = view.screenshot() else { return }

        let blurredSnapshot = snapshot.applyBlur(withRadius: 10,
                                                 blurType: BOXFILTER,
                                                 tintColor: UIColor(white: 1, alpha: 0.3),
                                                 saturationDeltaFactor: 1.8,
                                                 maskImage: nil)

        let blurredOverlay = UIImageView(image: blurredSnapshot)
        self.blurredOverlay = blurredOverlay

        view.addSubview(blurredOverlay)

        NSLayoutConstraint.activate([
            blurredOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurredOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            blurredOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurredOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureOverlay() {
        appAuthenticator?.authenticateWithDeviceOwnerAuthentication { [self] result in
            switch result {
            case .success:
                isAuthenticated = true
                removedBlurredOverlay()
            case .failure:
                isAuthenticated = false
                navigationController?.dismiss(animated: true, completion: nil)
                dismiss(animated: true)
            }
        }
    }

    private func removedBlurredOverlay() {
        blurredOverlay?.removeFromSuperview()
        blurredOverlay = nil
    }

    private func setupNotifications(forObserver observer: Any,
                                    observing notifications: [Notification.Name]) {
        notifications.forEach {
            notificationCenter?.addObserver(observer,
                                            selector: #selector(handleNotifications),
                                            name: $0,
                                            object: nil)
        }
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            isAuthenticated = false
            addBlurredOverlay()
        case UIApplication.willEnterForegroundNotification:
            if !isAuthenticated {
                configureOverlay()
            }

        default: break
        }
    }
}
