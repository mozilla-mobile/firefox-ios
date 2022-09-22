/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Shared

extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }

    func homeDidPressPersonalCounter(_ home: HomepageViewController, completion: (() -> Void)? = nil) {
        presentEcosiaWorld(completion)
    }

    func presentEcosiaWorld(_ completion: (() -> Void)? = nil) {
        ecosiaNavigation.popToRootViewController(animated: false)
        present(ecosiaNavigation, animated: true, completion: completion)
    }
}

extension BrowserViewController: EcosiaHomeDelegate {
    func ecosiaHome(didSelectURL url: URL) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: .link, forTab: tab)
    }
}

extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser) {
        User.shared.firstTime = false
        homepageViewController?.reloadTooltip()
    }
}
