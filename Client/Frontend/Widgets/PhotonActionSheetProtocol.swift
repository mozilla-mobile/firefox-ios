/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

protocol PhotonActionSheetProtocol {
    var tabManager: TabManager { get }
    var profile: Profile { get }
}

extension PhotonActionSheetProtocol {
    typealias PresentableVC = UIViewController & UIPopoverPresentationControllerDelegate

    func presentSheetWith(actions: [[PhotonActionSheetItem]], on viewController: PresentableVC, from view: UIView) {
        let sheet = PhotonActionSheet(actions: actions)
        sheet.modalPresentationStyle =  UIDevice.current.userInterfaceIdiom == .pad ? .popover : .overFullScreen
        sheet.modalTransitionStyle = .crossDissolve

        if let popoverVC = sheet.popoverPresentationController {
            popoverVC.backgroundColor = UIColor.clear
            popoverVC.delegate = viewController
            popoverVC.sourceView = view
            popoverVC.sourceRect = CGRect(x: view.frame.width/2, y: view.frame.size.height * 0.75, width: 1, height: 1)
            popoverVC.permittedArrowDirections = UIPopoverArrowDirection.up
        }

        viewController.present(sheet, animated: true, completion: nil)
    }

    //Returns a list of actions which is used to build a menu
    //parameter OpenURL is a clousre that can open a given URL in some view controller. It is up to the class using the menu to know how to open the url
    func getHomePanelActions(openURL: @escaping (URL) -> Void) -> [PhotonActionSheetItem] {
        let openTopSites = PhotonActionSheetItem(title: Strings.AppMenuTopSitesTitleString, iconString: "menupanel-TopSites") { action in
            openURL(HomePanelType.topSites.localhostURL)
        }

        let openBookmarks = PhotonActionSheetItem(title: Strings.AppMenuBookmarksTitleString, iconString: "menupanel-Bookmarks") { action in
            openURL(HomePanelType.bookmarks.localhostURL)
        }

        let openHistory = PhotonActionSheetItem(title: Strings.AppMenuHistoryTitleString, iconString: "menupanel-History") { action in
            openURL(HomePanelType.history.localhostURL)
        }

        let openReadingList = PhotonActionSheetItem(title: Strings.AppMenuReadingListTitleString, iconString: "menupanel-ReadingList") { action in
            openURL(HomePanelType.readingList.localhostURL)
        }

        return [openTopSites, openBookmarks, openHistory, openReadingList]
    }

    /*
    Returns a list of actions which is used to build the general browser menu
    These items repersent global options that are presented in the menu
    TODO: These icons should all have the icons and use Strings.swift
    */

    typealias PageOptionsVC = QRCodeViewControllerDelegate & SettingsDelegate & PresentingModalViewControllerDelegate & UIViewController

    func getOtherPanelActions(vcDelegate: PageOptionsVC) -> [PhotonActionSheetItem] {
        let openQR = PhotonActionSheetItem(title: "QR Scanner", iconString: "menu-ScanQRCode") { action in
            let qrCodeViewController = QRCodeViewController()
            qrCodeViewController.qrCodeDelegate = vcDelegate
            let controller = UINavigationController(rootViewController: qrCodeViewController)
            vcDelegate.present(controller, animated: true, completion: nil)
        }

        let openSettings = PhotonActionSheetItem(title: "Settings", iconString: "menu-Settings") { action in
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            settingsTableViewController.settingsDelegate = vcDelegate

            let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
            controller.popoverDelegate = vcDelegate
            controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
            vcDelegate.present(controller, animated: true, completion: nil)
        }

        let noImageText = NoImageModeHelper.isActivated(profile.prefs) ? "Hide Images" : "Show Images"
        let noImageMode = PhotonActionSheetItem(title: noImageText, iconString: "menu-NoImageMode") { action in
            NoImageModeHelper.toggle(profile: self.profile, tabManager: self.tabManager)
        }

        let nightModeText = NightModeHelper.isActivated(profile.prefs) ? "Turn off Night Mode" : "Turn on Night Mode"
        let nightMode = PhotonActionSheetItem(title: nightModeText, iconString: "menu-NightMode") { action in
            NightModeHelper.toggle(self.profile.prefs, tabManager: self.tabManager)
        }

        return [openSettings, openQR, noImageMode, nightMode]
    }

    func getTabActions(tab: Tab, buttonView: UIView, presentShareMenu: @escaping (URL, Tab, UIView, UIPopoverArrowDirection) -> Void) -> [PhotonActionSheetItem] {

        let toggleActionTitle = tab.desktopSite ? Strings.AppMenuViewMobileSiteTitleString : Strings.AppMenuViewDesktopSiteTitleString
        let toggleDesktopSite = PhotonActionSheetItem(title: toggleActionTitle, iconString: "menu-RequestDesktopSite") { action in
            tab.toggleDesktopSite()
        }

        let setHomePage = PhotonActionSheetItem(title: Strings.AppMenuSetHomePageTitleString, iconString: "menu-Home") { action in
            //TODO: pass a VC. this doesnt _need_ to be a HomePageHelper
            HomePageHelper(prefs: self.profile.prefs).setHomePage(toTab: tab, presentAlertOn: nil)
        }

        //TODO: Add to pocket

        let bookmarkPage = PhotonActionSheetItem(title: Strings.AppMenuAddBookmarkTitleString, iconString: "menu-Bookmark") { action in
            //TODO: can all this logic go somewhere else?
            guard let url = tab.url else { return }
            let absoluteString = url.absoluteString
            let shareItem = ShareItem(url: absoluteString, title: tab.title, favicon: tab.displayFavicon)
            _ = self.profile.bookmarks.shareItem(shareItem)
            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                withUserData: userData,
                                                                                toApplication: UIApplication.shared)
            tab.isBookmarked = true
        }

        let removeBookmark = PhotonActionSheetItem(title: Strings.AppMenuRemoveBookmarkTitleString, iconString: "menu-Bookmark") { action in
            //TODO: can all this logic go somewhere else?
            guard let url = tab.url else { return }
            let absoluteString = url.absoluteString
            self.profile.bookmarks.modelFactory >>== {
                $0.removeByURL(absoluteString).uponQueue(DispatchQueue.main) { res in
                    if res.isSuccess {
                        tab.isBookmarked = false
                    }
                }
            }
        }

        let share = PhotonActionSheetItem(title: "Share", iconString: "") { action in
            guard let url = self.tabManager.selectedTab?.url else { return }
            guard let tab = self.tabManager.selectedTab else { return }
            presentShareMenu(url, tab, buttonView, .up)
        }

        let bookmarkAction = tab.isBookmarked ? removeBookmark : bookmarkPage
        return [toggleDesktopSite, bookmarkAction, setHomePage, share]
    }

    func getTabMenuActions(openURL: @escaping (URL?, Bool) -> Void) -> [PhotonActionSheetItem] {
        let openTab = PhotonActionSheetItem(title: "Open new Tab", iconString: "menu-NewTab") { action in
            openURL(nil, false)
        }

        let openPrivateTab = PhotonActionSheetItem(title: "Open private Tab", iconString: "menu-NewTab") { action in
            openURL(nil, true)

        }

        let openTabTray = PhotonActionSheetItem(title: "Show Tabs", iconString: "") { action in
            //TODO: This has its own bug
        }

        return [openTab, openPrivateTab, openTabTray]
    }

}
