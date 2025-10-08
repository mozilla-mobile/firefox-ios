// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// Intent to bridge WebEngine code to Client
public protocol SessionCreator: AnyObject {
    /// Creates a popup WKWebView given a configuration and the source WebView for the popup.
    @MainActor
    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView?
    
    func alertStore(for webView: WKWebView) -> WKJavaScriptAlertStore?
    
    func isSessionActive(for webView: WKWebView) -> Bool
    
    func currentActiveStore() -> WKJavaScriptAlertStore?
}

//class WKSessionCreator: SessionCreator {
//    private let dependencies: EngineSessionDependencies
//    var onNewSessionCreated: VoidReturnCallback<EngineSession>?
//
//    init(dependencies: EngineSessionDependencies) {
//        self.dependencies = dependencies
//    }
//
//    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView? {
//        // TODO: FXIOS-13668 The newly created popup session should have the parent privacy settings
// Add comment to ticket for SampleBrowser
//        let configurationProvider = DefaultWKEngineConfigurationProvider(configuration: configuration)
//        let session = WKEngineSession.sessionFactory(userScriptManager: DefaultUserScriptManager(),
//                                                     dependencies: dependencies,
//                                                     configurationProvider: configurationProvider)
//
//        guard let session, let webView = session.webView as? WKWebView else { return nil }
//        onNewSessionCreated?(session)
//        return webView
//    }
//}
