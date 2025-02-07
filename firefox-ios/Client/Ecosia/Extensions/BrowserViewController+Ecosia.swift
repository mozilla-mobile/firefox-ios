// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Ecosia

// MARK: HomepageViewControllerDelegate
extension BrowserViewController: HomepageViewControllerDelegate {
    func homeDidTapSearchButton(_ home: HomepageViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }
}

// MARK: DefaultBrowserDelegate
extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser) {
        profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
//        homepageViewController?.reloadTooltip()
    }
}

// MARK: WhatsNewViewDelegate
extension BrowserViewController: WhatsNewViewDelegate {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController) {
        whatsNewDataProvider.markPreviousVersionsAsSeen()
//        homepageViewController?.reloadTooltip()
    }
}

// MARK: PageActionsShortcutsDelegate
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

// MARK: URL Bar
extension BrowserViewController {

    func updateURLBarFollowingPrivateModeUI() {
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        urlBar.applyUIMode(isPrivate: isPrivate, theme: themeManager.getCurrentTheme(for: windowUUID))
    }
}

// MARK: Present intro
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
}

// MARK: Present insightful sheets
extension BrowserViewController {
    private var shouldShowDefaultBrowserPromo: Bool {
        profile.prefs.intForKey(PrefsKeys.IntroSeen) == nil &&
        DefaultBrowser.minPromoSearches <= User.shared.searchCount
    }
    private var shouldShowWhatsNewPageScreen: Bool { whatsNewDataProvider.shouldShowWhatsNewPage }

    func presentInsightfulSheetsIfNeeded() {
        guard isHomePage(),
              !showLoadingScreen(for: .shared) else { return }

        // TODO: To review this logic as part of the upgrade
        /*
         We are not fan of this one, but given the current approach a refactor
         would not be suitable as part of this ticke scope.
         As part of the upgrade and with a more structured navigation approach, we will
         refactor it.
         The below is a decent compromise given the complexity of the decisional execution and presentation.
         The order of the function represents the priority.
         */
        let presentationFunctions: [() -> Bool] = [
            presentDefaultBrowserPromoIfNeeded,
            presentWhatsNewPageIfNeeded
        ]

        _ = presentationFunctions.first(where: { $0() })
    }

    private func isHomePage() -> Bool {
        tabManager.selectedTab?.url.flatMap { InternalURL($0)?.isAboutHomeURL } ?? false
    }

    @discardableResult
    private func presentDefaultBrowserPromoIfNeeded() -> Bool {
        guard shouldShowDefaultBrowserPromo else { return false }

        if #available(iOS 14, *) {
            let defaultPromo = DefaultBrowser(windowUUID: windowUUID, delegate: self)
            present(defaultPromo, animated: true)
        } else {
            profile.prefs.setInt(1, forKey: PrefsKeys.IntroSeen)
        }
        return true
    }

    @discardableResult
    private func presentWhatsNewPageIfNeeded() -> Bool {
        guard shouldShowWhatsNewPageScreen else { return false }
        let viewModel = WhatsNewViewModel(provider: whatsNewDataProvider)
        WhatsNewViewController.presentOn(self, viewModel: viewModel, windowUUID: windowUUID)
        return true
    }
}

// MARK: Claim Referral
extension BrowserViewController {

    func openBlankNewTabAndClaimReferral(code: String) {
        User.shared.referrals.pendingClaim = code

        // on first start, browser is not in view hierarchy yet
        guard !User.shared.firstTime else { return }
        popToBVC()
        openURLInNewTab(nil, isPrivate: false)
        // Intro logic will trigger claiming referral
        presentIntroViewController()
    }
}
