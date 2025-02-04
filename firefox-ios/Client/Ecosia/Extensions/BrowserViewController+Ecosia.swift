// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core
import Shared

extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }
}

extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser) {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
//        homepageViewController?.reloadTooltip()
    }
}

extension BrowserViewController: WhatsNewViewDelegate {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController) {
        whatsNewDataProvider.markPreviousVersionsAsSeen()
//        homepageViewController?.reloadTooltip()
    }
}

extension BrowserViewController: PageActionsShortcutsDelegate {
    func pageOptionsOpenHome() {
        tabToolbarDidPressHome(toolbar, button: .init())
        dismiss(animated: true)
        Analytics.shared.menuClick(.home)
    }

    func pageOptionsNewTab() {
        openBlankNewTab(focusLocationField: false)
        dismiss(animated: true)
        Analytics.shared.menuClick(.newTab)
    }

    func pageOptionsSettings() {
        homePanelDidRequestToOpenSettings(at: .general)
        dismiss(animated: true)
        Analytics.shared.menuClick(.settings)
    }

    func pageOptionsShare() {
        dismiss(animated: true) {
            guard let item = self.menuHelper?.getSharingAction().items.first,
                  let handler = item.tapHandler else { return }
            handler(item)
        }
    }
}

extension BrowserViewController {

    func updateURLBarFollowingPrivateModeUI() {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        urlBar.applyUIMode(isPrivate: isPrivate, theme: themeManager.getCurrentTheme(for: windowUUID))
    }
}

extension BrowserViewController {

    func presentIntroViewController(_ alwaysShow: Bool = false) {
        if showLoadingScreen(for: .shared) {
            presentLoadingScreen()
        } else if User.shared.firstTime {
            handleFirstTimeUserActions()
        }
    }

    private func presentLoadingScreen() {
        present(LoadingScreen(profile: profile, referrals: referrals, windowUUID: windowUUID, referralCode: User.shared.referrals.pendingClaim), animated: true)
    }

    private func handleFirstTimeUserActions() {
        User.shared.firstTime = false
        User.shared.migrated = true
        User.shared.hideBookmarksImportExportTooltip()
        toolbarContextHintVC.deactivateHintForNewUsers()
    }

    private func showLoadingScreen(for user: User) -> Bool {
        user.referrals.pendingClaim != nil
    }

    private func isHomePage() -> Bool {
        tabManager.selectedTab?.url.flatMap { InternalURL($0)?.isAboutHomeURL } ?? false
    }
}
