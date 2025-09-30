// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// FXIOS-12832 We shouldn't need `@preconcurrency` on to suppress warnings
@preconcurrency import WebKit
import Common

public protocol WKUIHandler: WKUIDelegate {
    var delegate: EngineSessionDelegate? { get set }
    /// Wether the session attacched to this handler is active or not.
    var isActive: Bool { get set }

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

public class AlertPresenter {
    weak var presenter: UIViewController?

    public init(presenter: UIViewController?) {
        self.presenter = presenter
    }

    @MainActor
    func present(_ alert: UIAlertController) {
        presenter?.present(alert, animated: true)
    }

    func canPresent() -> Bool {
        return presenter?.presentedViewController == nil
    }
}

public class DefaultUIHandler: NSObject, WKUIHandler, WKJavaScriptPromptAlertControllerDelegate {
    public weak var delegate: EngineSessionDelegate?
    private var sessionCreator: SessionCreator?

    public var isActive = false
    private let sessionDependencies: EngineSessionDependencies
    private let application: Application
    private let policyDecider: WKPolicyDecider
    private let alertPresenter: AlertPresenter
    private let store: WKJavscriptAlertStore
    private let popupThrottler: WKPopupThrottler

    // TODO: FXIOS-13670 With Swift 6 we can use default params in the init
    @MainActor
    public static func factory(
        sessionDependencies: EngineSessionDependencies,
        alertPresenter: AlertPresenter = AlertPresenter(presenter: nil),
        sessionCreator: SessionCreator? = nil
    ) -> DefaultUIHandler {
        let sessionCreator = sessionCreator ?? WKSessionCreator(dependencies: sessionDependencies)
        let policyDecider = WKPolicyDeciderFactory()
        let application = UIApplication.shared
        return DefaultUIHandler(
            sessionDependencies: sessionDependencies,
            sessionCreator: sessionCreator,
            alertPresenter: alertPresenter,
            application: application,
            policyDecider: policyDecider
        )
    }

    init(sessionDependencies: EngineSessionDependencies,
         sessionCreator: SessionCreator,
         alertPresenter: AlertPresenter,
         application: Application,
         policyDecider: WKPolicyDecider) {
        self.sessionCreator = sessionCreator
        self.sessionDependencies = sessionDependencies
        self.policyDecider = policyDecider
        self.application = application
        self.alertPresenter = alertPresenter
        self.store = DefaultJavscriptAlertStore()
        self.popupThrottler = DefaultPopupThrottler()
        super.init()

        (self.sessionCreator as? WKSessionCreator)?.onNewSessionCreated = { [weak self] in
            self?.delegate?.onRequestOpenNewSession($0)
        }
    }

    public func webView(_ webView: WKWebView,
                        createWebViewWith configuration: WKWebViewConfiguration,
                        for navigationAction: WKNavigationAction,
                        windowFeatures: WKWindowFeatures) -> WKWebView? {
        let policy = policyDecider.policyForPopupNavigation(action: navigationAction)
        switch policy {
        case .cancel:
            return nil
        case .allow:
            let url = navigationAction.request.url
            let urlString = url?.absoluteString ?? ""
            let webView = sessionCreator?.createPopupSession(configuration: configuration, parent: webView)
            guard let webView else { return nil }

            if url == nil || urlString.isEmpty,
               let blank = URL(string: EngineConstants.aboutBlank),
               let url = BrowserURL(browsingContext: BrowsingContext(type: .internalNavigation,
                                                                     url: blank)) {
                webView.load(URLRequest(url: url.url))
            }
            return webView
        case .launchExternalApp:
            guard let url = navigationAction.request.url, application.canOpen(url: url) else { return nil }
            application.open(url: url)
            return nil
        }
    }

    let logger = DefaultLogger.shared

    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    ) {
        let alert = MessageAlert(message: message, frame: frame, completionHandler: completionHandler)
        guard popupThrottler.canShowAlert(type: .alert) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                completionHandler()
            }
            return
        }
        if alertPresenter.canPresent() {
            let controller = alert.alertController()
            controller.delegate = self
            logger.log("Presenting alert controller", level: .fatal, category: .webview)
            alertPresenter.present(controller)
        } else {
            logger.log("storing alert controller", level: .fatal, category: .webview)
            store.add(alert)
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    }

    // TODO: FXIOS-8244 - Handle Javascript panel messages in WebEngine (epic part 3)
    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
    }

    public func webViewDidClose(_ webView: WKWebView) {
        // TODO: FXIOS-8245 - Handle webViewDidClose in WebEngine (epic part 3)
    }

    public func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping @MainActor (UIContextMenuConfiguration?) -> Void
    ) {
        completionHandler(delegate?.onProvideContextualMenu(linkURL: elementInfo.linkURL))
    }

    public func webView(_ webView: WKWebView,
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

    // MARK: - WKJavaScriptPromptAlertControllerDelegate
    func promptAlertControllerDidDismiss(_ alertController: WKJavaScriptPromptAlertController) {
        guard let alert = store.popFirst(), alertPresenter.canPresent() else { return }
        alertPresenter.present(alert.alertController())
    }
}
