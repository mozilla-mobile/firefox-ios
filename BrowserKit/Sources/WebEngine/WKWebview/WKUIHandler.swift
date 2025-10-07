// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// FXIOS-12832 We shouldn't need `@preconcurrency` on to suppress warnings
@preconcurrency import WebKit
import Common

@MainActor
public protocol WKUIHandler: WKUIDelegate {
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

@MainActor
public class AlertPresenter {
    weak var presenter: UIViewController?

    public init(presenter: UIViewController?) {
        self.presenter = presenter
    }

    func present(_ alert: UIViewController) {
        presenter?.present(alert, animated: true)
    }

    func canPresent() -> Bool {
        return presenter?.presentedViewController == nil
    }
}

public class DefaultUIHandler: NSObject, WKUIHandler, WKJavascriptPromptAlertControllerDelegate {
    public weak var delegate: EngineSessionDelegate?
    private weak var sessionCreator: SessionCreator?

    public var isActive = false
    private let sessionDependencies: EngineSessionDependencies
    private let application: Application
    private let policyDecider: WKPolicyDecider
    private let alertFactory: WKJavaScriptAlertInfoFactory?
    private let alertPresenter: AlertPresenter
    private let logger: Logger

    // TODO: FXIOS-13670 With Swift 6 we can use default params in the init
    @MainActor
    public static func factory(
        sessionDependencies: EngineSessionDependencies,
        alertFactory: WKJavaScriptAlertInfoFactory? = nil,
        alertPresenter: AlertPresenter = AlertPresenter(presenter: nil),
        sessionCreator: SessionCreator? = nil
    ) -> DefaultUIHandler {
        let policyDecider = WKPolicyDeciderFactory()
        let application = UIApplication.shared
        return DefaultUIHandler(
            sessionDependencies: sessionDependencies,
            sessionCreator: sessionCreator,
            alertFactory: alertFactory,
            alertPresenter: alertPresenter,
            application: application,
            policyDecider: policyDecider
        )
    }

    init(sessionDependencies: EngineSessionDependencies,
         sessionCreator: SessionCreator?,
         alertFactory: WKJavaScriptAlertInfoFactory? = nil,
         alertPresenter: AlertPresenter,
         application: Application,
         policyDecider: WKPolicyDecider,
         logger: Logger = DefaultLogger.shared
    ) {
        self.sessionCreator = sessionCreator
        self.sessionDependencies = sessionDependencies
        self.policyDecider = policyDecider
        self.application = application
        self.alertFactory = alertFactory
        self.alertPresenter = alertPresenter
        self.logger = logger
        super.init()
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

    public func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    ) {
        guard let alertFactory else { return }
        let alert = alertFactory.makeMessageAlert(message: message, frame: frame, completion: completionHandler)
        handleJavaScriptAlert(alert, for: webView) {
            completionHandler()
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        guard let alertFactory else { return }
        let alert = alertFactory.makeConfirmationAlert(message: message, frame: frame) { confirm in
            self.logger.log("JavaScript confirm panel was completed with result: \(confirm)", level: .info, category: .webview)
            completionHandler(confirm)
        }
        handleJavaScriptAlert(alert, for: webView) {
            completionHandler(false)
        }
    }

    public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        guard let alertFactory else { return }
        let alert = alertFactory.makeTextInputAlert(message: prompt, frame: frame, defaultText: defaultText) { input in
            self.logger.log("JavaScript text input panel was completed with input", level: .info, category: .webview)
            completionHandler(input)
        }
        handleJavaScriptAlert(alert, for: webView) {
            completionHandler("")
        }
    }
    
    private func handleJavaScriptAlert(
        _ alert: WKJavaScriptAlertInfo,
        for webView: WKWebView,
        spamCallback: @escaping () -> Void
    ) {
        if jsAlertExceedsSpamLimits(webView) {
            // User is being spammed. Squelch alert. Note that we have to do this after
            // a delay to avoid JS that could spin the CPU endlessly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                spamCallback()
            }
        } else if sessionCreator?.isSessionActive(for: webView) == true, alertPresenter.canPresent() {
            logger.log("JavaScript \(alert.type.rawValue) panel will be presented.", level: .info, category: .webview)
            let alertController = alert.alertController()
            alertController.delegate = self
            alertPresenter.present(alertController)
        } else if let store = sessionCreator?.alertStore(for: webView) {
            logger.log("JavaScript \(alert.type.rawValue) panel is queued.", level: .info, category: .webview)
            store.queueJavascriptAlertPrompt(alert)
        }
    }
    
    private func jsAlertExceedsSpamLimits(_ webView: WKWebView) -> Bool {
        guard sessionCreator?.isSessionActive(for: webView) == true,
              let store = sessionCreator?.alertStore(for: webView) else {
            return false
        }
        let canShow = store.popupThrottler.canShowAlert(type: .alert)
        if canShow {
            store.popupThrottler.willShowAlert(type: .alert)
        }
        return !canShow
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
    
    // MARK: - WKJavaScriptAlertControllerDelegate
    
    public func promptAlertControllerDidDismiss(_ alertController: any WKJavaScriptPromptAlertController) {
        checkForJSAlerts()
    }
    
    private func checkForJSAlerts() {
        guard let store = sessionCreator?.currentActiveStore(), store.hasJavascriptAlertPrompt() else { return }

        if alertPresenter.canPresent() {
            guard let nextAlert = store.dequeueJavascriptAlertPrompt() else { return }
            let controller = nextAlert.alertController()
            controller.delegate = self
            alertPresenter.present(controller)
        } else {
            // We cannot show the alert right now but there is one queued on the selected tab
            // check after a delay if we can show it
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.checkForJSAlerts()
            }
        }
    }
}
