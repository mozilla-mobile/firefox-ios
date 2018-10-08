/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
import WebKit

private let AllFramesAtDocumentStartJS: String = {
    let path = Bundle.main.path(forResource: "AllFramesAtDocumentStart", ofType: "js")!
    let source = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
    return """
        (function() {
            const SECURITY_TOKEN = "\(UserScriptManager.securityToken)";
            \(source)
        })();
        """
}()

private let UserScriptTemplate = """
    (function() {
        document.addEventListener("DOMContentLoaded", function() {
            document.title = /*name*/"%1$@";
        });

        // BEGIN: WebExtensionAPI.js
        /*const browser*/%2$@
        // END: WebExtensionAPI.js
    })();

    // BEGIN: Aggregate source from WebExtension background scripts
    %3$@
    // END: Aggregate source from WebExtension background scripts
    """

class WebExtensionBackgroundProcess: NSObject {
    let webExtension: WebExtension
    let webView: WKWebView

    fileprivate var createTabCompletionHandlers: [(Tab) -> Void] = []

    init?(webExtension: WebExtension) {
        self.webExtension = webExtension

        let json = webExtension.manifest["background"]

        guard let scripts = json["scripts"].array?.compactMap({ $0.string }),
            scripts.count > 0 else {
            return nil
        }

        var source = ""

        for script in scripts {
            let url = webExtension.tempDirectoryURL.appendingPathComponent(script)
            if let contentScriptSource = try? NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String {
                source += contentScriptSource + "\n"
            }
        }

        guard source.count > 0 else {
            return nil
        }

        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

        let allFramesAtDocumentStartUserScript = WKUserScript(source: AllFramesAtDocumentStartJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.webView.configuration.userContentController.addUserScript(allFramesAtDocumentStartUserScript)

        let name = "WebExtensionBackgroundProcess: \(webExtension.manifest["name"].string ?? webExtension.id)"

        let wrappedAPIUserScriptSource = String(format: UserScriptTemplate, name, webExtension.webExtensionAPIJS, source)
        let apiUserScript = WKUserScript(source: wrappedAPIUserScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        self.webView.configuration.userContentController.addUserScript(apiUserScript)
        self.webView.configuration.userContentController.add(webExtension.interface, name: "webExtensionAPI")

        self.webView.allowsLinkPreview = false

        let url = webExtension.urlForResource(at: "/__firefox__/web-extension-background-process")
        self.webView.load(URLRequest(url: url))

        super.init()

        self.webView.uiDelegate = self
    }

    func createTab(_ completionHandler: @escaping (Tab) -> Void) {
        createTabCompletionHandlers.append(completionHandler)

        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("""
                (function() {
                    window.open("about:blank");
                })();
                """)
        }
    }
}

extension WebExtensionBackgroundProcess: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard webView == self.webView,
            createTabCompletionHandlers.count > 0,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let tabManager = appDelegate.tabManager else {
            return nil
        }

        let tab = Tab(configuration: configuration, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
        tabManager.configureTab(tab, request: nil, afterTab: nil, flushToDisk: true, zombie: false, isPopup: true)

        guard let tabWebView = tab.webView, let apiUserScript = webExtension.browserAction?.apiUserScript else {
            return nil
        }

        tabWebView.configuration.userContentController.removeAllUserScripts()
        UserScriptManager.default.injectUserScripts(tab: tab)
        tabWebView.configuration.userContentController.addUserScript(apiUserScript)

        let completionHandler = createTabCompletionHandlers.removeFirst()
        completionHandler(tab)

        return tabWebView
    }
}
