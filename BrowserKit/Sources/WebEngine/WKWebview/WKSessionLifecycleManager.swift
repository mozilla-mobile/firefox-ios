// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Lifecycle manager purpose is to properly activate or deactive engine sessions whenever they
/// are shown or removed from the engine view
protocol WKSessionLifecycleManager {
    func activate(_ session: WKEngineSession)
    func deactivate(_ session: WKEngineSession)
}

struct DefaultWKSessionLifecycleManager: WKSessionLifecycleManager {
    private var notificationCenter: NotificationProtocol = NotificationCenter.default

    func activate(_ session: WKEngineSession) {
        session.isActive = true

        // TODO: FXIOS-11420 - Handle PDF loading view in WebEngine
//        if selectedTab.isDownloadingDocument() {
//            navigationHandler?.showDocumentLoading()
//        } else {
//            navigationHandler?.removeDocumentLoading()
//        }

        // TODO: FXIOS-12073 - Ensure newly selected session is properly themed
//        selectedTab.webView?.applyTheme(theme: currentTheme())

        // When the newly selected tab is the homepage or another internal tab,
        // we need to explicitly set the reader mode state to be unavailable.
        let readerModeState: ReaderModeState
        if let url = session.webView.url, WKInternalURL.scheme != url.scheme {
            readerModeState = session.sessionData.readerModeState ?? .unavailable
        } else {
            readerModeState = .unavailable
        }
        notificationCenter.post(
            name: .ReaderModeSessionChanged,
            withObject: nil,
            withUserInfo: [EngineConstants.isPrivateKey: session.sessionData.isPrivate ?? false,
                           EngineConstants.readerModeStateKey: readerModeState]
        )

        // TODO: FXIOS-12074 - Handle needs reload when selected tab changed
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
