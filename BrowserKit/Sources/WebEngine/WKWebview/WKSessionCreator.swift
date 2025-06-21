// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

public protocol SessionCreator: AnyObject {
    /// Creates a popup WKWebView given a configuration and the source WebView for the popup.
    @MainActor
    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView?
}

typealias VoidReturnCallback<T> = (T) -> Void

class WKSessionCreator: SessionCreator {
    private let dependencies: EngineSessionDependencies
    var onNewSessionCreated: VoidReturnCallback<EngineSession>?

    init(dependencies: EngineSessionDependencies) {
        self.dependencies = dependencies
    }

    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView? {
        let configurationProvider = DefaultWKEngineConfigurationProvider(configuration: configuration)
        let session = WKEngineSession.sessionFactory(userScriptManager: DefaultUserScriptManager(),
                                                     dependencies: dependencies,
                                                     configurationProvider: configurationProvider)

        guard let session, let webView = session.webView as? WKWebView else { return nil }
        onNewSessionCreated?(session)
        return webView
    }
}
