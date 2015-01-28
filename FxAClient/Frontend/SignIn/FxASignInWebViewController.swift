/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

protocol FxASignInWebViewControllerDelegate {
    func didCancel() -> Void
    func didLoad() -> Void
    func didSignIn(data: JSON) -> Void
}

/**
 * A controller that manages a single web view connected to the Firefox
 * Accounts (Desktop) Sync postMessage interface.
 *
 * The postMessage interface is not really documented, but it is simple
 * enough.  I reverse engineered it from the Desktop Firefox code and the
 * fxa-content-server git repository.
 */
class FxASignInWebViewController: UIViewController, WKScriptMessageHandler {
    var delegate: FxASignInWebViewControllerDelegate?

    // Optional delegate for detecting failed requests.
    var navigationDelegate: WKNavigationDelegate?

    var url: NSURL?

    private var webView: WKWebView!

    override func loadView() {
        NSLog("loadView!")
        super.loadView()
    }

    func startLoad(url: NSURL) {
        NSLog("startLoad")
        self.url = url
        loadWebView(url)
        NSLog("startLoad: \(webView)")
    }

    override func viewDidLoad() {
        NSLog("viewDidLoad!")
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "didCancel")

        view.addSubview(webView!)

        // Web content fills view.
        webView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        webView = nil
    }

    private func loadWebView(url: NSURL?) {
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
        contentController.addScriptMessageHandler(
            self,
            name: "accountsCommandHandler"
        )

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(
            frame: CGRectMake(0, 0, 0, 0),
            configuration: config
        )
        webView.navigationDelegate = navigationDelegate
        if let url = url {
            webView!.loadRequest(NSURLRequest(URL: url))
        }

        // Don't allow overscrolling.
        webView.scrollView.bounces = false
    }

    func didCancel() {
        delegate?.didCancel()
    }

    // Send a message to the content server.
    func injectData(type: String, content: [String: AnyObject]) {
        let data = [
            "type": type,
            "content": content,
        ]
        let json = JSON(data).toString(pretty: false)
        let script = "window.postMessage(\(json), '\(url)');"
        NSLog("reponse: \(json)")
        webView!.evaluateJavaScript(script, completionHandler: nil)
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
        NSLog("Logged in with email: %@ and uid: %@", data["email"].asString!, data["uid"].asString!)
        injectData("message", content: ["status": "login"])
        dismissViewControllerAnimated(true, completion: nil)
        self.delegate?.didSignIn(data)
    }

    // The content server page is ready to be shown.
    private func onLoad(data: JSON) {
        delegate?.didLoad()
    }

    // Handle a message coming from the content server.
    func handleRemoteCommand(command: String, data: JSON) {
        NSLog("command: %@", command)
        switch command {
        case "load":
            onLoad(data)
        case "login":
            onLogin(data)
        case "can_link_account":
            onCanLinkAccount(data)
        case "session_status":
            onSessionStatus(data)
        case "sign_out":
            onSignOut(data)
        default:
            NSLog("Unexpected remote command received: " + command + ". Ignoring command.");
        }
    }

    // Dispatch webkit messages originating from our child webview.
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if (message.name == "accountsCommandHandler") {
            let body = JSON(message.body)
            let detail = body["detail"]
            handleRemoteCommand(detail["command"].asString!, data: detail["data"])
        } else {
            NSLog("Got unrecognized message \(message)")
        }
    }

    private func getJS() -> String {
        let fileRoot = NSBundle.mainBundle().pathForResource("FxASignIn",
                ofType: "js")
        return NSString(contentsOfFile: fileRoot!, encoding: NSUTF8StringEncoding, error: nil)!
    }
}
