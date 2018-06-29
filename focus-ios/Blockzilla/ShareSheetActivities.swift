/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

class OpenInFirefoxActivity: UIActivity {
    fileprivate let url: URL
    private let app = UIApplication.shared
    
    init(url: URL) {
        self.url = url
    }

    override var activityTitle: String? {
        return String(format: UIConstants.strings.openIn, "Firefox")
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "open_in_firefox_icon")
    }

    override func perform() {
        openInFirefox(url: url)
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    func openInFirefox(url: URL) {
        guard let escaped = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
            let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)&private=true"),
            app.canOpenURL(firefoxURL) else {
                return
        }
        
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.menu, value: "firefox")
        app.open(firefoxURL, options: [:])
    }
}

class OpenInSafariActivity: UIActivity {
    fileprivate let url: URL
    private let app = UIApplication.shared

    init(url: URL) {
        self.url = url
    }

    override var activityTitle: String? {
        return String(format: UIConstants.strings.openIn, "Safari")
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "open_in_safari_icon")
    }

    override func perform() {
        openInSafari(url: url)
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    func openInSafari(url: URL) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.menu, value: "default")
        app.open(url, options: [:])
    }
}

class OpenInChromeActivity: UIActivity {
    fileprivate let url: URL
    private let app = UIApplication.shared

    init(url: URL) {
        self.url = url
    }

    override var activityTitle: String? {
        return String(format: UIConstants.strings.openIn, "Chrome")
    }

    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "open_in_chrome_icon")
    }

    override func perform() {
        openInChrome(url: url)
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    func openInChrome(url: URL) {
        // Code pulled from https://github.com/GoogleChrome/OpenInChrome
        // Replace the URL Scheme with the Chrome equivalent.
        var chromeScheme: String?
        if (url.scheme == "http") {
            chromeScheme = "googlechrome"
        } else if (url.scheme == "https") {
            chromeScheme = "googlechromes"
        }
        
        // Proceed only if a valid Google Chrome URI Scheme is available.
        guard let scheme = chromeScheme,
            let rangeForScheme = url.absoluteString.range(of: ":"),
            let chromeURL = URL(string: scheme + url.absoluteString[rangeForScheme.lowerBound...]) else { return }
        
        // Open the URL with Chrome.
        app.open(chromeURL, options: [:])
    }
}

class FindInPageActivity: UIActivity {
    override var activityTitle: String? {
        return UIConstants.strings.shareMenuFindInPage
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "ios-find-in-page")
    }
    
    override func perform() {
        openFindInPage()
        activityDidFinish(true)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    func openFindInPage() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.findInPageNotification)))
    }
}

class RequestDesktopActivity: UIActivity {
    fileprivate let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    override var activityTitle: String? {
        return UIConstants.strings.shareMenuRequestDesktop
    }
    
    override var activityImage: UIImage? {
        return #imageLiteral(resourceName: "request_desktop_site_activity")
    }
    
    override func perform() {
        // Reload in desktop mode
        reloadAsDesktopSite(url: url)
        activityDidFinish(true)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    func reloadAsDesktopSite(url: URL) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.requestDesktop)
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: UIConstants.strings.requestDesktopNotification)))
    }
}

/// This Activity Item Provider subclass does two things that are non-standard behaviour:
///
/// * We return NSNull if the calling activity is not supposed to see the title. For example the Copy action, which should only paste the URL. We also include Message and Mail to have parity with what Safari exposes.
/// * We set the subject of the item to the title, this means it will correctly be used when sharing to for example Mail. Again parity with Safari.
///
/// Note that not all applications use the Subject. For example OmniFocus ignores it, so we need to do both.

class TitleActivityItemProvider: UIActivityItemProvider {
    static let activityTypesToIgnore = [UIActivityType.copyToPasteboard, UIActivityType.message, UIActivityType.mail]
    
    init(title: String) {
        super.init(placeholderItem: title)
    }
    
    override var item : Any {
        if let activityType = activityType {
            if TitleActivityItemProvider.activityTypesToIgnore.contains(activityType) {
                return NSNull()
            }
        }
        return placeholderItem! as AnyObject
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return placeholderItem as! String
    }
}
