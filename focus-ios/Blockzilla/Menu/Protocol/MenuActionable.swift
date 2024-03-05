/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol MenuActionable: AnyObject {
    func addToShortcuts(url: URL)
    func removeShortcut(url: URL)

    func findInPage()
    func requestDesktopBrowsing()
    func requestMobileBrowsing()

    func openInFirefox(url: URL)
    func openInChrome(url: URL)
    var canOpenInFirefox: Bool { get }
    var canOpenInChrome: Bool { get }

    func showSettings(shouldScrollToSiri: Bool)
    func showHelp()

    func openInDefaultBrowser(url: URL)
    func showCopy(url: URL)
    func showSharePage(for utils: OpenUtils, sender: UIView)
}
