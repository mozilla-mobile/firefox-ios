/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit
import UIKit
import WebKit
import SwiftyJSON

protocol FxAContentViewControllerDelegate: class {
    func contentViewControllerDidSignIn(_ viewController: FxAContentViewController, withFlags: FxALoginFlags)
    func contentViewControllerDidCancel(_ viewController: FxAContentViewController)
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
    var fxaOptions = FxALaunchParams()

    fileprivate enum RemoteCommand: String {
        case canLinkAccount = "can_link_account"
        case loaded = "loaded"
        case login = "login"
        case sessionStatus = "session_status"
        case signOut = "sign_out"
    }

    weak var delegate: FxAContentViewControllerDelegate?

    let profile: Profile

    init(profile: Profile) {
        self.profile = profile
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
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )

        // Handle messages from the content server (via our user script).
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.add(LeakAvoider(delegate:self), name: "accountsCommandHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 1, height: 1),
            configuration: config
        )
        webView.allowsLinkPreview = false
        webView.navigationDelegate = self
        webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")

        // Don't allow overscrolling.
        webView.scrollView.bounces = false
        return webView
    }

    // Send a message to the content server.
    func injectData(_ type: String, content: [String: Any]) {
        let data = [
            "type": type,
            "content": content,
        ] as [String : Any]
        let json = JSON(data).stringValue() ?? ""
        let script = "window.postMessage(\(json), '\(self.url.absoluteString)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    fileprivate func onCanLinkAccount(_ data: JSON) {
        //    // We need to confirm a relink - see shouldAllowRelink for more
        //    let ok = shouldAllowRelink(accountData.email);
        let ok = true
        injectData("message", content: ["status": "can_link_account", "data": ["ok": ok]])
    }

    // We're not signed in to a Firefox Account at this time, which we signal by returning an error.
    fileprivate func onSessionStatus(_ data: JSON) {
        injectData("message", content: ["status": "error"])
    }

    // We're not signed in to a Firefox Account at this time. We should never get a sign out message!
    fileprivate func onSignOut(_ data: JSON) {
        injectData("message", content: ["status": "error"])
    }

    // The user has signed in to a Firefox Account.  We're done!
    fileprivate func onLogin(_ data: JSON) {
        injectData("message", content: ["status": "login"])

        let app = UIApplication.shared
        let helper = FxALoginHelper.sharedInstance
        helper.delegate = self
        helper.application(app, didReceiveAccountJSON: data)
    }

    // The content server page is ready to be shown.
    fileprivate func onLoaded() {
        self.timer?.invalidate()
        self.timer = nil
        self.isLoaded = true

        if AppConstants.MOZ_FXA_DEEP_LINK_FORM_FILL {
            fillField("email", value: self.fxaOptions.email)
            fillField("access_code", value: self.fxaOptions.access_code)
        }
    }
    
    // Attempt to fill out a field in content view
    fileprivate func fillField(_ className: String?, value: String?) {
        guard let name = className, let val = value else {
            return
        }
        let script = "$('.\(name)').val('\(val)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    // Handle a message coming from the content server.
    func handleRemoteCommand(_ rawValue: String, data: JSON) {
        if let command = RemoteCommand(rawValue: rawValue) {
            if !isLoaded && command != .loaded {
                // Work around https://github.com/mozilla/fxa-content-server/issues/2137
                onLoaded()
            }

            switch command {
            case .loaded:
                onLoaded()
            case .login:
                onLogin(data)
            case .canLinkAccount:
                onCanLinkAccount(data)
            case .sessionStatus:
                onSessionStatus(data)
            case .signOut:
                onSignOut(data)
            }
        }
    }

    // Dispatch webkit messages originating from our child webview.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Make sure we're communicating with a trusted page. That is, ensure the origin of the
        // message is the same as the origin of the URL we initially loaded in this web view.
        // Note that this exploit wouldn't be possible if we were using WebChannels; see
        // https://developer.mozilla.org/en-US/docs/Mozilla/JavaScript_code_modules/WebChannel.jsm
        let origin = message.frameInfo.securityOrigin
        guard origin.`protocol` == url.scheme && origin.host == url.host && origin.port == (url.port ?? 0) else {
            print("Ignoring message - \(origin) does not match expected origin: \(url.origin ?? "nil")")
            return
        }

        if message.name == "accountsCommandHandler" {
            let body = JSON(message.body)
            let detail = body["detail"]
            handleRemoteCommand(detail["command"].stringValue, data: detail["data"])
        }
    }

    fileprivate func getJS() -> String {
        let fileRoot = Bundle.main.path(forResource: "FxASignIn", ofType: "js")
        return (try! NSString(contentsOfFile: fileRoot!, encoding: String.Encoding.utf8.rawValue)) as String
    }

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Ignore for now.
    }

    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Ignore for now.
    }
}

extension FxAContentViewController: FxAPushLoginDelegate {
    func accountLoginDidSucceed(withFlags flags: FxALoginFlags) {
        DispatchQueue.main.async {
            self.delegate?.contentViewControllerDidSignIn(self, withFlags: flags)
        }
    }

    func accountLoginDidFail() {
        DispatchQueue.main.async {
            self.delegate?.contentViewControllerDidCancel(self)
        }
    }
}

/*
LeakAvoider prevents leaks with WKUserContentController
http://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
*/

class LeakAvoider: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}
