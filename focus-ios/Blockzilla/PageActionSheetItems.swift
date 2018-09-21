/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

class PageActionSheetItems {
    
    let app = UIApplication.shared
    let url: URL!
    
    init(url: URL) {
        self.url = url
    }
    
    var canOpenInFirefox: Bool {
        return app.canOpenURL(URL(string: "firefox://")!)
    }
    
    var canOpenInChrome: Bool {
        return app.canOpenURL(URL(string: "googlechrome://")!)
    }
    
    lazy var openInFireFoxItem = PhotonActionSheetItem(title: UIConstants.strings.shareOpenInFirefox, iconString: "open_in_firefox_icon") { action in
        guard let escaped = self.url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
            let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)&private=true"),
            self.app.canOpenURL(firefoxURL) else {
                return
        }
        
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.menu, value: "firefox")
        self.app.open(firefoxURL, options: [:])
    }
    
    lazy var openInChromeItem = PhotonActionSheetItem(title: UIConstants.strings.shareOpenInChrome, iconString: "open_in_chrome_icon") { action in
        // Code pulled from https://github.com/GoogleChrome/OpenInChrome
        // Replace the URL Scheme with the Chrome equivalent.
        var chromeScheme: String?
        if (self.url.scheme == "http") {
            chromeScheme = "googlechrome"
        } else if (self.url.scheme == "https") {
            chromeScheme = "googlechromes"
        }
        
        // Proceed only if a valid Google Chrome URI Scheme is available.
        guard let scheme = chromeScheme,
            let rangeForScheme = self.url.absoluteString.range(of: ":"),
            let chromeURL = URL(string: scheme + self.url.absoluteString[rangeForScheme.lowerBound...]) else { return }
        
        // Open the URL with Chrome.
        self.app.open(chromeURL, options: [:])
    }
    
    lazy var openInSafariItem = PhotonActionSheetItem(title: UIConstants.strings.shareOpenInSafari, iconString: "open_in_safari_icon") { action in
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.menu, value: "default")
        self.app.open(self.url, options: [:])
    }
    
    lazy var findInPageItem = PhotonActionSheetItem(title: UIConstants.strings.shareMenuFindInPage, iconString: "icon_searchfor") { action in
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.findInPageNotification)))
    }
    
    lazy var requestDesktopItem = PhotonActionSheetItem(title: UIConstants.strings.shareMenuRequestDesktop, iconString: "request_desktop_site_activity") { action in
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.requestDesktop)
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.requestDesktopNotification)))
    }
}
