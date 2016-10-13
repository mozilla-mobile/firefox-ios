/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class OpenUtils {
    private static let app = UIApplication.shared

    private static func openInFirefox(url: URL) ->  Bool {
        guard let escaped = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
              let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)") else {
            return false
        }

        return app.openURL(firefoxURL)
    }

    private static func openInSafari(url: URL) {
        app.openURL(url)
    }

    /// Opens the URL in Firefox, if Firefox is available.
    /// Otherwise, the URL is opened in Safari.
    static func openInExternalBrowser(url: URL) {
        if !openInFirefox(url: url) {
            openInSafari(url: url)
        }
    }
}
