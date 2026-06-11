// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class PrivacyWindowHelper {
    private struct UX {
        static let logoSize: CGFloat = 80
    }

    private var privacyWindow: UIWindow?

    @MainActor
    func showWindow(windowScene: UIWindowScene?, withThemedColor color: UIColor, showLogo: Bool = false) {
        guard let windowScene else { return }

        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = color

        if showLogo {
            let logoImageView = UIImageView(
                image: UIImage(named: ImageIdentifiers.homeHeaderLogoBall)
            )
            logoImageView.contentMode = .scaleAspectFit
            logoImageView.translatesAutoresizingMaskIntoConstraints = false
            rootViewController.view.addSubview(logoImageView)
            NSLayoutConstraint.activate([
                logoImageView.centerXAnchor.constraint(equalTo: rootViewController.view.centerXAnchor),
                logoImageView.centerYAnchor.constraint(equalTo: rootViewController.view.centerYAnchor),
                logoImageView.widthAnchor.constraint(equalToConstant: UX.logoSize),
                logoImageView.heightAnchor.constraint(equalToConstant: UX.logoSize)
            ])
        }

        privacyWindow = UIWindow(windowScene: windowScene)
        privacyWindow?.rootViewController = rootViewController
        // Set the privacy window level to be above alert windows (highest in importance).
        privacyWindow?.windowLevel = .alert + 1
        // Avoid makeKeyAndVisible(), becoming key steals first responder
        // and causses iOS keyboard to dismiss on background/foreground in private mode.
        privacyWindow?.isHidden = false
    }

    @MainActor
    func removeWindow() {
        privacyWindow?.isHidden = true
        privacyWindow = nil
    }
}
