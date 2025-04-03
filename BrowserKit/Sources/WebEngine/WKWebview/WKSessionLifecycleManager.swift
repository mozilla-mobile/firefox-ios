// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// TODO: Laurie - documentation
protocol WKSessionLifecycleManager {
    func activate(_ session: WKEngineSession)
    func deactivate(_ session: WKEngineSession)
}

struct DefaultWKSessionLifecycleManager: WKSessionLifecycleManager {
    private var notificationCenter: NotificationProtocol = NotificationCenter.default

    func activate(_ session: WKEngineSession) {
        session.isActive = true

        // TODO: Add JIRA
//        if selectedTab.isDownloadingDocument() {
//            navigationHandler?.showDocumentLoading()
//        } else {
//            navigationHandler?.removeDocumentLoading()
//        }

        // TODO: Add JIRA
//        // Theme is applied to the tab and webView in the else case
//        // because in the if block is applied already to all the tabs and web views
//        selectedTab.applyTheme(theme: currentTheme())
//        selectedTab.webView?.applyTheme(theme: currentTheme())

        notificationCenter.post(
            name: .ReaderModeSessionChanged,
            withObject: nil,
            withUserInfo: [WKEngineConstants.isPrivateKey: session.sessionData.isPrivate]
        )

        // When the newly selected tab is the homepage or another internal tab,
        // we need to explicitly set the reader mode state to be unavailable.
        if let url = session.webView.url, WKInternalURL.scheme != url.scheme,
           let readerMode = selectedTab.getContentScript(name: ReaderMode.name()) as? ReaderMode {
            updateReaderModeState(for: selectedTab, readerModeState: readerMode.state)
            if readerMode.state == .active {
                showReaderModeBar(animated: false)
            } else {
                hideReaderModeBar(animated: false)
            }
        } else {
            updateReaderModeState(for: selectedTab, readerModeState: .unavailable)
        }

        // TODO: Add JIRA - Handle needs reload when selected tab changed
//        if webView.url == nil {
//            // The webView can go gray if it was zombified due to memory pressure.
//            // When this happens, the URL is nil, so try restoring the page upon selection.
//            needsReload = true
//        }
//        /// If the selectedTab is showing an error page trigger a reload
//        if let url = selectedTab.url, let internalUrl = InternalURL(url), internalUrl.isErrorPage {
//            needsReload = true
//        }
//
//        if needsReload {
//            selectedTab.reloadPage()
//        }
    }

    func deactivate(_ session: WKEngineSession) {
        session.isActive = false

        // Remove the old accessibilityLabel. Since this webview shouldn't be visible, it doesn't need it
        // and having multiple views with the same label confuses tests.
        let previousWebView = session.webView
        previousWebView.endEditing(true)
        previousWebView.accessibilityLabel = nil
        previousWebView.accessibilityElementsHidden = true
        previousWebView.accessibilityIdentifier = nil
        previousWebView.removeFromSuperview()
    }
}
