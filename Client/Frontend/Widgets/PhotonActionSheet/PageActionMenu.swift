/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage

enum ButtonToastAction {
    case share
    case addToReadingList
    case bookmarkPage
    case removeBookmark
    case copyUrl
    case pinPage
    case removePinPage
}

extension PhotonActionSheetProtocol {
    fileprivate func share(fileURL: URL, buttonView: UIView, presentableVC: PresentableVC) {
        let helper = ShareExtensionHelper(url: fileURL, tab: tabManager.selectedTab)
        let controller = helper.createActivityViewController { completed, activityType in
            print("Shared downloaded file: \(completed)")
        }

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = buttonView
            popoverPresentationController.sourceRect = buttonView.bounds
            popoverPresentationController.permittedArrowDirections = .up
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
        presentableVC.present(controller, animated: true, completion: nil)
    }

    func getTabActions(tab: Tab, buttonView: UIView,
                       presentShareMenu: @escaping (URL, Tab, UIView, UIPopoverArrowDirection) -> Void,
                       findInPage: @escaping () -> Void,
                       reportSiteIssue: @escaping () -> Void,
                       presentableVC: PresentableVC,
                       isBookmarked: Bool,
                       isPinned: Bool,
                       shouldShowNewTabButton: Bool,
                       success: @escaping (String, ButtonToastAction) -> Void) -> Array<[PhotonActionSheetItem]> {
        if tab.url?.isFileURL ?? false {
            let shareFile = PhotonActionSheetItem(title: .AppMenu.SharePageTitleString, iconString: "action_share") {  _,_ in
                guard let url = tab.url else { return }

                self.share(fileURL: url, buttonView: buttonView, presentableVC: presentableVC)
            }

            return [[shareFile]]
        }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        let toggleActionIcon: String
        let siteTypeTelemetryObject: TelemetryWrapper.EventObject
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .AppMenu.ViewDesktopSiteTitleString : .AppMenu.ViewMobileSiteTitleString
            toggleActionIcon = tab.changedUserAgent ?
                "menu-RequestDesktopSite" : "menu-ViewMobile"
            siteTypeTelemetryObject = .requestDesktopSite
        } else {
            toggleActionTitle = tab.changedUserAgent ? .AppMenu.ViewMobileSiteTitleString : .AppMenu.ViewDesktopSiteTitleString
            toggleActionIcon = tab.changedUserAgent ?
                "menu-ViewMobile" : "menu-RequestDesktopSite"
            siteTypeTelemetryObject = .requestMobileSite
        }
        let toggleDesktopSite = PhotonActionSheetItem(title: toggleActionTitle, iconString: toggleActionIcon) { _,_  in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: tab.changedUserAgent, isPrivate: tab.isPrivate)
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: siteTypeTelemetryObject)
            }
        }

        let addReadingList = PhotonActionSheetItem(title: .AppMenu.AddToReadingListTitleString, iconString: "addToReadingList") { _,_  in
            guard let url = tab.url?.displayURL else { return }

            self.profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .readingListItem, value: .pageActionMenu)
            success(.AppMenu.AddToReadingListConfirmMessage, .addToReadingList)
        }

        let bookmarkPage = PhotonActionSheetItem(title: .AppMenu.AddBookmarkTitleString2, iconString: "menu-Bookmark") { _,_  in
            guard let url = tab.canonicalURL?.displayURL,
                let bvc = presentableVC as? BrowserViewController else {
                    return
            }
            bvc.addBookmark(url: url.absoluteString, title: tab.title, favicon: tab.displayFavicon)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .pageActionMenu)
        }

        let removeBookmark = PhotonActionSheetItem(title: .AppMenu.RemoveBookmarkTitleString, iconString: "menu-Bookmark-Remove") { _,_  in
            guard let url = tab.url?.displayURL else { return }

            self.profile.places.deleteBookmarksWithURL(url: url.absoluteString).uponQueue(.main) { result in
                if result.isSuccess {
                    success(.AppMenu.RemoveBookmarkConfirmMessage, .removeBookmark)
                }
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .pageActionMenu)
        }

        let addToShortcuts = PhotonActionSheetItem(title: .AddToShortcutsActionTitle, iconString: "action_pin") { _,_  in
            guard let url = tab.url?.displayURL, let sql = self.profile.history as? SQLiteHistory else { return }

            sql.getSites(forURLs: [url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }
                return self.profile.history.addPinnedTopSite(site)
            }.uponQueue(.main) { result in
                if result.isSuccess {
                    success(.AppMenu.AddPinToShortcutsConfirmMessage, .pinPage)
                }
            }
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pinToTopSites)
        }

        let removeFromShortcuts = PhotonActionSheetItem(title: .RemoveFromShortcutsActionTitle, iconString: "action_unpin") { _,_  in
            guard let url = tab.url?.displayURL, let sql = self.profile.history as? SQLiteHistory else { return }

            sql.getSites(forURLs: [url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }

                return self.profile.history.removeFromPinnedTopSites(site)
            }.uponQueue(.main) { result in
                if result.isSuccess {
                    success(.AppMenu.RemovePinFromShortcutsConfirmMessage, .removePinPage)
                }
            }
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .removePinnedSite)
        }

        let sendToDevice = PhotonActionSheetItem(title: .AppMenu.SendLinkToDeviceTitle, iconString: "menu-Send-to-Device") { _,_  in
            guard let bvc = presentableVC as? PresentableVC & InstructionsViewControllerDelegate & DevicePickerViewControllerDelegate else { return }
            if !self.profile.hasAccount() {
                let instructionsViewController = InstructionsViewController()
                instructionsViewController.delegate = bvc
                let navigationController = UINavigationController(rootViewController: instructionsViewController)
                navigationController.modalPresentationStyle = .formSheet
                bvc.present(navigationController, animated: true, completion: nil)
                return
            }

            let devicePickerViewController = DevicePickerViewController()
            devicePickerViewController.pickerDelegate = bvc
            devicePickerViewController.profile = self.profile
            devicePickerViewController.profileNeedsShutdown = false
            let navigationController = UINavigationController(rootViewController: devicePickerViewController)
            navigationController.modalPresentationStyle = .formSheet
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sendToDevice)
            bvc.present(navigationController, animated: true, completion: nil)
        }

        let sharePage = PhotonActionSheetItem(title: .ShareContextMenuTitle, iconString: "action_share") { _,_  in
            guard let url = tab.canonicalURL?.displayURL else { return }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
            if let temporaryDocument = tab.temporaryDocument {
                temporaryDocument.getURL().uponQueue(.main, block: { tempDocURL in
                    // If we successfully got a temp file URL, share it like a downloaded file,
                    // otherwise present the ordinary share menu for the web URL.
                    if tempDocURL.isFileURL {
                        self.share(fileURL: tempDocURL, buttonView: buttonView, presentableVC: presentableVC)
                    } else {
                        presentShareMenu(url, tab, buttonView, .up)
                    }
                })
            } else {
                presentShareMenu(url, tab, buttonView, .up)
            }
        }

        let copyURL = PhotonActionSheetItem(title: .AppMenu.CopyLinkTitleString, iconString: "menu-Copy-Link") { _,_ in
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .copyAddress)
            if let url = tab.canonicalURL?.displayURL {
                UIPasteboard.general.url = url
                success(.AppMenu.CopyURLConfirmMessage, .copyUrl)
            }
        }
        
        let refreshPage = PhotonActionSheetItem(title: .ReloadPageTitle, iconString: "nav-refresh") { _,_ in
            self.tabManager.selectedTab?.reload()
        }
        
        let stopRefreshPage = PhotonActionSheetItem(title: .AppMenu.StopReloadPageTitle, iconString: "nav-stop") { _,_ in
            self.tabManager.selectedTab?.stop()
        }
        
        let refreshAction = tab.loading ? stopRefreshPage : refreshPage
        var refreshActions = [refreshAction]
        
        if let url = tab.webView?.url, let helper = tab.contentBlocker, helper.isEnabled, helper.blockingStrengthPref == .strict {
            let isSafelisted = helper.status == .safelisted
            
            let title = !isSafelisted ? String.TrackingProtectionReloadWithout : String.TrackingProtectionReloadWith
            let imageName = helper.isEnabled ? "menu-TrackingProtection-Off" : "menu-TrackingProtection"
            let toggleTP = PhotonActionSheetItem(title: title, iconString: imageName) { _,_ in
                ContentBlocker.shared.safelist(enable: !isSafelisted, url: url) {
                    tab.reload()
                }
            }
            refreshActions.append(toggleTP)
        }
        
        let pinAction = (isPinned ? removeFromShortcuts : addToShortcuts)
        var section1 = [pinAction]
        var section2 = [toggleDesktopSite]
        var section3 = [sharePage]

        // Disable bookmarking and reading list if the URL is too long.
        if !tab.urlIsTooLong {
            if tab.readerModeAvailableOrActive {
                section1.insert(addReadingList, at: 0)
            }
            section1.insert((isBookmarked ? removeBookmark : bookmarkPage), at: 0)
        }

        section3.insert(contentsOf: [copyURL, sendToDevice], at: 0)

        // Disable find in page and report site issue if document is pdf.
        if tab.mimeType != MIMEType.PDF {
            let findInPageAction = PhotonActionSheetItem(title: .AppMenu.FindInPageTitleString, iconString: "menu-FindInPage") { _,_ in
                findInPage()
            }
            section2.insert(findInPageAction, at: 0)
            
            let reportSiteIssueAction = PhotonActionSheetItem(title: .AppMenu.ReportSiteIssueTitleString, iconString: "menu-reportSiteIssue") { _,_ in
                reportSiteIssue()
            }
            section2.append(reportSiteIssueAction)
        }

        if shouldShowNewTabButton && tab.readerModeAvailableOrActive {
            return [refreshActions, section1, section2, section3]
        } else {
            return [section1, section2, section3]
        }
    }

}
