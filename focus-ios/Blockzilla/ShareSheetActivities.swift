/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class OpenInFirefoxActivity: UIActivity {
    fileprivate let url: URL
    
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
        OpenUtils.openInFirefox(url: url)
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}

class OpenInSafariActivity: UIActivity {
    fileprivate let url: URL

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
        OpenUtils.openInSafari(url: url)
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}

class OpenInChromeActivity: UIActivity {
    fileprivate let url: URL

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
        OpenUtils.openInChrome(url: url)
        activityDidFinish(true)
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
