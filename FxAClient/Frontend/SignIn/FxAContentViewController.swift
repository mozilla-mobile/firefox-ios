/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Snap
import UIKit
import WebKit

protocol FxAContentViewControllerDelegate {
    func contentViewControllerDidCancel(vc: FxAContentViewController) -> Void
    func contentViewControllerDidLoad(vc: FxAContentViewController) -> Void
    func contentViewControllerDidSignIn(vc: FxAContentViewController, data: JSON) -> Void
    func contentViewControllerDidFailProvisionalNavigation
            (vc: FxAContentViewController, withError error: NSError!) -> Void
    func contentViewControllerDidFailNavigation
            (vc: FxAContentViewController, withError error: NSError!) -> Void
}

/**
 * A controller that manages a single web view connected to the Firefox
 * Accounts (Desktop) Sync postMessage interface.
 *
 * The postMessage interface is not really documented, but it is simple
 * enough.  I reverse engineered it from the Desktop Firefox code and the
 * fxa-content-server git repository.
 */
class FxAContentViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    private enum RemoteCommand: String {
        case CanLinkAccount = "can_link_account"
        case Loaded = "loaded"
        case Login = "login"
        case SessionStatus = "session_status"
        case SignOut = "sign_out"
    }

    var delegate: FxAContentViewControllerDelegate?

    var url: NSURL?

    private var webView: WKWebView!

    override func loadView() {
        super.loadView()
    }

    func startLoad(url: NSURL) {
        self.url = url
        loadWebView(url)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "SELdidCancel")

        view.addSubview(webView!)

        // Web content fills view.
        webView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
    }

    private func loadWebView(url: NSURL) {
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
        webView.navigationDelegate = self
        webView.loadRequest(NSURLRequest(URL: url))

        // Don't allow overscrolling.
        webView.scrollView.bounces = false
    }

    func SELdidCancel() {
        delegate?.contentViewControllerDidCancel(self)
    }

    // Send a message to the content server.
    func injectData(type: String, content: [String: AnyObject]) {
        let data = [
            "type": type,
            "content": content,
        ]
        let json = JSON(data).toString(pretty: false)
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
        dismissViewControllerAnimated(true, completion: nil)
        self.delegate?.contentViewControllerDidSignIn(self, data: data)
    }

    // The content server page is ready to be shown.
    private func onLoaded(data: JSON) {
        delegate?.contentViewControllerDidLoad(self)
    }

    // Handle a message coming from the content server.
    func handleRemoteCommand(command: String, data: JSON) {
        if let command = RemoteCommand(rawValue: command) {
            switch (command) {
            case .Loaded:
                onLoaded(data)
            case .Login:
                onLogin(data)
            case .CanLinkAccount:
                onCanLinkAccount(data)
            case .SessionStatus:
                onSessionStatus(data)
            case .SignOut:
                onSignOut(data)
            }
        } else {
            NSLog("Unknown remote command '\(command)'; ignoring.");
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

    func webView(webView: WKWebView!, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError!) {
        delegate?.contentViewControllerDidFailProvisionalNavigation(self, withError: error)
    }

    func webView(webView: WKWebView!, didFailNavigation navigation: WKNavigation!, withError error: NSError!) {
        delegate?.contentViewControllerDidFailNavigation(self, withError: error)
    }
}
