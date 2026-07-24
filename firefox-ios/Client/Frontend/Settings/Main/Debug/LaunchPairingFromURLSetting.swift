// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import enum MozillaAppServices.OAuthScope

/// Debug-only setting that launches the FxA device-pairing web flow from a
/// pasted (or pre-filled) pairing URL. Drives the same `.qrCode(url:)` path a
/// real scan would, so pairing can be exercised on a simulator, which lacks the
/// QR camera, and by the `pairingFlowiOS.spec.ts` functional test.
class LaunchPairingFromURLSetting: HiddenSetting {
    override var accessibilityIdentifier: String? { return "LaunchPairingFromURL.Setting" }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Launch pairing from URL",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Launch pairing from URL",
            message: "Paste a pairing URL (…/pair#channel_id=…&channel_key=…).",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.accessibilityIdentifier = "LaunchPairingFromURL.textField"
            textField.placeholder = "https://…/pair#channel_id=…"
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.text = Self.prefilledPairingURL()
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Launch", style: .default) { [weak self] _ in
            let text = alert.textFields?.first?.text ?? ""
            self?.launchPairing(urlString: text, navigationController: navigationController)
        })
        settings.present(alert, animated: true)
    }

    private func launchPairing(urlString: String, navigationController: UINavigationController?) {
        let pairingUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pairingUrl.isEmpty,
              let profile = settings.profile,
              let accountManager = profile.rustFxA.accountManager else { return }

        // Converts the raw /pair URL into the supplicant OAuth URL; loading /pair
        // directly sends non-desktop browsers to /pair/unsupported. Mirrors the
        // real-scan path in FirefoxAccountSignInViewController.
        accountManager.beginPairingAuthentication(
            pairingUrl: pairingUrl,
            entrypoint: "pairing_debug",
            scopes: [OAuthScope.profile, OAuthScope.oldSync, OAuthScope.session, OAuthScope.relay]
        ) { result in
            guard case .success(let supplicantURL) = result else { return }
            DispatchQueue.main.async {
                let vc = FxAWebViewController(
                    pageType: .qrCode(url: supplicantURL),
                    profile: profile,
                    dismissalStyle: .popToRootVC,
                    deepLinkParams: FxALaunchParams(entrypoint: .connectSetting, query: [:]),
                    shouldAskForNotificationPermission: false
                )
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    /// Prefill from the `PAIRING_URL` launch env (functional test), else the
    /// pasteboard if it holds a pairing URL.
    private static func prefilledPairingURL() -> String? {
        if let fromEnv = ProcessInfo.processInfo.environment["PAIRING_URL"], !fromEnv.isEmpty {
            return fromEnv
        }
        if let pasted = UIPasteboard.general.string, pasted.contains("/pair#") {
            return pasted
        }
        return nil
    }
}
