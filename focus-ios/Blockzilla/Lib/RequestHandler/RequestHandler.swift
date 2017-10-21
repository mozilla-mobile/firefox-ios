/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

private let internalSchemes = ["http", "https", "ftp", "file", "about", "javascript", "data"]

class RequestHandler {
    func handle(request: URLRequest, alertCallback: (UIAlertController) -> ()) -> Bool {
        guard let url = request.url,
              let scheme = request.url?.scheme?.lowercased() else {
            return false
        }

        // If the URL isn't a scheme the browser can open, let the system handle it if
        // it's a scheme we want to support.
        guard internalSchemes.contains(scheme) else {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return false
            }

            let title = components.path

            switch scheme {
            case "tel":
                // Don't present our dialog as the system presents its own
                UIApplication.shared.open(url, options: [:])
            case "facetime", "facetime-audio":
                let alert = RequestHandler.makeAlert(title: title, action: "FaceTime", forURL: url)
                alertCallback(alert)
            case "mailto":
                let alert = RequestHandler.makeAlert(title: title, action: UIConstants.strings.externalLinkEmail, forURL: url)
                alertCallback(alert)
            default:
                let openAction = UIAlertAction(title: UIConstants.strings.open, style: .default) { _ in
                    Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.requestHandler, value: "external link")
                    UIApplication.shared.open(url, options: [:])
                }

                let cancelAction = UIAlertAction(title: UIConstants.strings.externalLinkCancel, style: .cancel) { _ in
                    Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.cancel, object: TelemetryEventObject.requestHandler, value: "external link")
                }

                let alert = UIAlertController(title: String(format: UIConstants.strings.externalAppLink, AppInfo.productName),
                                              message: nil,
                                              preferredStyle: .alert)

                alert.addAction(cancelAction)
                alert.addAction(openAction)
                alert.preferredAction = openAction
                alertCallback(alert)
            }

            return false
        }

        guard scheme == "http" || scheme == "https",
              let host = url.host?.lowercased() else {
            return true
        }

        switch host {
        case "maps.apple.com":
            let alert = RequestHandler.makeAlert(title: String(format: UIConstants.strings.externalAppLinkWithAppName, AppInfo.productName, "Maps"), action: UIConstants.strings.open, forURL: url)
            alertCallback(alert)
            return false
        case "itunes.apple.com":
            let alert = RequestHandler.makeAlert(title: String(format: UIConstants.strings.externalAppLinkWithAppName, AppInfo.productName, "App Store"), action: UIConstants.strings.open, forURL: url)
            alertCallback(alert)
            return false
        default:
            return true
        }
    }

    static private func makeAlert(title: String, action: String, forURL url: URL) -> UIAlertController {
        let openAction = UIAlertAction(title: action, style: .default) { _ in
            UIApplication.shared.open(url, options: [:])
        }
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: UIConstants.strings.externalLinkCancel, style: .cancel, handler: nil))
        alert.addAction(openAction)
        alert.preferredAction = openAction
        return alert
    }
}
