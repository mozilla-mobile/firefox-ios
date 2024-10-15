// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import WebKit
import Account
import Common
import Shared

enum DismissType {
    case dismiss
    case popToTabTray
    case popToRootVC
}

/**
 Show the FxA web content for signing in, signing up, or showing FxA settings.
 Messaging from the website to native is with WKScriptMessageHandler.
 */
class FxAWebViewController: UIViewController {
    fileprivate let dismissType: DismissType
    fileprivate var webView: WKWebView
    /// Used to show a second WKWebView to browse help links.
    fileprivate var helpBrowser: WKWebView?
    fileprivate let viewModel: FxAWebViewModel
    private let logger: Logger
    /// Closure for dismissing higher up FxA Sign in view controller
    var shouldDismissFxASignInViewController: (() -> Void)?

    /**
     init() FxAWebView.

     - parameter pageType: Specify login flow or settings page if already logged in.
     - parameter profile: a Profile.
     - parameter dismissalStyle: depending on how this was presented, it uses modal dismissal, or if part
                                 of a UINavigationController stack it will pop to the root.
     - parameter deepLinkParams: URL args passed in from deep link that propagate to FxA web view
     */
    init(pageType: FxAPageType,
         profile: Profile,
         dismissalStyle: DismissType,
         deepLinkParams: FxALaunchParams,
         shouldAskForNotificationPermission: Bool = true,
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = FxAWebViewModel(pageType: pageType,
                                         profile: profile,
                                         deepLinkParams: deepLinkParams,
                                         shouldAskForNotificationPermission: shouldAskForNotificationPermission)

        self.dismissType = dismissalStyle

        let contentController = WKUserContentController()
        viewModel.setupUserScript(for: contentController)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsLinkPreview = false
        webView.accessibilityLabel = .FxAWebContentAccessibilityLabel
        webView.scrollView.bounces = false  // Don't allow overscrolling.
        webView.customUserAgent = FxAWebViewModel.mobileUserAgent

        self.logger = logger

        super.init(nibName: nil, bundle: nil)
        let scriptMessageHandler = WKScriptMessageHandleDelegate(self)
        contentController.add(scriptMessageHandler, name: "accountsCommandHandler")
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        webView.navigationDelegate = self
        view = webView
        webView.addObserver(self, forKeyPath: KVOConstants.URL.rawValue, options: .new, context: nil)
        viewModel.setupFirstPage { [weak self] (request, telemetryEventMethod) in
            self?.loadRequest(request, isPairing: telemetryEventMethod == .qrPairing)
        }

        viewModel.onDismissController = { [weak self] in
            self?.endPairingConnectionBackgroundTask()
            self?.dismiss(animated: true)
        }
    }

    /**
     Dismiss according the `dismissType`, depending on whether this view was presented modally or on navigation stack.
     */
    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        if dismissType == .dismiss {
            super.dismiss(animated: animated, completion: completion)
        } else if dismissType == .popToTabTray {
            shouldDismissFxASignInViewController?()
        } else {
            // Pop to settings view controller
            navigationController?.popToRootViewController(animated: true)
            completion?()
        }
    }

    deinit {
        webView.removeObserver(self, forKeyPath: KVOConstants.URL.rawValue)
        endPairingConnectionBackgroundTask()
    }

    // MARK: Background task

    /// In case the application is set to background while pairing with a QR code, we need
    /// to ensure the application can keep the connection alive a little longer so pairing can be completed
    private let backgroundTaskName = "moz.org.sync.qrcode.auth"
    private var backgroundTaskID = UIBackgroundTaskIdentifier(rawValue: 0)

    private func loadRequest(_ request: URLRequest, isPairing: Bool) {
        // Only start background task on pairing request
        guard isPairing else {
            webView.load(request)
            return
        }

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: backgroundTaskName) { [weak self] in
            self?.webView.stopLoading()
            self?.endPairingConnectionBackgroundTask()
        }

        webView.load(request)
    }

    private func endPairingConnectionBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }

    func presentSavePDFController(outputURL: URL) {
        let controller = UIActivityViewController(activityItems: [outputURL], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        present(controller, animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate
extension FxAWebViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let blobURL = navigationAction.request.url,
           viewModel.isMozillaAccountPDF(blobURL: blobURL, webViewURL: webView.url) {
            viewModel.getURLForPDF(webView: webView, blobURL: blobURL) { [weak self] outputURL in
                guard let self else { return }
                if let outputURL {
                    self.presentSavePDFController(outputURL: outputURL)
                    decisionHandler(.cancel)
                } else {
                    let decision = self.viewModel.shouldAllowRedirectAfterLogIn(basedOn: navigationAction.request.url)
                    decisionHandler(decision)
                }
            }
        } else {
            let decision = viewModel.shouldAllowRedirectAfterLogIn(basedOn: navigationAction.request.url)
            decisionHandler(decision)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let hideLongpress = "document.body.style.webkitTouchCallout='none';"
        webView.evaluateJavascriptInDefaultContentWorld(hideLongpress)

        // The helpBrowser shows the current URL in the navbar, the main fxa webview does not.
        guard webView !== helpBrowser else {
            navigationItem.title = viewModel.composeTitle(
                basedOn: webView.url,
                hasOnlySecureContent: webView.hasOnlySecureContent
            )
            return
        }

        navigationItem.title = nil
    }
}

// MARK: - WKScriptMessageHandler
extension FxAWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        viewModel.handle(scriptMessage: message)
    }
}

// MARK: - WKUIDelegate
extension FxAWebViewController: WKUIDelegate {
    /// Blank target links (support links) will create a 2nd webview (the `helpBrowser`) to browse. This webview
    /// will have a close button in the navigation bar to go back to the main fxa webview.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard helpBrowser == nil else { return nil }
        let f = webView.frame
        let wv = WKWebView(frame: CGRect(width: f.width, height: f.height), configuration: configuration)
        helpBrowser?.load(navigationAction.request)
        webView.addSubview(wv)
        helpBrowser = wv
        helpBrowser?.navigationDelegate = self

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: AccessibilityIdentifiers.GeneralizedIdentifiers.back,
            style: .plain,
            target: self,
            action: #selector(closeHelpBrowser)
        )

        return helpBrowser
    }

    @objc
    func closeHelpBrowser() {
        UIView.animate(
            withDuration: 0.2,
            animations: {
                self.helpBrowser?.alpha = 0
            }, completion: {_ in
                self.helpBrowser?.removeFromSuperview()
                self.helpBrowser = nil
            })

        navigationItem.title = nil
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = false
    }
}

// MARK: - WKScriptMessageHandleDelegate

// WKScriptMessageHandleDelegate uses for holding weak `self` to prevent retain cycle.
// self - webview - configuration
//   \                    /
//   userContentController
private class WKScriptMessageHandleDelegate: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let delegate else { return }
        delegate.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - Observe value
extension FxAWebViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard let kp = keyPath,
              let path = KVOConstants(rawValue: kp)
        else {
            sendObserveValueError(forKeyPath: keyPath)
            return
        }

        switch path {
        case .URL:
            if let flow = viewModel.fxAWebViewTelemetry.getFlowFromUrl(fxaUrl: webView.url) {
                viewModel.fxAWebViewTelemetry.recordTelemetry(for: FxAFlow.startedFlow(type: flow))
            }
        default:
            sendObserveValueError(forKeyPath: keyPath)
        }
    }

    private func sendObserveValueError(forKeyPath keyPath: String?) {
        logger.log("FxA webpage unhandled KVO",
                   level: .info,
                   category: .sync,
                   description: "Unhandled KVO key: \(keyPath ?? "nil")")
    }
}
