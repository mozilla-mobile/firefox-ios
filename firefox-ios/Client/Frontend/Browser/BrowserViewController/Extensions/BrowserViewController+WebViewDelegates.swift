// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
@preconcurrency import WebKit
import Shared
import UIKit
import Photos
import SafariServices
import WebEngine

// MARK: - WKUIDelegate
extension BrowserViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let parentTab = tabManager[webView] else { return nil }
        guard parentTab.popupThrottler.canShowAlert(type: .popupWindow) else {
            logger.log("Popup window disallowed for exceeding threshold for tab.", level: .info, category: .webview)
            return nil
        }
        parentTab.popupThrottler.willShowAlert(type: .popupWindow)

        guard !navigationAction.isInternalUnprivileged,
              shouldRequestBeOpenedAsPopup(navigationAction.request)
        else {
            guard let url = navigationAction.request.url else { return nil }

            if url.scheme == "whatsapp" && UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            }

            return nil
        }

        guard !isPayPalPopUp(navigationAction) else { return nil }

        if navigationAction.canOpenExternalApp, let url = navigationAction.request.url {
            UIApplication.shared.open(url)
            return nil
        }

        let navigationUrl = navigationAction.request.url

        // Check for "data" scheme using WebViewNavigationHandlerImplementation
        let navigationHandler = WebViewNavigationHandlerImplementation { _ in }
        var shouldAllowDataScheme = true
        if navigationHandler.shouldFilterDataScheme(url: navigationUrl) {
            shouldAllowDataScheme = navigationHandler.shouldAllowDataScheme(for: navigationUrl)
        }

        guard shouldAllowDataScheme else { return nil }

        // If the page uses `window.open()` or `[target="_blank"]`, open the page in a new tab.
        // IMPORTANT!!: WebKit will perform the `URLRequest` automatically!! Attempting to do
        // the request here manually leads to incorrect results!!
        let newTab = tabManager.addPopupForParentTab(
            profile: profile,
            parentTab: parentTab,
            configuration: configuration
        )

        // Set new tab url to about:blank because webViews created through this callback are always popups
        newTab.url = URL(string: "about:blank")

        // Select the new tab immediately
        tabManager.selectTab(newTab)

        return newTab.webView
    }

    private func handleJavaScriptAlert<T: WKJavaScriptAlertInfo>(
        _ alert: T,
        for webView: WKWebView,
        spamCallback: @escaping @MainActor () -> Void
    ) {
        if jsAlertExceedsSpamLimits(webView) {
            handleSpammedJSAlert(spamCallback)
        } else if shouldDisplayJSAlertForWebView(webView) {
            logger.log("JavaScript \(alert.type.rawValue) panel will be presented.", level: .info, category: .webview)
            let alertController = alert.alertController()
            alertController.delegate = self
            present(alertController, animated: true)
        } else if let promptingTab = tabManager[webView] {
            logger.log("JavaScript \(alert.type.rawValue) panel is queued.", level: .info, category: .webview)
            promptingTab.queueJavascriptAlertPrompt(alert)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    ) {
        let messageAlert = MessageAlert(message: message,
                                        frame: frame,
                                        completionHandler: completionHandler)

        handleJavaScriptAlert(messageAlert, for: webView) {
            completionHandler()
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        let confirmAlert = ConfirmPanelAlert(message: message, frame: frame) { confirm in
            self.logger.log("JavaScript confirm panel was completed with result: \(confirm)", level: .info, category: .webview)
            completionHandler(confirm)
        }

        handleJavaScriptAlert(confirmAlert, for: webView) {
            completionHandler(false)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        let textInputAlert = TextInputAlert(message: prompt, frame: frame, defaultText: defaultText) { input in
            self.logger.log("JavaScript text input panel was completed with input", level: .info, category: .webview)
            completionHandler(input)
        }

        handleJavaScriptAlert(textInputAlert, for: webView) {
            completionHandler("")
        }
    }

    func webViewDidClose(_ webView: WKWebView) {
        Task { @MainActor in
            if let tab = tabManager[webView] {
                // Need to wait here in case we're waiting for a pending `window.open()`.
                try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 100)
                tabsPanelTelemetry.tabClosed(mode: tab.isPrivate ? .private : .normal)
                tabManager.removeTab(tab.tabUUID)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping @MainActor (UIContextMenuConfiguration?) -> Void
    ) {
        guard let url = elementInfo.linkURL,
              let currentTab = tabManager.selectedTab,
              let contextHelper = currentTab.getContentScript(
                name: ContextMenuHelper.name()
              ) as? ContextMenuHelper,
              let elements = contextHelper.elements
        else {
            completionHandler(nil)
            return
        }
        completionHandler(contextMenuConfiguration(for: url, webView: webView, elements: elements))
        ContextMenuTelemetry().shown(origin: elements.image != nil ? .imageLink : .webLink)
    }

    func webView(_ webView: WKWebView, contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo) {
        guard let currentTab = tabManager.selectedTab,
              let contextHelper = currentTab.getContentScript(
                name: ContextMenuHelper.name()
              ) as? ContextMenuHelper,
              let elements = contextHelper.elements
        else { return }
        ContextMenuTelemetry().dismissed(origin: elements.image != nil ? .imageLink : .webLink)
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        // If the tab isn't the selected one or we're on the homepage, do not show the media capture prompt
        guard tabManager.selectedTab?.webView === webView, !contentContainer.hasAnyHomepage else {
            decisionHandler(.deny)
            return
        }

        decisionHandler(.prompt)
    }

    // MARK: - Helpers

    private func handleSpammedJSAlert(_ callback: @escaping @MainActor () -> Void) {
        // User is being spammed. Squelch alert. Note that we have to do this after
        // a delay to avoid JS that could spin the CPU endlessly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { callback() }
    }

    private func contextMenuConfiguration(for url: URL,
                                          webView: WKWebView,
                                          elements: ContextMenuHelper.Elements) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: contextMenuPreviewProvider(for: url, webView: webView),
                                          actionProvider: contextMenuActionProvider(for: url,
                                                                                    webView: webView,
                                                                                    elements: elements))
    }

    private func contextMenuActionProvider(for url: URL,
                                           webView: WKWebView,
                                           elements: ContextMenuHelper.Elements) -> UIContextMenuActionProvider {
        return { [self] (suggested) -> UIMenu? in
            guard let currentTab = tabManager.selectedTab else { return nil }

            let isPrivate = currentTab.isPrivate

            let actions = createActions(isPrivate: isPrivate,
                                        url: url,
                                        addTab: self.addTab,
                                        title: elements.title,
                                        image: elements.image,
                                        currentTab: currentTab,
                                        webView: webView)
            return UIMenu(title: url.normalizedHost ?? url.absoluteString, children: actions)
        }
    }

    private func contextMenuPreviewProvider(for url: URL, webView: WKWebView) -> UIContextMenuContentPreviewProvider? {
        let provider: UIContextMenuContentPreviewProvider = {
            guard self.profile.prefs.boolForKey(PrefsKeys.ContextMenuShowLinkPreviews) ?? true else { return nil }

            let previewViewController = ContextMenuPreviewViewController()
            previewViewController.view.isUserInteractionEnabled = false
            let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)

            previewViewController.view.addSubview(clonedWebView)
            clonedWebView.pinToSuperview()

            clonedWebView.load(URLRequest(url: url))

            return previewViewController
        }
        return provider
    }

    func addTab(rURL: URL, isPrivate: Bool, currentTab: Tab) {
        var setAddTabAdSearchParam = false
        let adUrl = rURL.absoluteString
        if canTrackAds(tab: currentTab, adUrl: adUrl) {
            AdsTelemetryHelper.trackAdsClickedOnPage(providerName: currentTab.adsProviderName)
            currentTab.adsTelemetryUrlList.removeAll()
            currentTab.adsTelemetryRedirectUrlList.removeAll()
            currentTab.adsProviderName = ""

            // Set the tab search param from current tab considering we need
            // the values in order to cope with ad redirects
        } else if !currentTab.adsProviderName.isEmpty {
            setAddTabAdSearchParam = true
        }

        let tab = tabManager.addTab(
            URLRequest(url: rURL as URL),
            afterTab: currentTab,
            isPrivate: isPrivate
        )

        if setAddTabAdSearchParam {
            tab.adsProviderName = currentTab.adsProviderName
            tab.adsTelemetryUrlList = currentTab.adsTelemetryUrlList
            tab.adsTelemetryRedirectUrlList = currentTab.adsTelemetryRedirectUrlList
        }

        // We are showing the toast always now
        showToastBy(isPrivate: isPrivate, tab: tab)
    }

    func canTrackAds(tab: Tab, adUrl: String) -> Bool {
        return tab == self.tabManager.selectedTab &&
               !tab.adsTelemetryUrlList.isEmpty &&
               tab.adsTelemetryUrlList.contains(adUrl) &&
               !tab.adsProviderName.isEmpty
    }

    func showToastBy(isPrivate: Bool, tab: Tab) {
        var toastLabelText: String

        if isPrivate {
            toastLabelText = .ContextMenuButtonToastNewPrivateTabOpenedLabelText
        } else {
            toastLabelText = .ContextMenuButtonToastNewTabOpenedLabelText
        }

        let viewModel = ButtonToastViewModel(labelText: toastLabelText,
                                             buttonText: .ContextMenuButtonToastNewTabOpenedButtonText)
        let toast = ButtonToast(viewModel: viewModel,
                                theme: self.currentTheme(),
                                completion: { buttonPressed in
            if buttonPressed {
                self.tabManager.selectTab(tab)
                self.overlayManager.switchTab(shouldCancelLoading: true)
            }
        })
        show(toast: toast)
    }

    func createActions(isPrivate: Bool,
                       url: URL,
                       addTab: @escaping @MainActor (URL, Bool, Tab) -> Void,
                       title: String?,
                       image: URL?,
                       currentTab: Tab,
                       webView: WKWebView) -> [UIAction] {
        let actionBuilder = WebContextMenuActionsProvider(menuType: image != nil ? .image : .web)
        let isJavascriptScheme = (url.scheme?.caseInsensitiveCompare("javascript") == .orderedSame)

        if !isPrivate && !isJavascriptScheme {
            actionBuilder.addOpenInNewTab(url: url, currentTab: currentTab, addTab: addTab)
        }

        if !isJavascriptScheme {
            actionBuilder.addOpenInNewPrivateTab(url: url, currentTab: currentTab, addTab: addTab)
        }

        let isBookmarkedSite = profile.places
            .isBookmarked(url: url.absoluteString)
            .value
            .successValue ?? false
        if isBookmarkedSite {
            actionBuilder.addRemoveBookmarkLink(urlString: url.absoluteString,
                                                title: title,
                                                removeBookmark: self.removeBookmark)
        } else {
            actionBuilder.addBookmarkLink(url: url, title: title, addBookmark: self.addBookmark)
        }

        if !isJavascriptScheme {
            actionBuilder.addDownload(url: url, currentTab: currentTab, assignWebView: assignWebView)
        }

        actionBuilder.addCopyLink(url: url)

        actionBuilder.addShare(url: url,
                               tabManager: tabManager,
                               webView: webView,
                               view: view,
                               navigationHandler: navigationHandler,
                               contentContainer: contentContainer)

        if let url = image {
            actionBuilder.addSaveImage(url: url,
                                       getImageData: getImageData,
                                       writeToPhotoAlbum: writeToPhotoAlbum)

            actionBuilder.addCopyImage(url: url)

            actionBuilder.addCopyImageLink(url: url)
        }

        return actionBuilder.build()
    }

    func assignWebView(_ webView: WKWebView?) {
        pendingDownloadWebView = webView
    }

    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc
    func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        guard error != nil else { return }
        DispatchQueue.main.async {
            let accessDenied = UIAlertController(
                title: .PhotoLibraryFirefoxWouldLikeAccessTitle,
                message: .PhotoLibraryFirefoxWouldLikeAccessMessage,
                preferredStyle: .alert
            )
            let dismissAction = UIAlertAction(title: .CancelString, style: .default, handler: nil)
            accessDenied.addAction(dismissAction)
            let settingsAction = UIAlertAction(title: .OpenSettingsString, style: .default ) { _ in
                DefaultApplicationHelper().openSettings()
            }
            accessDenied.addAction(settingsAction)
            self.present(accessDenied, animated: true, completion: nil)
        }
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewController: WKNavigationDelegate {
    /// Called when the WKWebView's content process has gone away. If this happens for the currently selected tab
    /// then we immediately reload it.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if let tab = tabManager.selectedTab, tab.webView == webView {
            tab.consecutiveCrashes += 1

            // Only automatically attempt to reload the crashed
            // tab three times before giving up.
            if tab.consecutiveCrashes < 3 {
                logger.log("The webview has crashed, trying to reload.",
                           level: .warning,
                           category: .webview,
                           extra: ["Attempt number": "\(tab.consecutiveCrashes)"])

                tabsTelemetry.trackConsecutiveCrashTelemetry(attemptNumber: tab.consecutiveCrashes)

                webView.reload()
            } else {
                tab.consecutiveCrashes = 0
            }
        }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?) {
        guard let tab = tabManager[webView] else { return }

        if !tab.adsTelemetryUrlList.isEmpty,
           !tab.adsProviderName.isEmpty,
           let webUrl = webView.url {
            tab.adsTelemetryRedirectUrlList.append(webUrl)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        if tabManager.selectedTab?.webView !== webView { return }

        // Note the main frame JSContext (i.e. document, window) is not available yet.
        if let tab = tabManager[webView], let blocker = tab.contentBlocker {
            blocker.clearPageStats()
        }

        updateFindInPageVisibility(isVisible: false)
        updateZoomPageBarVisibility(visible: false)

        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let url = webView.url {
            guard !url.isReaderModeURL else { return }
            hideReaderModeBar(animated: false)
        }
    }

    // This is the place where we decide what to do with a new navigation action. There are a number of special schemes
    // and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
    // method.
    @MainActor
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        // prevent the App from opening universal links
        // https://stackoverflow.com/questions/38450586/prevent-universal-links-from-opening-in-wkwebview-uiwebview
        let allowPolicy = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow

        guard let url = navigationAction.request.url,
              let tab = tabManager[webView]
        else {
            decisionHandler(.cancel)
            return
        }

        if tab == tabManager.selectedTab,
           navigationAction.navigationType == .linkActivated,
           !tab.adsTelemetryUrlList.isEmpty {
            handleAdsTelemetryForNavigation(url: url, tab: tab)
        }

        if InternalURL.isValid(url: url) {
            if navigationAction.navigationType != .backForward,
               navigationAction.isInternalUnprivileged,
               !url.isReaderModeURL {
                logger.log("Denying unprivileged request: \(navigationAction.request)",
                           level: .warning,
                           category: .webview)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
            return
        }

        // Bugzilla #1979499
        if (url.scheme ?? "").lowercased() == "fido" {
            decisionHandler(.cancel)
            return
        }

        // First special case are some schemes that are about Calling. We prompt the user to confirm this action. This
        // gives us the exact same behaviour as Safari.
        if ["sms", "tel", "facetime", "facetime-audio"].contains(url.scheme) {
            handleSpecialSchemeNavigation(url: url)
            decisionHandler(.cancel)
            return
        }

        if url.scheme == "about" {
            decisionHandler(.allow)
            return
        }

        // Disabled due to https://bugzilla.mozilla.org/show_bug.cgi?id=1588928
//                if url.scheme == "javascript", navigationAction.request.isPrivileged {
//                    decisionHandler(.cancel)
//                    if let javaScriptString = url.absoluteString.replaceFirstOccurrence(
//                        of: "javascript:",
//                        with: ""
//                    ).removingPercentEncoding {
//                        webView.evaluateJavaScript(javaScriptString)
//                    }
//                    return
//                }

        if isStoreURL(url) {
            decisionHandler(.cancel)
            handleStoreURLNavigation(url: url)
            return
        }

        // Handles custom mailto URL schemes.
        if url.scheme == "mailto" {
            handleMailToNavigation(url: url)
            decisionHandler(.cancel)
            return
        }

        // Handle Universal link for Firefox wallpaper setting
        if isFirefoxUniversalWallpaperSetting(url) {
            showWallpaperSettings()
            decisionHandler(.cancel)
            return
        }

        // Handle MarketplaceKit URL
        if url.scheme == "marketplace-kit" {
            let isMainFrame = isMainFrameNavigation(navigationAction)
            let shouldAllowNavigation = shouldAllowMarketplaceKitNavigation(
                navigationType: navigationAction.navigationType,
                isMainFrame: isMainFrame
            )
            decisionHandler(shouldAllowNavigation ? .allow : .cancel)
            return
        }

        let navigationHandler = WebViewNavigationHandlerImplementation(decisionHandler: decisionHandler)
        if navigationHandler.shouldFilterDataScheme(url: url) {
            navigationHandler.filterDataScheme(url: url, navigationAction: navigationAction)
            return
        }

        // Handle keyboard shortcuts on link presses from webpage navigation (ex: Cmd + Tap on Link)
        if navigationAction.navigationType == .linkActivated, navigateLinkShortcutIfNeeded(url: url) {
            decisionHandler(.cancel)
            return
        }

        let shouldBlockExternalApps = profile.prefs.boolForKey(PrefsKeys.BlockOpeningExternalApps) ?? false

        // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView.
        // We always allow this. Additionally, data URIs are also handled just like normal web pages.
        if let scheme = url.scheme, ["http", "https", "blob", "file"].contains(scheme) {
            if navigationAction.targetFrame?.isMainFrame ?? false {
                tab.changedUserAgent = Tab.ChangeUserAgent.contains(url: url, isPrivate: tab.isPrivate)
            }

            pendingRequests[url.absoluteString] = navigationAction.request

            if tab.changedUserAgent {
                let platformSpecificUserAgent = UserAgent.oppositeUserAgent(domain: url.baseDomain ?? "")
                webView.customUserAgent = platformSpecificUserAgent
            } else {
                webView.customUserAgent = UserAgent.getUserAgent(domain: url.baseDomain ?? "")
            }

            if url.isFileURL,
               tab.shouldDownloadDocument(navigationAction.request),
               let sourceURL = tab.getTemporaryDocumentsSession()[url] {
                let request = URLRequest(url: sourceURL)
                let filename = url.lastPathComponent
                handlePDFDownloadRequest(request: request, tab: tab, filename: filename)
                decisionHandler(.cancel)
                return
            }

            // Blob URLs are downloaded via DownloadHelper.js where we check if we need to handle any special cases like:
            // - If the blob response has a .pkpass MIME type (FXIOS-11684)
            // - The <a> tag pressed has a "download" attribute, indicating a file download (FXIOS-11125)
            // Once inspected, if there are no special cases to handle, we will then navigate to the blob URL's location
            // via JS since we are cancelling the navigation here
            if scheme == "blob" && navigationAction.navigationType != .other {
                _ = DownloadContentScript.requestBlobDownload(url: url, tab: tab)
                decisionHandler(.cancel)
                return
            }

            let isGoogleDomain = url.host?.contains("google") ?? false
            let isPrivate = tab.isPrivate

            if isPrivate || isGoogleDomain || shouldBlockExternalApps {
                decisionHandler(allowPolicy)
                return
            }

            decisionHandler(.allow)
            return
        }

        if let scheme = url.scheme, !scheme.contains("firefox"), !shouldBlockExternalApps, !tab.isPrivate {
            handleCustomSchemeURLNavigation(url: url, navigationAction: navigationAction)
        }

        decisionHandler(.cancel)
    }

    private func handleAdsTelemetryForNavigation(url: URL, tab: Tab) {
        let adUrl = url.absoluteString
        if tab.adsTelemetryUrlList.contains(adUrl) {
            if !tab.adsProviderName.isEmpty {
                AdsTelemetryHelper.trackAdsClickedOnPage(providerName: tab.adsProviderName)
            }

            tab.adsTelemetryUrlList.removeAll()
            tab.adsTelemetryRedirectUrlList.removeAll()
            tab.adsProviderName = ""
        }
    }

    private func handleSpecialSchemeNavigation(url: URL) {
        if url.scheme == "sms" { // All the other types show a native prompt
            showExternalAlert(withText: .ExternalSmsLinkConfirmation) { _ in
                UIApplication.shared.open(url, options: [:])
            }
        } else {
            UIApplication.shared.open(url, options: [:])
        }
    }

    private func handleStoreURLNavigation(url: URL) {
        // Make sure to wait longer than delaySelectingNewPopupTab to ensure selectedTab is correct
        // Otherwise the AppStoreAlert is shown on the wrong tab
        // TODO: FXIOS-14796 - Investigate if we can remove the handleStoreURLNavigation delay
        let delaySelectingNewPopupTab: TimeInterval = 0.2
        let delay: DispatchTime = .now() + delaySelectingNewPopupTab
        DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
            self?.showAppStoreAlert { isOpened in
                if isOpened {
                    UIApplication.shared.open(url, options: [:])
                }
                // If a new window was opened for this URL, close it
                if let currentTab = self?.tabManager.selectedTab,
                   currentTab.historyList.count == 1,
                   self?.isStoreURL(currentTab.historyList[0]) ?? false {
                    self?.tabsPanelTelemetry.tabClosed(mode: currentTab.isPrivate ? .private : .normal)
                    self?.tabManager.removeTab(currentTab.tabUUID)
                }
            }
        }
    }

    private func handleMailToNavigation(url: URL) {
        showExternalAlert(withText: .ExternalMailLinkConfirmation) { _ in
            if let mailToMetadata = url.mailToMetadata(),
               let mailScheme = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption),
               mailScheme != "mailto" {
                self.mailtoLinkHandler.launchMailClientForScheme(
                    mailScheme,
                    metadata: mailToMetadata,
                    defaultMailtoURL: url
                )
            } else {
                UIApplication.shared.open(url, options: [:])
            }
        }
    }

    private func handleCustomSchemeURLNavigation(url: URL, navigationAction: WKNavigationAction) {
        // Try to open the custom scheme URL, if it doesn't work we show an error alert
        UIApplication.shared.open(url, options: [:]) { openedURL in
            // Do not show error message for JS navigated links or
            // redirect as it's not the result of a user action.
            if !openedURL, navigationAction.navigationType == .linkActivated {
                let alert = UIAlertController(
                    title: nil,
                    message: .ExternalInvalidLinkMessage,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: .OKString, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        guard let downloadHelper else {
            logger.log("Unable to access downloadHelper, it is nil", level: .warning, category: .webview)
            return
        }
        handleDownloadFiles(downloadHelper: downloadHelper)
    }

    @MainActor
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        let response = navigationResponse.response
        let responseURL = response.url

        tabManager[webView]?.mimeType = response.mimeType
        notificationCenter.post(name: .TabMimeTypeDidSet, withUserInfo: windowUUID.userInfo)

        var request: URLRequest?
        if let url = responseURL {
            request = pendingRequests.removeValue(forKey: url.absoluteString)
        }

        // We can only show this content in the web view if this web view is not pending
        // download via the context menu.
        let canShowInWebView = navigationResponse.canShowMIMEType && (webView != pendingDownloadWebView)
        let forceDownload = webView == pendingDownloadWebView
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

        if let mimeType = response.mimeType, OpenPassBookHelper.shouldOpenWithPassBook(
            mimeType: mimeType,
            forceDownload: forceDownload) {
            // Open our helper and nullifies the helper when done with it
            let passBookHelper = OpenPassBookHelper(presenter: self)
            await passBookHelper.open(response: response, cookieStore: cookieStore)

            // Cancel this response from the webview.
            return .cancel
        }

        // For USDZ / Reality 3D model files, we can cancel this response from the webView and open the QL previewer instead
        if OpenQLPreviewHelper.shouldOpenPreviewHelper(response: response, forceDownload: forceDownload),
           let tab = tabManager[webView],
           let request = request {
            let temporaryDocument = DefaultTemporaryDocument(preflightResponse: response, request: request)
            let url = await temporaryDocument.download()

            let previewHelper = OpenQLPreviewHelper(presenter: self, withTemporaryDocument: temporaryDocument)
            if previewHelper.canOpen(url: url) {
                // Open our helper and cancel this response from the webview
                tab.quickLookPreviewHelper = previewHelper
                previewHelper.open {
                    // Once the preview is closed, we can safely release this object and let the tempory document be deleted
                    tab.quickLookPreviewHelper = nil
                }
                return .cancel
            }

            // We don't have a temporary document, fallthrough
        }

        /// FIXME(FXIOS-11543): Before FXIOS-11256 all calendar type requests were forwarded to SFSafariViewController.
        /// This, however, led to the app crashing sometimes since SFSafariViewController only expects http(s) urls.
        /// In order to handle blob urls as well we need to use EventKitUI and parse the calendars ourselves.
        if let url = responseURL,
           ["http", "https"].contains(url.scheme),
           tabManager[webView]?.mimeType == MIMEType.Calendar {
            let alertMessage: String
            if let baseDomain = url.baseDomain {
                alertMessage = String(format: .Alerts.AddToCalendar.Body, baseDomain)
            } else {
                alertMessage = .Alerts.AddToCalendar.BodyDefault
            }

            let alert = UIAlertController(title: .Alerts.AddToCalendar.Title,
                                          message: alertMessage,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .Alerts.AddToCalendar.CancelButton, style: .default))
            alert.addAction(UIAlertAction(title: .Alerts.AddToCalendar.AddButton,
                                          style: .default,
                                          handler: { _ in
                let safariVC = SFSafariViewController(url: url)
                safariVC.modalPresentationStyle = .fullScreen
                self.present(safariVC, animated: true, completion: nil)
            }))
            present(alert, animated: true)
            return .cancel
        }

        // Check if this response should be downloaded
        if let downloadHelper = DownloadHelper(request: request, response: response, cookieStore: cookieStore),
            downloadHelper.shouldDownloadFile(canShowInWebView: canShowInWebView,
                                              forceDownload: forceDownload,
                                              isForMainFrame: navigationResponse.isForMainFrame) {
            /// FXIOS-12201: Need to hold reference to downloadHelper,
            /// so we can use this later in `webView(_:navigationResponse:didBecome:)`
            self.downloadHelper = downloadHelper
            return .download
        }

        // If the content type is not HTML, create a temporary document so it can be downloaded and
        // shared to external applications later. Otherwise, clear the old temporary document.
        // NOTE: This should only happen if the request/response came from the main frame, otherwise
        // we may end up overriding the "Share Page With..." action to share a temp file that is not
        // representative of the contents of the web view.
        if navigationResponse.isForMainFrame, let tab = tabManager[webView] {
            if response.mimeType == MIMEType.PDF, let request {
                if !tab.shouldDownloadDocument(request) {
                    return .allow
                }
                handlePDFDownloadRequest(request: request, tab: tab, filename: response.suggestedFilename)
                return .cancel
            }
            if response.mimeType != MIMEType.HTML, let request {
                tab.temporaryDocument = DefaultTemporaryDocument(preflightResponse: response, request: request)
            } else {
                tab.temporaryDocument = nil
            }

            tab.mimeType = response.mimeType
        }

        // If none of our helpers are responsible for handling this response,
        // just let the webview handle it as normal.
        return .allow
    }

    /// Handle a PDF download request by forwarding it to the provided `Tab`.
    func handlePDFDownloadRequest(request: URLRequest,
                                  tab: Tab,
                                  filename: String?) {
        let shouldUpdateUI = tab === tabManager.selectedTab

        if shouldUpdateUI {
            navigationHandler?.showDocumentLoading()
            scrollController.showToolbars(animated: false)
        }

        tab.getSessionCookies { [weak tab, weak self] cookies in
            let tempPDF = DefaultTemporaryDocument(
                filename: filename,
                request: request,
                mimeType: MIMEType.PDF,
                cookies: cookies
            )
            tempPDF.onDownloadProgressUpdate = { progress in
                self?.handleDownloadProgressUpdate(progress: progress, tab: tab)
            }
            tempPDF.onDownloadStarted = {
                self?.handleDownloadStarted(tab: tab, request: request)
            }
            tempPDF.onDownloadError = { error in
                self?.handleDownloadError(tab: tab, request: request, error: error)
            }
            tab?.enqueueDocument(tempPDF)
            if let url = request.url {
                self?.observeValue(
                    forKeyPath: KVOConstants.URL.rawValue,
                    of: tab?.webView,
                    change: [.newKey: url],
                    context: nil
                )
            }
        }
    }

    private func handleDownloadProgressUpdate(progress: Double, tab: Tab?) {
        observeValue(forKeyPath: KVOConstants.estimatedProgress.rawValue,
                     of: tab?.webView,
                     change: [.newKey: progress],
                     context: nil)
    }

    private func handleDownloadStarted(tab: Tab?, request: URLRequest) {
        observeValue(forKeyPath: KVOConstants.loading.rawValue,
                     of: tab?.webView,
                     change: [.newKey: true],
                     context: nil)
        if let url = request.url {
            documentLogger.registerDownloadStart(url: url)
        }
    }

    private func handleDownloadError(tab: Tab?, request: URLRequest, error: (any Error)?) {
        navigationHandler?.removeDocumentLoading()
        logger.log("Failed to download Document",
                   level: .warning,
                   category: .webview,
                   extra: [
                    "error": error?.localizedDescription ?? "",
                    "url": request.url?.absoluteString ?? "Unknown URL"])
        guard let error, let webView = tab?.webView else { return }
        showErrorPage(webView: webView, error: error)
    }

    private func showErrorPage(webView: WKWebView, error: Error) {
        guard let url = webView.url else { return }
        if isNativeErrorPageEnabled {
            let action = NativeErrorPageAction(networkError: error as NSError,
                                               windowUUID: windowUUID,
                                               actionType: NativeErrorPageActionType.receivedError
            )
            store.dispatch(action)
            webView.load(PrivilegedRequest(url: url) as URLRequest)
        } else {
            ErrorPageHelper(certStore: profile.certStore).loadPage(error as NSError,
                                                                   forUrl: url,
                                                                   inWebView: webView)
        }
    }

    func handleDownloadFiles(downloadHelper: DownloadHelper) {
        // Clear the pending download web view so that subsequent navigations from the same
        // web view don't invoke another download.
        pendingDownloadWebView = nil

        let downloadAction: @MainActor (HTTPDownload) -> Void = { [weak self] download in
            self?.downloadQueue.enqueue(download)
        }

        // Open our helper and cancel this response from the webview.
        if let downloadViewModel = downloadHelper.downloadViewModel(windowUUID: windowUUID,
                                                                    okAction: downloadAction) {
            presentSheetWith(viewModel: downloadViewModel, on: self, from: addressToolbarContainer)
        }
    }

    /// Tells the delegate that an error occurred during navigation.
    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation?,
        withError error: Error
    ) {
        logger.log("Error occurred during navigation.",
                   level: .warning,
                   category: .webview)

        TelemetryWrapper.shared.recordEvent(category: .information,
                                            method: .error,
                                            object: .webview,
                                            value: .webviewFail)

        webviewTelemetry.cancel()
    }

    /// Invoked when an error occurs while starting to load data for the main frame.
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation?,
        withError error: Error
    ) {
        logger.log("Error occurred during the early navigation process.",
                   level: .warning,
                   category: .webview)

        TelemetryWrapper.shared.recordEvent(category: .information,
                                            method: .error,
                                            object: .webview,
                                            value: .webviewFailProvisional)

        webviewTelemetry.cancel()

        // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
        // to open an external application and hand it over to UIApplication.openURL(). The result
        // will be that we switch to the external app, for example the app store, while keeping the
        // original web page in the tab instead of replacing it with an error page.
        let error = error as NSError
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        guard !checkIfWebContentProcessHasCrashed(webView, error: error as NSError) else { return }

        if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
            if let tab = tabManager[webView], tab === tabManager.selectedTab {
                let action = ToolbarAction(
                    url: tab.url?.displayURL,
                    isPrivate: tab.isPrivate,
                    canGoBack: tab.canGoBack,
                    canGoForward: tab.canGoForward,
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.urlDidChange
                )
                store.dispatch(action)
                let middlewareAction = ToolbarMiddlewareAction(
                    scrollOffset: scrollController.contentOffset,
                    windowUUID: windowUUID,
                    actionType: ToolbarMiddlewareActionType.urlDidChange
                )
                store.dispatch(middlewareAction)
            }
            return
        }

        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            guard var errorPageURLComponents = URLComponents(
                string: "\(InternalURL.baseUrl)/\(ErrorPageHandler.path)") else {
                ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
                return
            }

            errorPageURLComponents.queryItems = [
                URLQueryItem(
                    name: InternalURL.Param.url.rawValue,
                    value: url.absoluteString
                ),
                URLQueryItem(
                    name: "code",
                    value: String(
                        error.code
                    )
                )
            ]

            if let errorPageURL = errorPageURLComponents.url {
                /// Used for checking if current error code is for no internet connection
                let noInternetErrorCode = Int(
                    CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue
                )

                // Only handle No internet access because other cases show about:blank page
                if isNICErrorPageEnabled && error.code == noInternetErrorCode {
                    let action = NativeErrorPageAction(networkError: error,
                                                       windowUUID: windowUUID,
                                                       actionType: NativeErrorPageActionType.receivedError
                    )
                    store.dispatch(action)
                    webView.load(PrivilegedRequest(url: errorPageURL) as URLRequest)
                } else {
                    // We can fall into here for bad certificates (e.g. self-signed)
                    ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
                }
            } else {
                ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        respondTo challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let authenticationMethod = challenge.protectionSpace.authenticationMethod
        let defaultHandling: (URLSession.AuthChallengeDisposition, URLCredential?) = (.performDefaultHandling, nil)

        if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                return defaultHandling
            }

            return await handleServerTrust(
                serverTrust: serverTrust,
                challengeHost: challenge.protectionSpace.host,
                challengePort: challenge.protectionSpace.port
            )
        } else if authenticationMethod == NSURLAuthenticationMethodHTTPBasic
                    || authenticationMethod == NSURLAuthenticationMethodHTTPDigest
                    || authenticationMethod == NSURLAuthenticationMethodNTLM {
            guard let tab = tabManager[webView] else {
                return defaultHandling
            }

            // If this is a request to our local web server, use our private credentials.
            if challenge.protectionSpace.host == "localhost",
                challenge.protectionSpace.port == Int(WebServer.sharedInstance.server.port) {
                return (.useCredential, WebServer.sharedInstance.credentials)
            }

            let loginsHelper = tab.getContentScript(name: LoginsHelper.name()) as? LoginsHelper

            do {
                // Show authentication alert forms
                let loginEntry = try await Authenticator.handleAuthRequestAsync(
                    self,
                    challenge: challenge,
                    loginsHelper: loginsHelper,
                )

                return (.useCredential, loginEntry.credentials)
            } catch {
                // For example, an error is thrown when the user taps "Cancel" on the authentication prompt
                return (.rejectProtectionSpace, nil)
            }
        } else {
            return defaultHandling
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        guard let tab = tabManager[webView] else { return }

        // The main frame JSContext is available, and DOM parsing has begun.
        // Do not execute JS at this point that requires running prior to DOM parsing.
        if let tpHelper = tab.contentBlocker, !tpHelper.isEnabled {
            let js = "window.__firefox__.TrackingProtectionStats.setEnabled(false, \(UserScriptManager.appIdToken))"
            webView.evaluateJavascriptInDefaultContentWorld(js)
        }

        searchTelemetry.trackTabAndTopSiteSAP(tab, webView: webView)
        webviewTelemetry.start()
        tab.url = webView.url

        if !tab.adsTelemetryRedirectUrlList.isEmpty,
           !tab.adsProviderName.isEmpty,
           !tab.adsTelemetryUrlList.isEmpty,
           !tab.adsProviderName.isEmpty,
           let startingRedirectHost = tab.startingSearchUrlWithAds?.host,
           let lastRedirectHost = tab.adsTelemetryRedirectUrlList.last?.host,
           lastRedirectHost != startingRedirectHost {
            AdsTelemetryHelper.trackAdsClickedOnPage(providerName: tab.adsProviderName)
            tab.adsTelemetryUrlList.removeAll()
            tab.adsTelemetryRedirectUrlList.removeAll()
            tab.adsProviderName = ""
        }

        // When tab url changes after web content starts loading on the page
        // We notify the content blocker change so that content blocker status
        // can be correctly shown on beside the URL bar
        // TODO: content blocking hasn't really changed, can we improve code clarity here? [FXIOS-10091]
        tab.contentBlocker?.notifyContentBlockingChanged()

        if let scrollController = scrollController as? LegacyTabScrollProvider {
            scrollController.resetZoomState()
        }

        if tabManager.selectedTab === tab {
            updateUIForReaderHomeStateForTab(tab, focusUrlBar: true)
            // Because we are not calling updateInContentHomePanel in updateUIForReaderHomeStateForTab we need to
            // call it here so that we can load the webpage from tapping a link on the homepage
            // TODO: FXIOS-14355 Remove this call in favor of newState update
            if isToolbarTranslucencyRefactorEnabled {
                updateInContentHomePanel(tab.url, focusUrlBar: true)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        webviewTelemetry.stop()

        if let url = webView.url, InternalURL(url) == nil {
            if let title = webView.title,
               tabManager.selectedTab?.webView == webView {
                tabManager.selectedTab?.lastTitle = title
                tabManager.notifyCurrentTabDidFinishLoading()
            }

            tabManager.commitChanges()
        }

        scrollController.configureRefreshControl()
        navigationHandler?.removeDocumentLoading()

        if let tab = tabManager[webView] {
            if tab == tabManager.selectedTab {
                screenshotHelper.takeScreenshot(
                    tab,
                    windowUUID: windowUUID,
                    screenshotBounds: CGRect(
                        x: contentContainer.frame.origin.x,
                        y: -contentContainer.frame.origin.y,
                        width: view.frame.width,
                        height: view.frame.height
                    )
                )
            }
            navigateInTab(tab: tab, to: navigation, webViewStatus: .finishedNavigation)

            // If this tab had previously crashed, wait 5 seconds before resetting
            // the consecutive crash counter. This allows a successful webpage load
            // without a crash to reset the consecutive crash counter in the event
            // that the tab begins crashing again in the future.
            if tab.consecutiveCrashes > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                    if tab.consecutiveCrashes > 0 {
                        tab.consecutiveCrashes = 0
                    }
                }
            }
        }
    }
}

// MARK: - Private
private extension BrowserViewController {
    // Handle Universal link for Firefox wallpaper setting
    func isFirefoxUniversalWallpaperSetting(_ url: URL) -> Bool {
        guard let scheme = url.scheme,
              [URL.mozPublicScheme, URL.mozInternalScheme].contains(scheme)
        else { return false }

        let deeplinkUrl = "\(scheme)://deep-link?url=/settings/wallpaper"
        if url.absoluteString == deeplinkUrl { return true }

        return false
    }

    // Handle MarketPlaceKitNavigation
    // Allow only explicit user tap on a top level link
    private func shouldAllowMarketplaceKitNavigation(navigationType: WKNavigationType,
                                                     isMainFrame: Bool) -> Bool {
        return navigationType == .linkActivated && isMainFrame
    }

    // Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
    // used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
    // them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
    // leave a 'Back to Safari' button in the status bar, which we do not want.
    func isStoreURL(_ url: URL) -> Bool {
      let isAppStoreScheme = ["itms-apps", "itms-appss"].contains(url.scheme)
      if isAppStoreScheme {
        return true
      }

      let isHttpScheme = ["http", "https"].contains(url.scheme)
      let isAppStoreHost = ["itunes.apple.com", "apps.apple.com", "appsto.re"].contains(url.host)
      return isHttpScheme && isAppStoreHost
    }

    // Use for sms and mailto, which do not show a confirmation before opening.
    func showExternalAlert(withText text: String,
                           completion: @escaping @MainActor (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: text,
                                      preferredStyle: .alert)

        let okOption = UIAlertAction(
            title: .ExternalOpenMessage,
            style: .default,
            handler: completion
        )

        let cancelOption = UIAlertAction(
            title: .CancelString,
            style: .cancel
        )

        alert.addAction(okOption)
        alert.addAction(cancelOption)

        present(alert, animated: true, completion: nil)
    }

    func showAppStoreAlert(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: .ExternalLinkAppStoreConfirmationTitle,
                                      preferredStyle: .alert)

        let okOption = UIAlertAction(
            title: .AppStoreString,
            style: .default,
            handler: { _ in completion(true) }
        )

        let cancelOption = UIAlertAction(
            title: .NotNowString,
            style: .cancel,
            handler: { _ in completion(false) }
        )

        alert.addAction(okOption)
        alert.addAction(cancelOption)

        present(alert, animated: true, completion: nil)
    }

    func shouldRequestBeOpenedAsPopup(_ request: URLRequest) -> Bool {
        // Treat `window.open("")` the same as `window.open("about:blank")`.
        if request.url?.absoluteString.isEmpty ?? false {
            return true
        }

        /// List of schemes that are allowed to be opened in new tabs.
        let schemesAllowedToBeOpenedAsPopups = ["http", "https", "javascript", "data", "about"]

        if let scheme = request.url?.scheme?.lowercased(), schemesAllowedToBeOpenedAsPopups.contains(scheme) {
            return true
        }

        return false
    }

    // The WKNavigationAction request for Paypal popUp is empty which causes that we open a blank page in
    // createWebViewWith. We will show Paypal popUp in page like mobile devices using the mobile User Agent
    // so we will block the creation of a new Webview with this check
    func isPayPalPopUp(_ navigationAction: WKNavigationAction) -> Bool {
        let domain = navigationAction.sourceFrame.request.url?.baseDomain ?? ""
        return ["paypal.com", "shopify.com"].contains(domain)
    }

    func shouldDisplayJSAlertForWebView(_ webView: WKWebView) -> Bool {
        guard let tab = tabManager.selectedTab else { return false }
        // Only display a JS Alert if we are selected and there isn't anything being shown
        return (tab.webView === webView && self.presentedViewController == nil)
    }

    func jsAlertExceedsSpamLimits(_ webView: WKWebView) -> Bool {
        guard let tab = tabManager.selectedTab, tab.webView === webView else { return false }
        let canShow = tab.popupThrottler.canShowAlert(type: .alert)
        if canShow { tab.popupThrottler.willShowAlert(type: .alert) }
        return !canShow
    }

     func checkIfWebContentProcessHasCrashed(_ webView: WKWebView, error: NSError) -> Bool {
        if error.code == WKError.webContentProcessTerminated.rawValue && error.domain == "WebKitErrorDomain" {
            logger.log("WebContent process has crashed. Trying to reload to restart it.",
                       level: .warning,
                       category: .webview)
            webView.reload()
            return true
        }

        return false
    }

    /// Handles a certificate challenge. Checks if the certificate has previously been accepted by the user. If not,
    /// perform the default handling.
    /// Note: This path can be tested with incorrect certificates on badssl.com.
    func handleServerTrust(
        serverTrust: sending SecTrust,
        challengeHost: String,
        challengePort: Int,
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let origin = "\(challengeHost):\(challengePort)"

        /// FXIOS-8697: Do not call `SecTrustCopyCertificateChain` on the main thread, as it may perform network operations
        /// to evaluate the trust (via SecTrustEvaluateIfNecessary), which can block the current thread.
        let backgroundTask: Task<(URLSession.AuthChallengeDisposition, URLCredential?), Never>
        = Task.detached(priority: .userInitiated) {
            guard let certChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
                  let firstCert = certChain.first,
                  self.profile.certStore.containsCertificate(firstCert, forOrigin: origin) else {
                return (.performDefaultHandling, nil)
            }

            // Note: Temporary credentials are added when a user has tapped the "visit anyway" button on one of our error
            // pages (i.e. "This Connection is Untrusted"). The CertStore credentials are not persisted between runs.
            let credential = URLCredential(trust: serverTrust)
            return (.useCredential, credential)
        }

        return await backgroundTask.value
    }
}

extension WKNavigationAction {
    /// Allow local requests only if the request is privileged.
    var isInternalUnprivileged: Bool {
        guard let url = request.url else { return true }

        if let url = InternalURL(url) {
            return !url.isAuthorized
        } else {
            return false
        }
    }

    var canOpenExternalApp: Bool {
        guard let urlShortDomain = request.url?.shortDomain else { return false }

        if let url = URL(string: "\(urlShortDomain)://"), UIApplication.shared.canOpenURL(url) {
            return true
        }

        return false
    }
}
