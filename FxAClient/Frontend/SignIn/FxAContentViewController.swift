/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit
import WebKit

protocol FxAContentViewControllerDelegate: class {
    func contentViewControllerDidSignIn(viewController: FxAContentViewController, data: JSON) -> Void
    func contentViewControllerDidCancel(viewController: FxAContentViewController)
}

/**
 * A controller that manages a single web view connected to the Firefox
 * Accounts (Desktop) Sync postMessage interface.
 *
 * The postMessage interface is not really documented, but it is simple
 * enough.  I reverse engineered it from the Desktop Firefox code and the
 * fxa-content-server git repository.
 */
class FxAContentViewController: SettingsContentViewController, WKScriptMessageHandler {
    private enum RemoteCommand: String {
        case CanLinkAccount = "can_link_account"
        case Loaded = "loaded"
        case Login = "login"
        case SessionStatus = "session_status"
        case SignOut = "sign_out"
    }

    weak var delegate: FxAContentViewControllerDelegate?

    init() {
        super.init(backgroundColor: UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0), title: NSAttributedString(string: "Firefox Accounts"))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func makeWebView() -> WKWebView {
        // Inject  our setup code after the page loads.
        let source = getJS()
        let userScript = WKUserScript(
            source: source,
            injectionTime: WKUserScriptInjectionTime.AtDocumentEnd,
            forMainFrameOnly: true
        )

        // Handle messages from the content server (via our user script).
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.addScriptMessageHandler(LeakAvoider(delegate:self), name: "accountsCommandHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1, height: 1),
            configuration: config
        )
        webView.navigationDelegate = self
        webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")

        // Don't allow overscrolling.
        webView.scrollView.bounces = false
        return webView
    }

    // Send a message to the content server.
    func injectData(type: String, content: [String: AnyObject]) {
        let data = [
            "type": type,
            "content": content,
        ]
        let json = JSON(data).toString(false)
        let script = "window.postMessage(\(json), '\(self.url)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func onCanLinkAccount(data: JSON) {
        //    // We need to confirm a relink - see shouldAllowRelink for more
        //    let ok = shouldAllowRelink(accountData.email);
        let ok = true
        injectData("message", content: ["status": "can_link_account", "data": ["ok": ok]]);
    }

    // We're not signed in to a Firefox Account at this time, which we signal by returning an error.
    private func onSessionStatus(data: JSON) {
        injectData("message", content: ["status": "error"])
    }

    // We're not signed in to a Firefox Account at this time. We should never get a sign out message!
    private func onSignOut(data: JSON) {
        injectData("message", content: ["status": "error"])
    }

    // The user has signed in to a Firefox Account.  We're done!
    private func onLogin(data: JSON) {
        injectData("message", content: ["status": "login"])
        self.delegate?.contentViewControllerDidSignIn(self, data: data)
    }

    // The content server page is ready to be shown.
    private func onLoaded() {
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true
    }

    // Handle a message coming from the content server.
    func handleRemoteCommand(rawValue: String, data: JSON) {
        if let command = RemoteCommand(rawValue: rawValue) {
            if !isLoaded && command != .Loaded {
                // Work around https://github.com/mozilla/fxa-content-server/issues/2137
                onLoaded()
            }

            switch (command) {
            case .Loaded:
                onLoaded()
            case .Login:
                onLogin(data)
            case .CanLinkAccount:
                onCanLinkAccount(data)
            case .SessionStatus:
                onSessionStatus(data)
            case .SignOut:
                onSignOut(data)
            }
        }
    }

    // Dispatch webkit messages originating from our child webview.
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Make sure we're communicating with a trusted page. That is, ensure the origin of the
        // message is the same as the origin of the URL we initially loaded in this web view.
        // Note that this exploit wouldn't be possible if we were using WebChannels; see
        // https://developer.mozilla.org/en-US/docs/Mozilla/JavaScript_code_modules/WebChannel.jsm
        if #available(iOS 9.0, *) {
            let origin = message.frameInfo.securityOrigin
            guard origin.`protocol` == url.scheme && origin.host == url.host && origin.port == (url.port ?? 0) else {
                print("Ignoring message - \(origin) does not match expected origin \(url.origin)")
                return
            }
        } else {
            guard url.origin == message.frameInfo.request.URL?.origin else { return }
        }

        if (message.name == "accountsCommandHandler") {
            let body = JSON(message.body)
            let detail = body["detail"]
            handleRemoteCommand(detail["command"].asString!, data: detail["data"])
        }
    }

    private func getJS() -> String {
        let fileRoot = NSBundle.mainBundle().pathForResource("FxASignIn", ofType: "js")
        return (try! NSString(contentsOfFile: fileRoot!, encoding: NSUTF8StringEncoding)) as String
    }

    override func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        // Ignore for now.
    }

    override func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        // Ignore for now.
    }
}

/*
LeakAvoider prevents leaks with WKUserContentController
http://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
*/

class LeakAvoider : NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceiveScriptMessage: message)
    }
}