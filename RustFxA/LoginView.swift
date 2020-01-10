/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import Account
import MozillaAppServices

enum DismissType {
    case dismiss
    case popToRootVC
}

enum FxALoginFlow {
    case emailLoginFlow
    case signUpFlow
}

class RustLoginView: UIViewController, WKNavigationDelegate {
    private var webView = WKWebView()
    var dismissType: DismissType = .dismiss
    let fxaLaunchParams: FxALaunchParams
    let loginFlowType: FxALoginFlow

    init(fxaOptions: FxALaunchParams?, flowType: FxALoginFlow) {
        self.fxaLaunchParams = fxaOptions ?? FxALaunchParams(query: [String: String]())
        self.loginFlowType = flowType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        self.view = self.webView

        RustFirefoxAccounts.shared?.accountManager.beginAuthentication() { [weak self] result in
            if case .success(let url) = result {
                self?.webView.load(URLRequest(url: url))
            }
        }
    }

    // TODO:  hookup, as this was copied from Fxa content view controller
    private func setupUrl(url: String) -> String {
        var url = url
        if loginFlowType == .signUpFlow {
            url = url.replaceFirstOccurrence(of: "signin", with: "signup")
        }

        guard fxaLaunchParams.query.count > 0 else {
            return url
        }

        // Only append certain parameters. Note that you can't override the service and context params.
        var params = fxaLaunchParams.query
        params.removeValue(forKey: "service")
        params.removeValue(forKey: "context")

        if loginFlowType == .emailLoginFlow {
            params["action"] = "email"
        }
        params["style"] = "trailhead" // adds Trailhead banners to the page

        let queryURL = params.filter { ["action", "style", "signin", "entrypoint"].contains($0.key) || $0.key.range(of: "utm_") != nil }.map({
            return "\($0.key)=\($0.value)"
        }).joined(separator: "&")

        // TODO double check it should be & not ? to append params
        if url.contains("?") {
            return "\(url)&\(queryURL)"
        } else {
            return "\(url)?\(queryURL)"
        }
    }

    private func matchingRedirectURLReceived(components: URLComponents) {
        var dic = [String: String]()
        components.queryItems?.forEach { dic[$0.name] = $0.value }
        let data = FxaAuthData(code: dic["code"]!, state: dic["state"]!, actionQueryParam: "signin")
        RustFirefoxAccounts.shared?.accountManager.finishAuthentication(authData: data) { _ in
            let application = UIApplication.shared
            // ask for push notification
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        return
                    }
                    if granted {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        }

        if dismissType == .dismiss {
            dismiss(animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let redirectUrl = RustFirefoxAccounts.shared?.redirectURL, let navigationURL = navigationAction.request.url {
            let expectedRedirectURL = URL(string: redirectUrl)!
            if navigationURL.scheme == expectedRedirectURL.scheme && navigationURL.host == expectedRedirectURL.host && navigationURL.path == expectedRedirectURL.path,
                let components = URLComponents(url: navigationURL, resolvingAgainstBaseURL: true) {
                matchingRedirectURLReceived(components: components)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

//    private func styleNavigationBar() {
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
//    }
}
