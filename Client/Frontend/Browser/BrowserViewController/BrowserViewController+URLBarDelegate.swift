/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import Telemetry

extension BrowserViewController: URLBarDelegate {
    func showTabTray() {
        Sentry.shared.clearBreadcrumbs()

        updateFindInPageVisibility(visible: false)
        
        var shouldShowChronTabs = false // default don't show
        let chronDebugValue = profile.prefs.boolForKey(PrefsKeys.ChronTabsPrefKey)
        let chronLPValue = chronTabsUserResearch?.chronTabsState ?? false
        // Only allow chron tabs on iPhone
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Respect debug mode chron tab value on
            if chronDebugValue != nil {
                shouldShowChronTabs = chronDebugValue!
            // Respect build channel based settings
            } else if chronDebugValue == nil {
                if AppConstants.CHRONOLOGICAL_TABS {
                    shouldShowChronTabs = true
                } else {
                    // Respect LP value
                    shouldShowChronTabs = chronLPValue
                }
            }
        }
        if shouldShowChronTabs {
            let tabTrayViewController = TabTrayV3ViewController(tabTrayDelegate: self, profile: profile)
            let controller: UINavigationController
            if #available(iOS 13.0, *) {
                controller = UINavigationController(rootViewController: tabTrayViewController)
                controller.presentationController?.delegate = tabTrayViewController
                // If we're not using the system theme, override the view's style to match
                if !ThemeManager.instance.systemThemeIsOn {
                    controller.overrideUserInterfaceStyle = ThemeManager.instance.userInterfaceStyle
                }
            } else {
                let themedController = ThemedNavigationController(rootViewController: tabTrayViewController)
                themedController.presentingModalViewControllerDelegate = self
                controller = themedController
            }
            self.present(controller, animated: true, completion: nil)
            self.tabTrayControllerV3 = tabTrayViewController
//        } else if shouldShowChronTabs {
//            let tabTrayViewController = TabTrayV2ViewController(tabTrayDelegate: self, profile: profile)
//            let controller: UINavigationController
//            if #available(iOS 13.0, *) {
//                controller = UINavigationController(rootViewController: tabTrayViewController)
//                controller.presentationController?.delegate = tabTrayViewController
//                // If we're not using the system theme, override the view's style to match
//                if !ThemeManager.instance.systemThemeIsOn {
//                    controller.overrideUserInterfaceStyle = ThemeManager.instance.userInterfaceStyle
//                }
//            } else {
//                let themedController = ThemedNavigationController(rootViewController: tabTrayViewController)
//                themedController.presentingModalViewControllerDelegate = self
//                controller = themedController
//            }
//            self.present(controller, animated: true, completion: nil)
//            self.tabTrayControllerV2 = tabTrayViewController
        } else {
            let tabTrayController = TabTrayControllerV1(tabManager: tabManager, profile: profile, tabTrayDelegate: self)
            navigationController?.pushViewController(tabTrayController, animated: true)
            self.tabTrayController = tabTrayController
        }

        if let tab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(tab)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .tabTray)
    }

    func urlBarDidPressReload(_ urlBar: URLBarView) {
        tabManager.selectedTab?.reload()
    }

    func urlBarDidPressQRButton(_ urlBar: URLBarView) {
        let qrCodeViewController = QRCodeViewController()
        qrCodeViewController.qrCodeDelegate = self
        let controller = QRCodeNavigationController(rootViewController: qrCodeViewController)
        self.present(controller, animated: true, completion: nil)
    }

    func urlBarDidPressPageOptions(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab, let urlString = tab.url?.absoluteString, !urlBar.inOverlayMode else { return }

        let actionMenuPresenter: (URL, Tab, UIView, UIPopoverArrowDirection) -> Void  = { (url, tab, view, _) in
            self.presentActivityViewController(url, tab: tab, sourceView: view, sourceRect: view.bounds, arrowDirection: .up)
        }

        let findInPageAction = {
            self.updateFindInPageVisibility(visible: true)
        }
        
        let reportSiteIssue = {
            self.openURLInNewTab(SupportUtils.URLForReportSiteIssue(self.urlBar.currentURL?.absoluteString))
        }

        let successCallback: (String, ButtonToastAction) -> Void = { (successMessage, toastAction) in
            switch toastAction {
            case .removeBookmark:
                let toast = ButtonToast(labelText: successMessage, buttonText: Strings.UndoString, textAlignment: .left) { isButtonTapped in
                    isButtonTapped ? self.addBookmark(url: urlString) : nil
                }
                self.show(toast: toast)
            default:
                SimpleToast().showAlertWithText(successMessage, bottomContainer: self.webViewContainer)
            }
        }

        let deferredBookmarkStatus: Deferred<Maybe<Bool>> = fetchBookmarkStatus(for: urlString)
        let deferredPinnedTopSiteStatus: Deferred<Maybe<Bool>> = fetchPinnedTopSiteStatus(for: urlString)

        // Wait for both the bookmark status and the pinned status
        deferredBookmarkStatus.both(deferredPinnedTopSiteStatus).uponQueue(.main) {
            let shouldShowNewTabButton = false
            let isBookmarked = $0.successValue ?? false
            let isPinned = $1.successValue ?? false
            let pageActions = self.getTabActions(tab: tab, buttonView: button, presentShareMenu: actionMenuPresenter,
                                                 findInPage: findInPageAction, reportSiteIssue: reportSiteIssue, presentableVC: self, isBookmarked: isBookmarked,
                                                 isPinned: isPinned, shouldShowNewTabButton: shouldShowNewTabButton, success: successCallback)
            self.presentSheetWith(title: Strings.PageActionMenuTitle, actions: pageActions, on: self, from: button)
        }
    }

    func urlBarDidLongPressPageOptions(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab else { return }
        guard let url = tab.canonicalURL?.displayURL, self.presentedViewController == nil else {
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        presentActivityViewController(url, tab: tab, sourceView: button, sourceRect: button.bounds, arrowDirection: .up)
    }

    func urlBarDidTapShield(_ urlBar: URLBarView) {
        if let tab = self.tabManager.selectedTab {
            let trackingProtectionMenu = self.getTrackingSubMenu(for: tab)
            let title = String.localizedStringWithFormat(Strings.TPPageMenuTitle, tab.url?.host ?? "")
            LeanPlumClient.shared.track(event: .trackingProtectionMenu)
            TelemetryWrapper.recordEvent(category: .action, method: .press, object: .trackingProtectionMenu)
            self.presentSheetWith(title: title, actions: trackingProtectionMenu, on: self, from: urlBar)
        }
    }

    func urlBarDidPressStop(_ urlBar: URLBarView) {
        tabManager.selectedTab?.stop()
    }

    func urlBarDidPressTabs(_ urlBar: URLBarView) {
        showTabTray()
    }

    func urlBarDidPressReaderMode(_ urlBar: URLBarView) {
        libraryDrawerViewController?.close()

        guard let tab = tabManager.selectedTab, let readerMode = tab.getContentScript(name: "ReaderMode") as? ReaderMode else {
            return
        }
        switch readerMode.state {
        case .available:
            enableReaderMode()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeOpenButton)
            LeanPlumClient.shared.track(event: .useReaderView)
        case .active:
            disableReaderMode()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readerModeCloseButton)
        case .unavailable:
            break
        }
    }

    func urlBarDidLongPressReaderMode(_ urlBar: URLBarView) -> Bool {
        guard let tab = tabManager.selectedTab,
               let url = tab.url?.displayURL
            else {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAddPageGeneralErrorAccessibilityLabel)
                return false
        }

        let result = profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)

        switch result.value {
        case .success:
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAddPageSuccessAcessibilityLabel)
            SimpleToast().showAlertWithText(Strings.ShareAddToReadingListDone, bottomContainer: self.webViewContainer)
        case .failure(let error):
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: String.ReaderModeAddPageMaybeExistsErrorAccessibilityLabel)
            print("readingList.createRecordWithURL(url: \"\(url.absoluteString)\", ...) failed with error: \(error)")
        }
        return true
    }

    func urlBarDidLongPressReload(_ urlBar: URLBarView, from button: UIButton) {
        guard let tab = tabManager.selectedTab else {
            return
        }
        let urlActions = self.getRefreshLongPressMenu(for: tab)
        guard !urlActions.isEmpty else {
            return
        }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        let shouldSuppress = !topTabsVisible && UIDevice.current.userInterfaceIdiom == .pad
        presentSheetWith(actions: [urlActions], on: self, from: button, suppressPopover: shouldSuppress)
    }

    func locationActionsForURLBar(_ urlBar: URLBarView) -> [AccessibleAction] {
        if UIPasteboard.general.string != nil {
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    func urlBarDisplayTextForURL(_ url: URL?) -> (String?, Bool) {
        // use the initial value for the URL so we can do proper pattern matching with search URLs
        var searchURL = self.tabManager.selectedTab?.url
        if let url = searchURL, InternalURL.isValid(url: url) {
            searchURL = url
        }
        if let query = profile.searchEngines.queryForSearchURL(searchURL as URL?) {
            return (query, true)
        } else {
            return (url?.absoluteString, false)
        }
    }

    func urlBarDidLongPressLocation(_ urlBar: URLBarView) {
        let urlActions = self.getLongPressLocationBarActions(with: urlBar, webViewContainer: self.webViewContainer)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        self.presentSheetWith(actions: [urlActions], on: self, from: urlBar)
    }

    func urlBarDidPressScrollToTop(_ urlBar: URLBarView) {
        if let selectedTab = tabManager.selectedTab, firefoxHomeViewController == nil {
            // Only scroll to top if we are not showing the home view controller
            selectedTab.webView?.scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }

    func urlBarLocationAccessibilityActions(_ urlBar: URLBarView) -> [UIAccessibilityCustomAction]? {
        return locationActionsForURLBar(urlBar).map { $0.accessibilityCustomAction }
    }

    func urlBar(_ urlBar: URLBarView, didRestoreText text: String) {
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
        }

        searchController?.searchQuery = text
        searchLoader?.setQueryWithoutAutocomplete(text)
    }

    func urlBar(_ urlBar: URLBarView, didEnterText text: String) {
        urlBar.updateSearchEngineImage()
        if text.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
        }

        searchController?.searchQuery = text
        searchLoader?.query = text
    }

    func urlBar(_ urlBar: URLBarView, didSubmitText text: String) {
        guard let currentTab = tabManager.selectedTab else { return }

        if let fixupURL = URIFixup.getURL(text) {
            // The user entered a URL, so use it.
            finishEditingAndSubmit(fixupURL, visitType: VisitType.typed, forTab: currentTab)
            return
        }

        // We couldn't build a URL, so check for a matching search keyword.
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard let possibleKeywordQuerySeparatorSpace = trimmedText.firstIndex(of: " ") else {
            submitSearchText(text, forTab: currentTab)
            return
        }

        let possibleKeyword = String(trimmedText[..<possibleKeywordQuerySeparatorSpace])
        let possibleQuery = String(trimmedText[trimmedText.index(after: possibleKeywordQuerySeparatorSpace)...])

        profile.places.getBookmarkURLForKeyword(keyword: possibleKeyword).uponQueue(.main) { result in

            if var urlString = result.successValue ?? "",
                let escapedQuery = possibleQuery.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
                let range = urlString.range(of: "%s") {
                urlString.replaceSubrange(range, with: escapedQuery)

                if let url = URL(string: urlString) {
                    self.finishEditingAndSubmit(url, visitType: VisitType.typed, forTab: currentTab)
                    return
                }
            }

            self.submitSearchText(text, forTab: currentTab)
        }
    }

    func submitSearchText(_ text: String, forTab tab: Tab) {
        let engine = profile.searchEngines.defaultEngine

        if let searchURL = engine.searchURLForQuery(text) {
            // We couldn't find a matching search keyword, so do a search query.
            Telemetry.default.recordSearch(location: .actionBar, searchEngine: engine.engineID ?? "other")
            GleanMetrics.Search.counts["\(engine.engineID ?? "custom").\(SearchesMeasurement.SearchLocation.actionBar.rawValue)"].add()
            searchTelemetry?.shouldSetUrlTypeSearch = true
            finishEditingAndSubmit(searchURL, visitType: VisitType.typed, forTab: tab)
        } else {
            // We still don't have a valid URL, so something is broken. Give up.
            print("Error handling URL entry: \"\(text)\".")
            assertionFailure("Couldn't generate search URL: \(text)")
        }
    }

    func urlBarDidEnterOverlayMode(_ urlBar: URLBarView) {
        libraryDrawerViewController?.close()
        urlBar.updateSearchEngineImage()
        guard let profile = profile as? BrowserProfile else {
            return
        }

        if .blankPage == NewTabAccessors.getNewTabPage(profile.prefs) {
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: UIAccessibility.Notification.screenChanged)
        } else {
            if let toast = clipboardBarDisplayHandler?.clipboardToast {
                toast.removeFromSuperview()
            }

            showFirefoxHome(inline: false)
        }

        LeanPlumClient.shared.track(event: .interactWithURLBar)
    }

    func urlBarDidLeaveOverlayMode(_ urlBar: URLBarView) {
        destroySearchController()
        updateInContentHomePanel(tabManager.selectedTab?.url as URL?)
    }

    func urlBarDidBeginDragInteraction(_ urlBar: URLBarView) {
        dismissVisibleMenus()
    }
}
