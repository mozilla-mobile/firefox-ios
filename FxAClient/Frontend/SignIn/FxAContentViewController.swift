/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Snap
import UIKit
import WebKit

let FxADefaultTimeoutTimeInterval = 10.0 // Seconds.  We'll want some telemetry on load times in the wild.

protocol FxAContentViewControllerDelegate {
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
class FxAContentViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    private enum RemoteCommand: String {
        case CanLinkAccount = "can_link_account"
        case Loaded = "loaded"
        case Login = "login"
        case SessionStatus = "session_status"
        case SignOut = "sign_out"
    }

    var url: NSURL!

    var delegate: FxAContentViewControllerDelegate?
    var debug: Bool = false

    private var timer: NSTimer?
    private var isLoaded: Bool = false {
        didSet {
            if isLoaded {
                 UIView.transitionFromView(interstitialView, toView: webView,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    completion: { finished in
                        self.interstitialView.removeFromSuperview()
                        self.interstitialSpinnerView.stopAnimating()
                    })
            }
        }
    }

    private var isError: Bool = false {
        didSet {
            if isError {
                interstitialErrorView.hidden = false
                UIView.transitionFromView(interstitialSpinnerView, toView: interstitialErrorView,
                    duration: 0.5,
                    options: UIViewAnimationOptions.TransitionCrossDissolve,
                    completion: { finished in
                        self.interstitialSpinnerView.removeFromSuperview()
                        self.interstitialSpinnerView.stopAnimating()
                })
            }
        }
    }

    // The view shown while the content is loading in the background web view.
    private var interstitialView: UIView!
    private var interstitialSpinnerView: UIActivityIndicatorView!
    private var interstitialErrorView: UILabel!

    // The web view that displays content from the fxa-content-server.
    private var webView: WKWebView!

    func startLoading(timeout: Double = FxADefaultTimeoutTimeInterval) {
        if self.isLoaded {
            return
        }
        if timeout > 0 {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timeout, target: self, selector: "SELdidTimeOut", userInfo: nil, repeats: false)
        } else {
            self.timer = nil
        }
        self.webView.loadRequest(NSURLRequest(URL: url))
        self.interstitialSpinnerView.startAnimating()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Don't extend under navigation bar.
        self.edgesForExtendedLayout = UIRectEdge.None

        // This background agrees with the content server background.
        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0)

        self.webView = makeWebView()
        view.addSubview(webView)

        // Web content fills view.
        webView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        // Destructuring let causes problems.
        let ret = makeInterstitialViews()
        self.interstitialView = ret.0
        self.interstitialSpinnerView = ret.1
        self.interstitialErrorView = ret.2

        view.addSubview(interstitialView)
        interstitialView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
        if debug {
            // This lets you see the underlying webview, but not interact with it.
            interstitialView.alpha = 0.5
        }

        startLoading()
    }

    private func makeWebView() -> WKWebView {
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

        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1, height: 1),
            configuration: config
        )
        webView.navigationDelegate = self

        // Don't allow overscrolling.
        webView.scrollView.bounces = false
        return webView
    }

    private func makeInterstitialViews() -> (UIView, UIActivityIndicatorView, UILabel) {
        let view = UIView()
        // Keeping the background constant prevents a pop of mismatched color.
        view.backgroundColor = UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0)

        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        view.addSubview(spinner)

        let error = UILabel()
        error.text = NSLocalizedString("Could not connect to Firefox Accounts.", comment: "Settings")
        error.textColor = UIColor.redColor() // Firefox Orange!
        error.textAlignment = NSTextAlignment.Center
        error.hidden = true
        view.addSubview(error)

        spinner.snp_makeConstraints { make in
            make.center.equalTo(view)
            return
        }

        error.snp_makeConstraints { make in
            make.center.equalTo(view)
            make.left.equalTo(view.snp_left).offset(20)
            make.right.equalTo(view.snp_right).offset(-20)
            make.height.equalTo(44)
            return
        }

        return (view, spinner, error)
    }

    // Send a message to the content server.
    func injectData(type: String, content: [String: AnyObject]) {
        NSLog("injectData: " + type)
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
        NSLog("onLogin: " + data.toString())
        injectData("message", content: ["status": "login"])
        self.delegate?.contentViewControllerDidSignIn(self, data: data)
    }

    // The content server page is ready to be shown.
    private func onLoaded() {
        NSLog("Handling loaded remote command.");
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true
    }

    // Handle a message coming from the content server.
    func handleRemoteCommand(rawValue: String, data: JSON) {
        if let command = RemoteCommand(rawValue: rawValue) {
            NSLog("Handling remote command '\(rawValue)' .");

            if !isLoaded && command != .Loaded {
                // Work around https://github.com/mozilla/fxa-content-server/issues/2137
                NSLog("Synthesizing loaded remote command.")
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
        } else {
            NSLog("Unknown remote command '\(rawValue)'; ignoring.");
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
        let fileRoot = NSBundle.mainBundle().pathForResource("FxASignIn", ofType: "js")
        return NSString(contentsOfFile: fileRoot!, encoding: NSUTF8StringEncoding, error: nil)!
    }

    func webView(webView: WKWebView!, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError!) {
        self.timer = nil
        self.isError = true
    }

    func webView(webView: WKWebView!, didFailNavigation navigation: WKNavigation!, withError error: NSError!) {
        // Ignore for now.
    }

    func SELdidTimeOut() {
        self.timer = nil
        self.isError = true
    }
}
