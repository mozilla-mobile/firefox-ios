/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class RelayContentScript: TabContentScript {
    private let tab: Tab
    private let prefs: Prefs

    private let relayUrl = "https://relay.firefox.com/emails/"

    class func name() -> String {
        return "RelayContentScript"
    }

    func scriptMessageHandlerName() -> String? {
        return "relayMessageHandler"
    }

    required init(tab: Tab, prefs: Prefs) {
        self.tab = tab
        self.prefs = prefs
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        print(message.name)
        if let body = message.body as? String {
            print(body)
            if (body == "buttonClicked") {
                buttonClicked()
            }
        }
    }

    private func buttonClicked() {
        fetchNewEmailAddress { (newEmailAddress) in
            if let newEmailAddress = newEmailAddress {
                self.sendEmailAddressToWebView(newEmailAddress)
            }
        }
    }

    private func fetchNewEmailAddress(completion: @escaping (String?) -> Void) {
        let apiKey = prefs.stringForKey("relay-api-key")
        let json: [String: Any] = [
            "api_token": apiKey
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        guard let url = URL(string: relayUrl) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("moz-extension", forHTTPHeaderField: "Origin")
        request.addValue(relayUrl, forHTTPHeaderField: "Referer")

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            guard let data = data, error == nil else { completion(nil); return }
            let dataString = String(bytes: data, encoding: String.Encoding.utf8)
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                completion(responseJSON["address"] as? String)
            }
        }

        task.resume()
    }

    private func sendEmailAddressToWebView(_ emailAddress: String) {
        DispatchQueue.main.async {
            let js = "document.querySelector('input[type=email]').value='\(emailAddress)';"
            self.tab.webView?.evaluateJavaScript(js, completionHandler: { (result, error) in

            })
        }
    }
}
