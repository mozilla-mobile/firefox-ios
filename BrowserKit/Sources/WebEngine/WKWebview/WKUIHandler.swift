// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import WebKit
import Common

protocol WKUIHandler: WKUIDelegate {
    var delegate: EngineSessionDelegate? { get set }
    var isActive: Bool {get set}

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView?

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    )

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    )

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    )

    func webViewDidClose(_ webView: WKWebView)

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping @MainActor (UIContextMenuConfiguration?) -> Void
    )

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    )
}

class DefaultUIHandler: NSObject, WKUIHandler {
    weak var delegate: EngineSessionDelegate?
    public var isActive = false
    private let sessionDependencies: EngineSessionDependencies
    private let application: Application
    private let policyDecider: WKPolicyDecider

    init(sessionDependencies: EngineSessionDependencies,
         application: Application = UIApplication.shared,
         policyDecider: WKPolicyDecider = WKPolicyDeciderFactory()) {
        self.sessionDependencies = sessionDependencies
        self.policyDecider = policyDecider
        self.application = application
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        let policy = policyDecider.policyForPopupNavigation(action: navigationAction)
        switch policy {
        case .cancel:
            return nil
        case .allow:
            let configurationProvider = DefaultWKEngineConfigurationProvider(configuration: configuration)
            let session = WKEngineSession.sessionFactory(userScriptManager: DefaultUserScriptManager(),
                                                         dependencies: sessionDependencies,
                                                         configurationProvider: configurationProvider)

            guard let session, let webView = session.webView as? WKWebView else { return nil }
            let url = navigationAction.request.url
            let urlString = url?.absoluteString ?? ""

            if url == nil || urlString.isEmpty,
               let blank = URL(string: EngineConstants.aboutBlank),
               let url = BrowserURL(browsingContext: BrowsingContext(type: .internalNavigation, url: blank)) {
                session.load(browserURL: url)
            }

            delegate?.onRequestOpenNewSession(session)
            return webView
        case .launchExternalApp:
            guard let url = navigationAction.request.url, application.canOpen(url: url) else { return nil }
            application.open(url: url)
            return nil
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    func webViewDidClose(_ webView: WKWebView) {
        // TODO: FXIOS-8245 - Handle webViewDidClose in WebEngine (epic part 3)
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping @MainActor (UIContextMenuConfiguration?) -> Void
    ) {
        completionHandler(delegate?.onProvideContextualMenu(linkURL: elementInfo.linkURL))
    }

    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void) {
        guard isActive && (delegate?.requestMediaCapturePermission() ?? false) else {
            decisionHandler(.deny)
            return
        }
        decisionHandler(.prompt)
    }
}
