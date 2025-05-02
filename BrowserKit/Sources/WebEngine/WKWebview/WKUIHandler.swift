// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency
import WebKit

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

protocol Application {
    func open(url: URL)

    func canOpen(url: URL) -> Bool
}

extension UIApplication: Application {
    func open(url: URL) {
        open(url, options: [:])
    }

    func canOpen(url: URL) -> Bool {
        return canOpenURL(url)
    }
}

class DefaultUIHandler: NSObject, WKUIHandler {
    weak var delegate: EngineSessionDelegate?
    public var isActive = false
    private let application: Application
    private let policyDeciders: [WKPolicyDecider]

    init(application: Application = UIApplication.shared,
         policyDeciders: [WKPolicyDecider] = []) {
        self.policyDeciders = policyDeciders
        self.application = application
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        guard !navigationAction.isInternalUnprivileged,
              shouldRequestBeOpenedAsPopup(navigationAction.request) else {

            guard let url = navigationAction.request.url else { return nil }
            
            if url.scheme == "whatsapp" && application.canOpen(url: url) {
                application.open(url: url)
            }
            return nil
        }

        // HTTPS policy
        guard !isPayPalPopUp(navigationAction) else { return nil }

        // APPLauncherPolicy
        if navigationAction.canOpenExternalApp,  let url = navigationAction.request.url {
            application.open(url: url)
            return nil
        }
        return nil
    }

    func isPayPalPopUp(_ navigationAction: WKNavigationAction) -> Bool {
        // The WKNavigationAction request for Paypal popUp is empty which causes that we open a blank page in
        // createWebViewWith. We will show Paypal popUp in page like mobile devices using the mobile User Agent
        // so we will block the creation of a new Webview with this check
        return navigationAction.sourceFrame.request.url?.baseDomain == "paypal.com"
    }

    private func shouldRequestBeOpenedAsPopup(_ request: URLRequest) -> Bool {
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

extension WKNavigationAction {
    /// Allow local requests only if the request is privileged.
    var isInternalUnprivileged: Bool {
        guard let url = request.url else { return true }

        if let url = WKInternalURL(url) {
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
