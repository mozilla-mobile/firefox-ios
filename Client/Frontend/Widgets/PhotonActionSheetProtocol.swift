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

private let log = Logger.browserLogger

extension PhotonActionSheetProtocol {
    typealias PresentableVC = UIViewController & UIPopoverPresentationControllerDelegate
    typealias MenuAction = () -> Void
    typealias IsPrivateTab = Bool
    typealias URLOpenAction = (URL?, IsPrivateTab) -> Void
    
    func presentSheetWith(actions: [[PhotonActionSheetItem]], on viewController: PresentableVC, from view: UIView, supressPopover: Bool = false) {
        let sheet = PhotonActionSheet(actions: actions)
        sheet.modalPresentationStyle =  (UIDevice.current.userInterfaceIdiom == .pad && !supressPopover) ? .popover : .overCurrentContext
        sheet.photonTransitionDelegate = PhotonActionSheetAnimator()
        
        if let popoverVC = sheet.popoverPresentationController, sheet.modalPresentationStyle == .popover {
            popoverVC.delegate = viewController
            popoverVC.sourceView = view
            popoverVC.sourceRect = CGRect(x: view.frame.width/2, y: view.frame.size.height * 0.75, width: 1, height: 1)
            popoverVC.permittedArrowDirections = UIPopoverArrowDirection.up
            popoverVC.backgroundColor = UIConstants.AppBackgroundColor.withAlphaComponent(0.7)
        }
        viewController.present(sheet, animated: true, completion: nil)
    }
    
    //Returns a list of actions which is used to build a menu
    //OpenURL is a closure that can open a given URL in some view controller. It is up to the class using the menu to know how to open it
    func getHomePanelActions() -> [PhotonActionSheetItem] {
        guard let tab = self.tabManager.selectedTab else { return [] }

        let openTopSites = PhotonActionSheetItem(title: Strings.AppMenuTopSitesTitleString, iconString: "menu-panel-TopSites") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.topSites.localhostURL) as URLRequest)
        }

        let openBookmarks = PhotonActionSheetItem(title: Strings.AppMenuBookmarksTitleString, iconString: "menu-panel-Bookmarks") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.bookmarks.localhostURL) as URLRequest)
        }
        
        let openHistory = PhotonActionSheetItem(title: Strings.AppMenuHistoryTitleString, iconString: "menu-panel-History") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.history.localhostURL) as URLRequest)
        }
        
        let openReadingList = PhotonActionSheetItem(title: Strings.AppMenuReadingListTitleString, iconString: "menu-panel-ReadingList") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.readingList.localhostURL) as URLRequest)
        }
        
        let openHomePage = PhotonActionSheetItem(title: Strings.AppMenuOpenHomePageTitleString, iconString: "menu-Home") { _ in
            HomePageHelper(prefs: self.profile.prefs).openHomePage(tab)
        }
        
        var actions = [openTopSites, openBookmarks, openReadingList, openHistory]
        if HomePageHelper(prefs: self.profile.prefs).isHomePageAvailable {
            actions.insert(openHomePage, at: 0)
        }

        return actions
    }
    
    /*
     Returns a list of actions which is used to build the general browser menu
     These items repersent global options that are presented in the menu
     TODO: These icons should all have the icons and use Strings.swift
     */
    
    typealias PageOptionsVC = QRCodeViewControllerDelegate & SettingsDelegate & PresentingModalViewControllerDelegate & UIViewController
    
    func getOtherPanelActions(vcDelegate: PageOptionsVC) -> [PhotonActionSheetItem] {
        var noImageMode: PhotonActionSheetItem? = nil
        if #available(iOS 11, *) {
            let noImageEnabled = NoImageModeHelper.isActivated(profile.prefs)
            let noImageText = noImageEnabled ? Strings.AppMenuNoImageModeDisable : Strings.AppMenuNoImageModeEnable
            noImageMode = PhotonActionSheetItem(title: noImageText, iconString: "menu-NoImageMode", isEnabled: noImageEnabled) { action in
                NoImageModeHelper.toggle(profile: self.profile, tabManager: self.tabManager)
            }
        }

        let nightModeEnabled = NightModeHelper.isActivated(profile.prefs)
        let nightModeText = nightModeEnabled ? Strings.AppMenuNightModeDisable : Strings.AppMenuNightModeEnable
        let nightMode = PhotonActionSheetItem(title: nightModeText, iconString: "menu-NightMode", isEnabled: nightModeEnabled) { action in
            NightModeHelper.toggle(self.profile.prefs, tabManager: self.tabManager)
        }

        let openSettings = PhotonActionSheetItem(title: Strings.AppMenuSettingsTitleString, iconString: "menu-Settings") { action in
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            settingsTableViewController.settingsDelegate = vcDelegate

            let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
            controller.popoverDelegate = vcDelegate
            controller.modalPresentationStyle = UIModalPresentationStyle.formSheet
            vcDelegate.present(controller, animated: true, completion: nil)
        }

        if let noImageMode = noImageMode {
            return [noImageMode, nightMode, openSettings]
        }
        return [nightMode, openSettings]
    }
    
    func getTabActions(tab: Tab, buttonView: UIView,
                       presentShareMenu: @escaping (URL, Tab, UIView, UIPopoverArrowDirection) -> Void,
                       findInPage:  @escaping () -> Void,
                       presentableVC: PresentableVC,
                       success: @escaping (String) -> Void) -> Array<[PhotonActionSheetItem]> {
        
        let toggleActionTitle = tab.desktopSite ? Strings.AppMenuViewMobileSiteTitleString : Strings.AppMenuViewDesktopSiteTitleString
        let toggleDesktopSite = PhotonActionSheetItem(title: toggleActionTitle, iconString: "menu-RequestDesktopSite") { action in
            tab.toggleDesktopSite()
        }
        
        let addReadingList = PhotonActionSheetItem(title: Strings.AppMenuAddToReadingListTitleString, iconString: "addToReadingList") { action in
            guard let url = tab.url?.displayURL else { return }

            self.profile.readingList?.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            success(Strings.AppMenuAddToReadingListConfirmMessage)
        }

        let findInPageAction = PhotonActionSheetItem(title: Strings.AppMenuFindInPageTitleString, iconString: "menu-FindInPage") { action in
            findInPage()
        }

        let bookmarkPage = PhotonActionSheetItem(title: Strings.AppMenuAddBookmarkTitleString, iconString: "menu-Bookmark") { action in
            //TODO: can all this logic go somewhere else?
            guard let url = tab.canonicalURL?.displayURL else { return }
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
            success(Strings.AppMenuAddBookmarkConfirmMessage)
        }
        
        let removeBookmark = PhotonActionSheetItem(title: Strings.AppMenuRemoveBookmarkTitleString, iconString: "menu-Bookmark-Remove") { action in
            //TODO: can all this logic go somewhere else?
            guard let url = tab.url?.displayURL else { return }
            let absoluteString = url.absoluteString
            self.profile.bookmarks.modelFactory >>== {
                $0.removeByURL(absoluteString).uponQueue(.main) { res in
                    if res.isSuccess {
                        tab.isBookmarked = false
                        success(Strings.AppMenuRemoveBookmarkConfirmMessage)
                    }
                }
            }
        }
        
        let pinToTopSites = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin") { action in
            guard let url = tab.url?.displayURL,
                  let sql = self.profile.history as? SQLiteHistory else { return }
            let absoluteString = url.absoluteString
            
            sql.getSitesForURLs([absoluteString]) >>== { result in
                guard let siteOp = result.asArray().first, let site = siteOp else {
                    log.warning("Could not get site for \(absoluteString)")
                    return
                }
                
                _ = self.profile.history.addPinnedTopSite(site).value
            }
        }

        let sendToDevice = PhotonActionSheetItem(title: Strings.SendToDeviceTitle, iconString: "menu-Send-to-Device") { action in
            guard let bvc = presentableVC as? PresentableVC & InstructionsViewControllerDelegate & ClientPickerViewControllerDelegate else { return }
            if !self.profile.hasAccount() {
                let instructionsViewController = InstructionsViewController()
                instructionsViewController.delegate = bvc
                let navigationController = UINavigationController(rootViewController: instructionsViewController)
                bvc.present(navigationController, animated: true, completion: nil)
                return
            }

            let clientPickerViewController = ClientPickerViewController()
            clientPickerViewController.clientPickerDelegate = bvc
            clientPickerViewController.profile = self.profile
            clientPickerViewController.profileNeedsShutdown = false
            let navigationController = UINavigationController(rootViewController: clientPickerViewController)
            bvc.present(navigationController, animated: true, completion: nil)
        }
        
        let share = PhotonActionSheetItem(title: Strings.AppMenuSharePageTitleString, iconString: "action_share") { action in
            guard let url = tab.canonicalURL?.displayURL else { return }
            presentShareMenu(url, tab, buttonView, .up)
        }

        let copyURL = PhotonActionSheetItem(title: Strings.AppMenuCopyURLTitleString, iconString: "menu-Copy-Link") { _ in
            UIPasteboard.general.url = tab.canonicalURL?.displayURL
            success(Strings.AppMenuCopyURLConfirmMessage)
        }

        var topActions: [PhotonActionSheetItem] = []

        // Disable bookmarking and reading list if the URL is too long.
        if !tab.urlIsTooLong {
            topActions.append(tab.isBookmarked ? removeBookmark : bookmarkPage)

            if tab.readerModeAvailableOrActive {
                topActions.append(addReadingList)
            }
        }

        return [topActions, [copyURL, findInPageAction, toggleDesktopSite, pinToTopSites, sendToDevice], [share]]
    }
}

