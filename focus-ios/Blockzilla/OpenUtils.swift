/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class OpenUtils {
    private static let app = UIApplication.shared
    private static let firefoxAppStoreURL = URL(string: "https://itunes.apple.com/app/id989804926")!

    private static var canOpenInFirefox: Bool {
        return app.canOpenURL(URL(string: "firefox://")!)
    }

    private static func openInFirefox(url: URL) {
        guard let escaped = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
              let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)"),
              app.canOpenURL(firefoxURL) else {
            return
        }

        AdjustIntegration.track(eventName: .openFirefox)
        app.openURL(firefoxURL)
    }

    private static func openInSafari(url: URL) {
        AdjustIntegration.track(eventName: .openSafari)
        app.openURL(url)
    }

    static func buildShareAlert(url: URL, anchor: UIView, shareCallback: @escaping (UIActivityViewController) -> ()) -> UIAlertController {
        let alert = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: UIConstants.strings.openFirefox, style: .default) { _ in
            // If Firefox isn't installed, launch the URL to download it in the App Store.
            guard OpenUtils.canOpenInFirefox else {
                UIApplication.shared.openURL(firefoxAppStoreURL)
                return
            }

            OpenUtils.openInFirefox(url: url)
        })

        alert.addAction(UIAlertAction(title: UIConstants.strings.openSafari, style: .default) { _ in
            OpenUtils.openInSafari(url: url)
        })

        alert.addAction(UIAlertAction(title: UIConstants.strings.openShare, style: .default) { _ in
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = anchor
            controller.popoverPresentationController?.sourceRect = anchor.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .up
            shareCallback(controller)
        })

        alert.addAction(UIAlertAction(title: UIConstants.strings.openCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.sourceView = anchor
        alert.popoverPresentationController?.sourceRect = anchor.bounds
        alert.popoverPresentationController?.permittedArrowDirections = .up

        return alert
    }
}
