/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import Photos

private let log = Logger.browserLogger

/// List of schemes that are allowed to be opened in new tabs.
private let schemesAllowedToBeOpenedAsPopups = ["http", "https", "javascript", "data", "about"]

extension BrowserViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let parentTab = tabManager[webView] else { return nil }

        guard !navigationAction.isInternalUnprivileged, shouldRequestBeOpenedAsPopup(navigationAction.request) else {
            print("Denying popup from request: \(navigationAction.request)")
            return nil
        }

        if let currentTab = tabManager.selectedTab {
            screenshotHelper.takeScreenshot(currentTab)
        }

        guard let bvc = parentTab.browserViewController else { return nil }

        // If the page uses `window.open()` or `[target="_blank"]`, open the page in a new tab.
        // IMPORTANT!!: WebKit will perform the `URLRequest` automatically!! Attempting to do
        // the request here manually leads to incorrect results!!
        let newTab = tabManager.addPopupForParentTab(bvc: bvc, parentTab: parentTab, configuration: configuration)

        return newTab.webView
    }

    fileprivate func shouldRequestBeOpenedAsPopup(_ request: URLRequest) -> Bool {
        // Treat `window.open("")` the same as `window.open("about:blank")`.
        if request.url?.absoluteString.isEmpty ?? false {
            return true
        }

        if let scheme = request.url?.scheme?.lowercased(), schemesAllowedToBeOpenedAsPopups.contains(scheme) {
            return true
        }

        return false
    }

    fileprivate func shouldDisplayJSAlertForWebView(_ webView: WKWebView) -> Bool {
        // Only display a JS Alert if we are selected and there isn't anything being shown
        return ((tabManager.selectedTab == nil ? false : tabManager.selectedTab!.webView == webView)) && (self.presentedViewController == nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let messageAlert = MessageAlert(message: message, frame: frame, completionHandler: completionHandler)
        if shouldDisplayJSAlertForWebView(webView) {
            present(messageAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(messageAlert)
        } else {
            // This should never happen since an alert needs to come from a web view but just in case call the handler
            // since not calling it will result in a runtime exception.
            completionHandler()
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let confirmAlert = ConfirmPanelAlert(message: message, frame: frame, completionHandler: completionHandler)
        if shouldDisplayJSAlertForWebView(webView) {
            present(confirmAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(confirmAlert)
        } else {
            completionHandler(false)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let textInputAlert = TextInputAlert(message: prompt, frame: frame, completionHandler: completionHandler, defaultText: defaultText)
        if shouldDisplayJSAlertForWebView(webView) {
            present(textInputAlert.alertController(), animated: true, completion: nil)
        } else if let promptingTab = tabManager[webView] {
            promptingTab.queueJavascriptAlertPrompt(textInputAlert)
        } else {
            completionHandler(nil)
        }
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let tab = tabManager[webView] {
            // Need to wait here in case we're waiting for a pending `window.open()`.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.tabManager.removeTabAndUpdateSelectedIndex(tab)
            }
        }
    }

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        completionHandler(UIContextMenuConfiguration(identifier: nil, previewProvider: {
            guard let url = elementInfo.linkURL, self.profile.prefs.boolForKey(PrefsKeys.ContextMenuShowLinkPreviews) ?? true else { return nil }
            let previewViewController = UIViewController()
            previewViewController.view.isUserInteractionEnabled = false
            let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)

            previewViewController.view.addSubview(clonedWebView)
            clonedWebView.snp.makeConstraints { make in
                make.edges.equalTo(previewViewController.view)
            }

            clonedWebView.load(URLRequest(url: url))

            return previewViewController
        }, actionProvider: { (suggested) -> UIMenu? in
            guard let url = elementInfo.linkURL, let currentTab = self.tabManager.selectedTab,
                let contextHelper = currentTab.getContentScript(name: ContextMenuHelper.name()) as? ContextMenuHelper,
                let elements = contextHelper.elements else { return nil }
            let isPrivate = currentTab.isPrivate
            let addTab = { (rURL: URL, isPrivate: Bool) in
                let tab = self.tabManager.addTab(URLRequest(url: rURL as URL), afterTab: currentTab, isPrivate: isPrivate)
                LeanPlumClient.shared.track(event: .openedNewTab, withParameters: ["Source": "Long Press Context Menu"])
                guard !self.topTabsVisible else {
                    return
                }
                var toastLabelText: String
                
                if isPrivate {
                    toastLabelText = Strings.ContextMenuButtonToastNewPrivateTabOpenedLabelText
                } else {
                    toastLabelText = Strings.ContextMenuButtonToastNewTabOpenedLabelText
                }
                // We're not showing the top tabs; show a toast to quick switch to the fresh new tab.
                let toast = ButtonToast(labelText: toastLabelText, buttonText: Strings.ContextMenuButtonToastNewTabOpenedButtonText, completion: { buttonPressed in
                    if buttonPressed {
                        self.tabManager.selectTab(tab)
                    }
                })
                self.show(toast: toast)
            }

            let getImageData = { (_ url: URL, success: @escaping (Data) -> Void) in
                makeURLSession(userAgent: UserAgent.fxaUserAgent, configuration: URLSessionConfiguration.default).dataTask(with: url) { (data, response, error) in
                    if let _ = validatedHTTPResponse(response, statusCode: 200..<300), let data = data {
                        success(data)
                    }
                }.resume()
            }

            var actions = [UIAction]()

            if !isPrivate {
                actions.append(UIAction(title: Strings.ContextMenuOpenInNewTab, image: UIImage.templateImageNamed("menu-NewTab"), identifier: UIAction.Identifier(rawValue: "linkContextMenu.openInNewTab")) {_ in
                    addTab(url, false)
                })
            }

            actions.append(UIAction(title: Strings.ContextMenuOpenInNewPrivateTab, image: UIImage.templateImageNamed("menu-NewPrivateTab"), identifier: UIAction.Identifier("linkContextMenu.openInNewPrivateTab")) { _ in
                addTab(url, true)
            })

            actions.append(UIAction(title: Strings.ContextMenuBookmarkLink, image: UIImage.templateImageNamed("menu-Bookmark"), identifier: UIAction.Identifier("linkContextMenu.bookmarkLink")) { _ in
                self.addBookmark(url: url.absoluteString, title: elements.title)
                SimpleToast().showAlertWithText(Strings.AppMenuAddBookmarkConfirmMessage, bottomContainer: self.webViewContainer)
                TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .contextMenu)
            })

            actions.append(UIAction(title: Strings.ContextMenuDownloadLink, image: UIImage.templateImageNamed("menu-panel-Downloads"), identifier: UIAction.Identifier("linkContextMenu.download")) {_ in
                self.pendingDownloadWebView = currentTab.webView
                DownloadContentScript.requestDownload(url: url, tab: currentTab)
            })

            actions.append(UIAction(title: Strings.ContextMenuCopyLink, image: UIImage.templateImageNamed("menu-Copy-Link"), identifier: UIAction.Identifier("linkContextMenu.copyLink")) { _ in
                UIPasteboard.general.url = url
            })

            actions.append(UIAction(title: Strings.ContextMenuShareLink, image: UIImage.templateImageNamed("action_share"), identifier: UIAction.Identifier("linkContextMenu.share")) { _ in
                guard let tab = self.tabManager[webView], let helper = tab.getContentScript(name: ContextMenuHelper.name()) as? ContextMenuHelper else { return }
                // This is only used on ipad for positioning the popover. On iPhone it is an action sheet.
                let p = webView.convert(helper.touchPoint, to: self.view)
                self.presentActivityViewController(url as URL, sourceView: self.view, sourceRect: CGRect(origin: p, size: CGSize(width: 10, height: 10)), arrowDirection: .unknown)
            })

            if let url = elements.image {
                let photoAuthorizeStatus = PHPhotoLibrary.authorizationStatus()
                actions.append(UIAction(title: Strings.ContextMenuSaveImage, identifier: UIAction.Identifier("linkContextMenu.saveImage")) { _ in
                    let handlePhotoLibraryAuthorized = {
                        DispatchQueue.main.async {
                            getImageData(url) { data in
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
                                })
                            }
                        }
                    }

                    let handlePhotoLibraryDenied = {
                        DispatchQueue.main.async {
                            let accessDenied = UIAlertController(title: Strings.PhotoLibraryFirefoxWouldLikeAccessTitle, message: Strings.PhotoLibraryFirefoxWouldLikeAccessMessage, preferredStyle: .alert)
                            let dismissAction = UIAlertAction(title: Strings.CancelString, style: .default, handler: nil)
                            accessDenied.addAction(dismissAction)
                            let settingsAction = UIAlertAction(title: Strings.OpenSettingsString, style: .default ) { _ in
                                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
                            }
                            accessDenied.addAction(settingsAction)
                            self.present(accessDenied, animated: true, completion: nil)
                        }
                    }

                    if photoAuthorizeStatus == .notDetermined {
                        PHPhotoLibrary.requestAuthorization({ status in
                            guard status == .authorized else {
                                handlePhotoLibraryDenied()
                                return
                            }

                            handlePhotoLibraryAuthorized()
                        })
                    } else if photoAuthorizeStatus == .authorized {
                        handlePhotoLibraryAuthorized()
                    } else {
                        handlePhotoLibraryDenied()
                    }
                })

                actions.append(UIAction(title: Strings.ContextMenuCopyImage, identifier: UIAction.Identifier("linkContextMenu.copyImage")) { _ in
                    // put the actual image on the clipboard
                    // do this asynchronously just in case we're in a low bandwidth situation
                    let pasteboard = UIPasteboard.general
                    pasteboard.url = url as URL
                    let changeCount = pasteboard.changeCount
                    let application = UIApplication.shared
                    var taskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
                    taskId = application.beginBackgroundTask (expirationHandler: {
                        application.endBackgroundTask(taskId)
                    })

                    makeURLSession(userAgent: UserAgent.fxaUserAgent, configuration: URLSessionConfiguration.default).dataTask(with: url) { (data, response, error) in
                        guard let _ = validatedHTTPResponse(response, statusCode: 200..<300) else {
                            application.endBackgroundTask(taskId)
                            return
                        }

                        // Only set the image onto the pasteboard if the pasteboard hasn't changed since
                        // fetching the image; otherwise, in low-bandwidth situations,
                        // we might be overwriting something that the user has subsequently added.
                        if changeCount == pasteboard.changeCount, let imageData = data, error == nil {
                            pasteboard.addImageWithData(imageData, forURL: url)
                        }

                        application.endBackgroundTask(taskId)
                    }.resume()
                })

                actions.append(UIAction(title: Strings.ContextMenuCopyImageLink, identifier: UIAction.Identifier("linkContextMenu.copyImageLink")) { _ in
                    UIPasteboard.general.url = url as URL
                })
            }

            return UIMenu(title: url.absoluteString, children: actions)
        }))
    }
}

extension WKNavigationAction {
    /// Allow local requests only if the request is privileged.
    var isInternalUnprivileged: Bool {
        guard let url = request.url else {
            return true
        }

        if let url = InternalURL(url) {
            return !url.isAuthorized
        } else {
            return false
        }
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if tabManager.selectedTab?.webView !== webView {
            return
        }

        updateFindInPageVisibility(visible: false)

        // If we are going to navigate to a new page, hide the reader mode button. Unless we
        // are going to a about:reader page. Then we keep it on screen: it will change status
        // (orange color) as soon as the page has loaded.
        if let url = webView.url {
            if !url.isReaderModeURL {
                urlBar.updateReaderModeState(ReaderModeState.unavailable)
                hideReaderModeBar(animated: false)
            }
        }
    }

    // Recognize an Apple Maps URL. This will trigger the native app. But only if a search query is present. Otherwise
    // it could just be a visit to a regular page on maps.apple.com.
    fileprivate func isAppleMapsURL(_ url: URL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" {
            if url.host == "maps.apple.com" && url.query != nil {
                return true
            }
        }
        return false
    }

    // Recognize a iTunes Store URL. These all trigger the native apps. Note that appstore.com and phobos.apple.com
    // used to be in this list. I have removed them because they now redirect to itunes.apple.com. If we special case
    // them then iOS will actually first open Safari, which then redirects to the app store. This works but it will
    // leave a 'Back to Safari' button in the status bar, which we do not want.
    fileprivate func isStoreURL(_ url: URL) -> Bool {
        if url.scheme == "http" || url.scheme == "https" || url.scheme == "itms-apps" {
            if url.host == "itunes.apple.com" {
                return true
            }
        }
        return false
    }

    // Use for sms and mailto links, which do not show a confirmation before opening.
    fileprivate func showSnackbar(forExternalUrl url: URL, tab: Tab, completion: @escaping (Bool) -> ()) {
        let snackBar = TimerSnackBar(text: Strings.ExternalLinkGenericConfirmation + "\n\(url.absoluteString)", img: nil)
        let ok = SnackButton(title: Strings.OKString, accessibilityIdentifier: "AppOpenExternal.button.ok") { bar in
            tab.removeSnackbar(bar)
            completion(true)
        }
        let cancel = SnackButton(title: Strings.CancelString, accessibilityIdentifier: "AppOpenExternal.button.cancel") { bar in
            tab.removeSnackbar(bar)
            completion(false)
        }
        snackBar.addButton(ok)
        snackBar.addButton(cancel)
        tab.addSnackbar(snackBar)
    }

    // This is the place where we decide what to do with a new navigation action. There are a number of special schemes
    // and http(s) urls that need to be handled in a different way. All the logic for that is inside this delegate
    // method.

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let tab = tabManager[webView] else {
            decisionHandler(.cancel)
            return
        }

        if InternalURL.isValid(url: url) {
            if navigationAction.navigationType != .backForward, navigationAction.isInternalUnprivileged {
                log.warning("Denying unprivileged request: \(navigationAction.request)")
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
                showSnackbar(forExternalUrl: url, tab: tab) { isOk in
                    guard isOk else { return }
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
        //        if url.scheme == "javascript", navigationAction.request.isPrivileged {
        //            decisionHandler(.cancel)
        //            if let javaScriptString = url.absoluteString.replaceFirstOccurrence(of: "javascript:", with: "").removingPercentEncoding {
        //                webView.evaluateJavaScript(javaScriptString)
        //            }
        //            return
        //        }

        // Second special case are a set of URLs that look like regular http links, but should be handed over to iOS
        // instead of being loaded in the webview. Note that there is no point in calling canOpenURL() here, because
        // iOS will always say yes.

        if isAppleMapsURL(url) {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
            return
        }

        if isStoreURL(url) {
            decisionHandler(.cancel)

            // Make sure to wait longer than delaySelectingNewPopupTab to ensure selectedTab is correct
            DispatchQueue.main.asyncAfter(deadline: .now() + tabManager.delaySelectingNewPopupTab + 0.1) {
                guard let tab = self.tabManager.selectedTab else { return }
                if tab.bars.isEmpty { // i.e. no snackbars are showing
                    TimerSnackBar.showAppStoreConfirmationBar(forTab: tab, appStoreURL: url) { _ in
                        // If a new window was opened for this URL (it will have no history), close it.
                        if tab.historyList.isEmpty {
                            self.tabManager.removeTabAndUpdateSelectedIndex(tab)
                        }
                    }
                }
            }
            return
        }

        // Handles custom mailto URL schemes.
        if url.scheme == "mailto" {
            showSnackbar(forExternalUrl: url, tab: tab) { isOk in
                guard isOk else { return }

                if let mailToMetadata = url.mailToMetadata(), let mailScheme = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption), mailScheme != "mailto" {
                    self.mailtoLinkHandler.launchMailClientForScheme(mailScheme, metadata: mailToMetadata, defaultMailtoURL: url)
                } else {
                    UIApplication.shared.open(url, options: [:])
                }

                LeanPlumClient.shared.track(event: .openedMailtoLink)
            }

            decisionHandler(.cancel)
            return
        }

        // https://blog.mozilla.org/security/2017/11/27/blocking-top-level-navigations-data-urls-firefox-59/
        if url.scheme == "data" {
            let url = url.absoluteString
            // Allow certain image types
            if url.hasPrefix("data:image/") && !url.hasPrefix("data:image/svg+xml") {
                decisionHandler(.allow)
                return
            }

            // Allow video, and certain application types
            if url.hasPrefix("data:video/") || url.hasPrefix("data:application/pdf") || url.hasPrefix("data:application/json") {
                decisionHandler(.allow)
                return
            }

            // Allow plain text types.
            // Note the format of data URLs is `data:[<media type>][;base64],<data>` with empty <media type> indicating plain text.
            if url.hasPrefix("data:;base64,") || url.hasPrefix("data:,") || url.hasPrefix("data:text/plain,") || url.hasPrefix("data:text/plain;") {
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)
            return
        }

        // This is the normal case, opening a http or https url, which we handle by loading them in this WKWebView. We
        // always allow this. Additionally, data URIs are also handled just like normal web pages.

        if ["http", "https", "blob", "file"].contains(url.scheme) {
            if navigationAction.targetFrame?.isMainFrame ?? false {
                tab.changedUserAgent = Tab.ChangeUserAgent.contains(url: url)
            }

            pendingRequests[url.absoluteString] = navigationAction.request

            if tab.changedUserAgent {
                let platformSpecificUserAgent = UserAgent.oppositeUserAgent(domain: url.baseDomain ?? "")
                webView.customUserAgent = platformSpecificUserAgent
            } else {
                webView.customUserAgent = UserAgent.getUserAgent(domain: url.baseDomain ?? "")
            }
            
            decisionHandler(.allow)
            return
        }

        if !(url.scheme?.contains("firefox") ?? true) {
            showSnackbar(forExternalUrl: url, tab: tab) { isOk in
                guard isOk else { return }
                UIApplication.shared.open(url, options: [:]) { openedURL in
                    // Do not show error message for JS navigated links or redirect as it's not the result of a user action.
                    if !openedURL, navigationAction.navigationType == .linkActivated {
                        let alert = UIAlertController(title: Strings.UnableToOpenURLErrorTitle, message: Strings.UnableToOpenURLError, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }

        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let response = navigationResponse.response
        let responseURL = response.url

        var request: URLRequest?
        if let url = responseURL {
            request = pendingRequests.removeValue(forKey: url.absoluteString)
        }

        // We can only show this content in the web view if this web view is not pending
        // download via the context menu.
        let canShowInWebView = navigationResponse.canShowMIMEType && (webView != pendingDownloadWebView)
        let forceDownload = webView == pendingDownloadWebView

        // Check if this response should be handed off to Passbook.
        if let passbookHelper = OpenPassBookHelper(request: request, response: response, canShowInWebView: canShowInWebView, forceDownload: forceDownload, browserViewController: self) {
            // Clear the network activity indicator since our helper is handling the request.
            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            // Open our helper and cancel this response from the webview.
            passbookHelper.open()
            decisionHandler(.cancel)
            return
        }

        if #available(iOS 12.0, *) {
            // Check if this response should be displayed in a QuickLook for USDZ files.
            if let previewHelper = OpenQLPreviewHelper(request: request, response: response, canShowInWebView: canShowInWebView, forceDownload: forceDownload, browserViewController: self) {

                // Certain files are too large to download before the preview presents, block and use a temporary document instead
                if let tab = tabManager[webView] {
                    if navigationResponse.isForMainFrame, response.mimeType != MIMEType.HTML, let request = request {
                        tab.temporaryDocument = TemporaryDocument(preflightResponse: response, request: request)
                        previewHelper.url = tab.temporaryDocument!.getURL().value as NSURL

                        // Open our helper and cancel this response from the webview.
                        previewHelper.open()
                        decisionHandler(.cancel)
                        return
                    } else {
                        tab.temporaryDocument = nil
                    }
                }

                // We don't have a temporary document, fallthrough
            }
        }

        // Check if this response should be downloaded.
        if let downloadHelper = DownloadHelper(request: request, response: response, canShowInWebView: canShowInWebView, forceDownload: forceDownload, browserViewController: self) {
            // Clear the network activity indicator since our helper is handling the request.
            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            // Clear the pending download web view so that subsequent navigations from the same
            // web view don't invoke another download.
            pendingDownloadWebView = nil

            // Open our helper and cancel this response from the webview.
            downloadHelper.open()
            decisionHandler(.cancel)
            return
        }

        // If the content type is not HTML, create a temporary document so it can be downloaded and
        // shared to external applications later. Otherwise, clear the old temporary document.
        // NOTE: This should only happen if the request/response came from the main frame, otherwise
        // we may end up overriding the "Share Page With..." action to share a temp file that is not
        // representative of the contents of the web view.
        if navigationResponse.isForMainFrame, let tab = tabManager[webView] {
            if response.mimeType != MIMEType.HTML, let request = request {
                tab.temporaryDocument = TemporaryDocument(preflightResponse: response, request: request)
            } else {
                tab.temporaryDocument = nil
            }

            tab.mimeType = response.mimeType
        }

        // If none of our helpers are responsible for handling this response,
        // just let the webview handle it as normal.
        decisionHandler(.allow)
    }

    /// Invoked when an error occurs while starting to load data for the main frame.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Ignore the "Frame load interrupted" error that is triggered when we cancel a request
        // to open an external application and hand it over to UIApplication.openURL(). The result
        // will be that we switch to the external app, for example the app store, while keeping the
        // original web page in the tab instead of replacing it with an error page.
        let error = error as NSError
        if error.domain == "WebKitErrorDomain" && error.code == 102 {
            return
        }

        if checkIfWebContentProcessHasCrashed(webView, error: error as NSError) {
            return
        }

        if error.code == Int(CFNetworkErrors.cfurlErrorCancelled.rawValue) {
            if let tab = tabManager[webView], tab === tabManager.selectedTab {
                urlBar.currentURL = tab.url?.displayURL
            }
            return
        }

        if let url = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            ErrorPageHelper(certStore: profile.certStore).loadPage(error, forUrl: url, inWebView: webView)
        }
    }

    fileprivate func checkIfWebContentProcessHasCrashed(_ webView: WKWebView, error: NSError) -> Bool {
        if error.code == WKError.webContentProcessTerminated.rawValue && error.domain == "WebKitErrorDomain" {
            print("WebContent process has crashed. Trying to reload to restart it.")
            webView.reload()
            return true
        }

        return false
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        // If this is a certificate challenge, see if the certificate has previously been
        // accepted by the user.
        let origin = "\(challenge.protectionSpace.host):\(challenge.protectionSpace.port)"
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust,
           let cert = SecTrustGetCertificateAtIndex(trust, 0), profile.certStore.containsCertificate(cert, forOrigin: origin) {
            completionHandler(.useCredential, URLCredential(trust: trust))
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest ||
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM,
              let tab = tabManager[webView] else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // If this is a request to our local web server, use our private credentials.
        if challenge.protectionSpace.host == "localhost" && challenge.protectionSpace.port == Int(WebServer.sharedInstance.server.port) {
            completionHandler(.useCredential, WebServer.sharedInstance.credentials)
            return
        }

        // The challenge may come from a background tab, so ensure it's the one visible.
        tabManager.selectTab(tab)

        let loginsHelper = tab.getContentScript(name: LoginsHelper.name()) as? LoginsHelper
        Authenticator.handleAuthRequest(self, challenge: challenge, loginsHelper: loginsHelper).uponQueue(.main) { res in
            if let credentials = res.successValue {
                completionHandler(.useCredential, credentials.credentials)
            } else {
                completionHandler(.rejectProtectionSpace, nil)
            }
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let tab = tabManager[webView] else { return }

        tab.url = webView.url
        // When tab url changes after web content starts loading on the page
        // We notify the contect blocker change so that content blocker status can be correctly shown on beside the URL bar
        tab.contentBlocker?.notifyContentBlockingChanged()
        self.scrollController.resetZoomState()

        if tabManager.selectedTab === tab {
            updateUIForReaderHomeStateForTab(tab)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let tab = tabManager[webView] {
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
