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

// MARK: - WKUIDelegate
extension BrowserViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let parentTab = tabManager[webView] else { return nil }
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
        let navigationUrlString = navigationUrl?.absoluteString ?? ""

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

        if navigationUrl == nil || navigationUrlString.isEmpty {
            newTab.url = URL(string: "about:blank")
        }

        return newTab.webView
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let messageAlert = MessageAlert(message: message,
                                        frame: frame,
                                        completionHandler: completionHandler)

        if shouldDisplayJSAlertForWebView(webView) {
            logger.log("JavaScript alert panel will be presented.", level: .info, category: .webview)

            let alertController = messageAlert.alertController()
            alertController.delegate = self
            present(alertController, animated: true)
        } else if let promptingTab = tabManager[webView] {
            logger.log("JavaScript alert panel is queued.", level: .info, category: .webview)
            promptingTab.queueJavascriptAlertPrompt(messageAlert)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let confirmAlert = ConfirmPanelAlert(message: message, frame: frame) { confirm in
            self.logger.log("JavaScript confirm panel was completed with result: \(confirm)", level: .info, category: .webview)
            completionHandler(confirm)
        }

        if shouldDisplayJSAlertForWebView(webView) {
            self.logger.log("JavaScript confirm panel will be presented.", level: .info, category: .webview)

            let alertController = confirmAlert.alertController()
            alertController.delegate = self
            present(alertController, animated: true)
        } else if let promptingTab = tabManager[webView] {
            logger.log("JavaScript confirm panel is queued.", level: .info, category: .webview)
            promptingTab.queueJavascriptAlertPrompt(confirmAlert)
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let textInputAlert = TextInputAlert(message: prompt, frame: frame, defaultText: defaultText) { input in
            self.logger.log("JavaScript text input panel was completed with input", level: .info, category: .webview)
            completionHandler(input)
        }

        if shouldDisplayJSAlertForWebView(webView) {
            logger.log("JavaScript text input panel will be presented.", level: .info, category: .webview)

            let alertController = textInputAlert.alertController()
            alertController.delegate = self
            present(alertController, animated: true)
        } else if let promptingTab = tabManager[webView] {
            logger.log("JavaScript text input panel is queued.", level: .info, category: .webview)
            promptingTab.queueJavascriptAlertPrompt(textInputAlert)
        }
    }

    func webViewDidClose(_ webView: WKWebView) {
        Task {
            if let tab = tabManager[webView] {
                // Need to wait here in case we're waiting for a pending `window.open()`.
                try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 100)
                await tabManager.removeTab(tab.tabUUID)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping (UIContextMenuConfiguration?) -> Void
    ) {
        guard let url = elementInfo.linkURL,
              let currentTab = tabManager.selectedTab,
              let contextHelper = currentTab.getContentScript(
                name: ContextMenuHelper.name()
              ) as? ContextMenuHelper,
              let elements = contextHelper.elements
        else { return }
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

    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // If the tab isn't the selected one or we're on the homepage, do not show the media capture prompt
        guard tabManager.selectedTab?.webView === webView, !contentContainer.hasAnyHomepage else {
            decisionHandler(.deny)
            return
        }

        decisionHandler(.prompt)
    }

    // MARK: - Helpers
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
            return UIMenu(title: url.absoluteString, children: actions)
        }
    }

    private func contextMenuPreviewProvider(for url: URL, webView: WKWebView) -> UIContextMenuContentPreviewProvider? {
        let provider: UIContextMenuContentPreviewProvider = {
            guard self.profile.prefs.boolForKey(PrefsKeys.ContextMenuShowLinkPreviews) ?? true else { return nil }

            let previewViewController = UIViewController()
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

        self.recordObservationForSearchTermGroups(currentTab: currentTab, addedTab: tab)

        // We are showing the toast always now
        showToastBy(isPrivate: isPrivate, tab: tab)
    }

    func canTrackAds(tab: Tab, adUrl: String) -> Bool {
        return tab == self.tabManager.selectedTab &&
               !tab.adsTelemetryUrlList.isEmpty &&
               tab.adsTelemetryUrlList.contains(adUrl) &&
               !tab.adsProviderName.isEmpty
    }

    func recordObservationForSearchTermGroups(currentTab: Tab, addedTab: Tab) {
        let searchTerm = currentTab.metadataManager?.tabGroupData.tabAssociatedSearchTerm ?? ""
        let searchUrl = currentTab.metadataManager?.tabGroupData.tabAssociatedSearchUrl ?? ""
        if !searchTerm.isEmpty,
           !searchUrl.isEmpty {
            let searchData = LegacyTabGroupData(searchTerm: searchTerm,
                                                searchUrl: searchUrl,
                                                nextReferralUrl: addedTab.url?.absoluteString ?? "")
            addedTab.metadataManager?.updateTimerAndObserving(
                state: .openInNewTab,
                searchData: searchData,
                isPrivate: addedTab.isPrivate
            )
        }
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
                       addTab: @escaping (URL, Bool, Tab) -> Void,
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

        updateFindInPageVisibility(isVisible: false)

        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let url = webView.url {
            guard !url.isReaderModeURL else { return }
            // FXIOS-10239: Reader mode icon shifts when toolbar refactor is enabled
            if !isToolbarRefactorEnabled {
                updateReaderModeState(for: tabManager.selectedTab, readerModeState: .unavailable)
            }
            hideReaderModeBar(animated: false)
        }
    }

    // This is the place where we decide what to do with a new navigation action. There are a number of special schemes
    // and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
    // method.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let tab = tabManager[webView]
        else {
            decisionHandler(.cancel)
            return
        }
        updateZoomPageBarVisibility(visible: false)
        if tab == tabManager.selectedTab,
           navigationAction.navigationType == .linkActivated,
           !tab.adsTelemetryUrlList.isEmpty {
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

        // First special case are some schemes that are about Calling. We prompt the user to confirm this action. This
        // gives us the exact same behaviour as Safari.
        if ["sms", "tel", "facetime", "facetime-audio"].contains(url.scheme) {
            if url.scheme == "sms" { // All the other types show a native prompt
                showExternalAlert(withText: .ExternalSmsLinkConfirmation) { _ in
                    UIApplication.shared.open(url, options: [:])
                }
            } else {
                UIApplication.shared.open(url, options: [:])
            }

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

            // Make sure to wait longer than delaySelectingNewPopupTab to ensure selectedTab is correct
            // Otherwise the AppStoreAlert is shown on the wrong tab
            let delay: DispatchTime = .now() + tabManager.delaySelectingNewPopupTab + 0.1
            DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
                self?.showAppStoreAlert { isOpened in
                    if isOpened {
                        UIApplication.shared.open(url, options: [:])
                    }
                    // If a new window was opened for this URL, close it
                    if let currentTab = self?.tabManager.selectedTab,
                       currentTab.historyList.count == 1,
                       self?.isStoreURL(currentTab.historyList[0]) ?? false {
                        self?.tabManager.removeTabWithCompletion(tab.tabUUID, completion: nil)
                    }
                }
            }
            return
        }

        // Handles custom mailto URL schemes.
        if url.scheme == "mailto" {
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

            decisionHandler(.cancel)
            return
        }

        // Handle Universal link for Firefox wallpaper setting
        if isFirefoxUniversalWallpaperSetting(url) {
            showWallpaperSettings()
            decisionHandler(.cancel)
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

            if navigationAction.navigationType == .linkActivated && url != webView.url {
                if profile.prefs.boolForKey(PrefsKeys.BlockOpeningExternalApps) ?? false {
                    decisionHandler(.cancel)
                    webView.load(navigationAction.request)
                    return
                }
            }

            decisionHandler(.allow)
            return
        }

        if !(url.scheme?.contains("firefox") ?? true) {
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

        decisionHandler(.cancel)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
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
            passBookHelper = OpenPassBookHelper(presenter: self)
            // Open our helper and nullifies the helper when done with it
            passBookHelper?.open(response: response, cookieStore: cookieStore, completion: {
                self.passBookHelper = nil
            })

            // Cancel this response from the webview.
            decisionHandler(.cancel)
            return
        }

        // For USDZ / Reality 3D model files, we can cancel this response from the webView and open the QL previewer instead
        if OpenQLPreviewHelper.shouldOpenPreviewHelper(response: response, forceDownload: forceDownload),
           let tab = tabManager[webView],
           let request = request {
            // Certain files are too large to download before the preview presents, so block until we have something to show
            let group = DispatchGroup()
            var url: URL?
            group.enter()
            let temporaryDocument = DefaultTemporaryDocument(preflightResponse: response, request: request)
            temporaryDocument.download { docURL in
                url = docURL
                group.leave()
            }
            _ = group.wait(timeout: .distantFuture)

            let previewHelper = OpenQLPreviewHelper(presenter: self, withTemporaryDocument: temporaryDocument)
            if previewHelper.canOpen(url: url) {
                // Open our helper and cancel this response from the webview
                tab.quickLookPreviewHelper = previewHelper
                previewHelper.open {
                    // Once the preview is closed, we can safely release this object and let the tempory document be deleted
                    tab.quickLookPreviewHelper = nil
                }
                decisionHandler(.cancel)
                return
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
            decisionHandler(.cancel)
            return
        }

        // Check if this response should be downloaded
        if let downloadHelper = DownloadHelper(request: request, response: response, cookieStore: cookieStore),
            downloadHelper.shouldDownloadFile(canShowInWebView: canShowInWebView,
                                              forceDownload: forceDownload,
                                              isForMainFrame: navigationResponse.isForMainFrame) {
            handleDownloadFiles(downloadHelper: downloadHelper)
            decisionHandler(.cancel)
            return
        }

        // If the content type is not HTML, create a temporary document so it can be downloaded and
        // shared to external applications later. Otherwise, clear the old temporary document.
        // NOTE: This should only happen if the request/response came from the main frame, otherwise
        // we may end up overriding the "Share Page With..." action to share a temp file that is not
        // representative of the contents of the web view.
        if navigationResponse.isForMainFrame, let tab = tabManager[webView] {
            if isPDFRefactorEnabled, response.mimeType == MIMEType.PDF, let request {
                if !tab.canLoadDocumentRequest(request) {
                    decisionHandler(.allow)
                    return
                }
                handlePDFResponse(webView, tab: tab, response: response, request: request)
                decisionHandler(.cancel)
                return
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
        decisionHandler(.allow)
    }

    func handlePDFResponse(_ webView: WKWebView,
                           tab: Tab,
                           response: URLResponse,
                           request: URLRequest) {
        navigationHandler?.showDocumentLoading()
        scrollController.showToolbars(animated: false)

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { [weak tab, weak webView, weak self] cookies in
            let tempPDF = DefaultTemporaryDocument(
                filename: response.suggestedFilename,
                request: request,
                mimeType: MIMEType.PDF,
                cookies: cookies
            )
            tempPDF.onDownloadProgressUpdate = { progress in
                self?.observeValue(forKeyPath: KVOConstants.estimatedProgress.rawValue,
                                   of: webView,
                                   change: [.newKey: progress],
                                   context: nil)
            }
            tempPDF.onDownloadStarted = {
                self?.observeValue(forKeyPath: KVOConstants.loading.rawValue,
                                   of: webView,
                                   change: [.newKey: true],
                                   context: nil)
            }
            tempPDF.onDownloadError = { error in
                self?.navigationHandler?.removeDocumentLoading()
                guard let error, let webView else { return }
                self?.showErrorPage(webView: webView, error: error)
            }
            tab?.enqueueDocument(tempPDF)
            if let url = request.url {
                self?.observeValue(
                    forKeyPath: KVOConstants.URL.rawValue,
                    of: webView,
                    change: [.newKey: url],
                    context: nil
                )
            }
        }
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

        let downloadAction: (HTTPDownload) -> Void = { [weak self] download in
            self?.downloadQueue.enqueue(download)
        }

        // Open our helper and cancel this response from the webview.
        if let downloadViewModel = downloadHelper.downloadViewModel(windowUUID: windowUUID,
                                                                    okAction: downloadAction) {
            presentSheetWith(viewModel: downloadViewModel, on: self, from: urlBarView)
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
                if isToolbarRefactorEnabled {
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
                } else {
                    legacyUrlBar?.currentURL = tab.url?.displayURL
                }
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

                if isNativeErrorPageEnabled {
                    guard isNICErrorPageEnabled && error.code == noInternetErrorCode else { return }
                    let action = NativeErrorPageAction(networkError: error,
                                                       windowUUID: windowUUID,
                                                       actionType: NativeErrorPageActionType.receivedError
                    )
                    store.dispatch(action)
                    webView.load(PrivilegedRequest(url: errorPageURL) as URLRequest)
                } else {
                    ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
                }
            } else {
                ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod != NSURLAuthenticationMethodServerTrust else {
            handleServerTrust(challenge: challenge, completionHandler: completionHandler)
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
              let tab = tabManager[webView]
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // If this is a request to our local web server, use our private credentials.
        if challenge.protectionSpace.host == "localhost" &&
            challenge.protectionSpace.port == Int(WebServer.sharedInstance.server.port) {
            completionHandler(.useCredential, WebServer.sharedInstance.credentials)
            return
        }

        let loginsHelper = tab.getContentScript(name: LoginsHelper.name()) as? LoginsHelper
        Authenticator.handleAuthRequest(
            self,
            challenge: challenge,
            loginsHelper: loginsHelper
        ) { res in
            DispatchQueue.main.async {
                switch res {
                case .success(let credentials):
                    completionHandler(.useCredential, credentials.credentials)
                case .failure:
                    completionHandler(.rejectProtectionSpace, nil)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        guard let tab = tabManager[webView],
              let metadataManager = tab.metadataManager
        else { return }

        searchTelemetry.trackTabAndTopSiteSAP(tab, webView: webView)
        webviewTelemetry.start()
        tab.url = webView.url

        // Only update search term data with valid search term data
        if metadataManager.shouldUpdateSearchTermData(webViewUrl: webView.url?.absoluteString) {
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

            updateObservationReferral(
                metadataManager: metadataManager,
                url: webView.url?.absoluteString,
                isPrivate: tab.isPrivate
            )
        }

        // When tab url changes after web content starts loading on the page
        // We notify the content blocker change so that content blocker status
        // can be correctly shown on beside the URL bar

        // TODO: content blocking hasn't really changed, can we improve code clarity here? [FXIOS-10091]
        tab.contentBlocker?.notifyContentBlockingChanged()

        self.scrollController.resetZoomState()

        if tabManager.selectedTab === tab {
            updateUIForReaderHomeStateForTab(tab, focusUrlBar: true)
            updateFakespot(tab: tab, isReload: true)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        webviewTelemetry.stop()
        if isPDFRefactorEnabled {
            scrollController.configureRefreshControl()
            navigationHandler?.removeDocumentLoading()
        }
        if let tab = tabManager[webView],
           let metadataManager = tab.metadataManager {
            navigateInTab(tab: tab, to: navigation, webViewStatus: .finishedNavigation)

            // Only update search term data with valid search term data
            if metadataManager.shouldUpdateSearchTermData(webViewUrl: webView.url?.absoluteString) {
                updateObservationReferral(
                    metadataManager: metadataManager,
                    url: webView.url?.absoluteString,
                    isPrivate: tab.isPrivate
                )
            } else if !tab.isFxHomeTab {
                let searchData = LegacyTabGroupData(searchTerm: metadataManager.tabGroupData.tabAssociatedSearchTerm,
                                                    searchUrl: webView.url?.absoluteString ?? "",
                                                    nextReferralUrl: "")
                metadataManager.updateTimerAndObserving(state: .openURLOnly,
                                                        searchData: searchData,
                                                        tabTitle: webView.title,
                                                        isPrivate: tab.isPrivate)
            }

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
    func showExternalAlert(withText text: String, completion: @escaping (UIAlertAction) -> Void) {
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
            style: .cancel,
            handler: nil
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
        return navigationAction.sourceFrame.request.url?.baseDomain == "paypal.com"
    }

    func shouldDisplayJSAlertForWebView(_ webView: WKWebView) -> Bool {
        // Only display a JS Alert if we are selected and there isn't anything being shown
        return ((tabManager.selectedTab == nil ? false : tabManager.selectedTab!.webView === webView))
            && (self.presentedViewController == nil)
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

    func handleServerTrust(challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            // If this is a certificate challenge, see if the certificate has previously been
            // accepted by the user.
            let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"

            guard let trust = challenge.protectionSpace.serverTrust,
                  let cert = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
                  self.profile.certStore.containsCertificate(cert[0], forOrigin: origin)
            else {
                DispatchQueue.main.async {
                    completionHandler(.performDefaultHandling, nil)
                }
                return
            }

            DispatchQueue.main.async {
                completionHandler(.useCredential, URLCredential(trust: trust))
            }
        }
    }

    func updateObservationReferral(metadataManager: LegacyTabMetadataManager, url: String?, isPrivate: Bool) {
        let searchData = LegacyTabGroupData(searchTerm: metadataManager.tabGroupData.tabAssociatedSearchTerm,
                                            searchUrl: metadataManager.tabGroupData.tabAssociatedSearchUrl,
                                            nextReferralUrl: url ?? "")
        metadataManager.updateTimerAndObserving(
            state: .tabNavigatedToDifferentUrl,
            searchData: searchData,
            isPrivate: isPrivate)
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
