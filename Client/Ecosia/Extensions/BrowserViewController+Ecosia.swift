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
        presentYourImpact(completion)
    }

    func presentYourImpact(_ completion: (() -> Void)? = nil) {
        ecosiaNavigation.popToRootViewController(animated: false)
        present(ecosiaNavigation, animated: true, completion: completion)
    }
}

extension BrowserViewController: YourImpactDelegate {
    func yourImpact(didSelectURL url: URL) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: .link, forTab: tab)
    }
}

extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser) {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        homepageViewController?.reloadTooltip()
    }
}

extension BrowserViewController: PageActionsShortcutsDelegate {
    func pageOptionsOpenHome() {
        tabToolbarDidPressHome(toolbar, button: .init())
        dismiss(animated: true)
        Analytics.shared.menuClick("home")
    }

    func pageOptionsNewTab() {
        openBlankNewTab(focusLocationField: false)
        dismiss(animated: true)
        Analytics.shared.menuClick("new_tab")
    }

    func pageOptionsYourImpact() {
        dismiss(animated: true) {
            self.presentYourImpact()
        }
        Analytics.shared.menuClick("your_impact")
    }

    func pageOptionsShare() {
        dismiss(animated: true) {
            guard let item = self.menuHelper?.getSharingAction().item,
                  let handler = item.tapHandler else { return }
            handler(item)
        }
    }
}
