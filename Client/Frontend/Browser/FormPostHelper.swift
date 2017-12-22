/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

struct FormPostData {
    let action: URL
    let method: String
    let target: String
    let enctype: String
    let requestBody: Data
    
    init?(messageBody: Any) {
        guard let messageBodyDict = messageBody as? [String : String],
            let actionString = messageBodyDict["action"],
            let method = messageBodyDict["method"],
            let target = messageBodyDict["target"],
            let enctype = messageBodyDict["enctype"],
            let requestBodyString = messageBodyDict["requestBody"],
            let action = URL(string: actionString),
            let requestBody = requestBodyString.data(using: .utf8) else {
                return nil
        }
        
        self.action = action
        self.method = method
        self.target = target
        self.enctype = enctype
        self.requestBody = requestBody
    }
    
    func matchesNavigationAction(_ navigationAction: WKNavigationAction) -> Bool {
        let request = navigationAction.request
        let headers = request.allHTTPHeaderFields ?? [:]
        
        if self.action == request.url,
            self.method == request.httpMethod,
            self.enctype == headers["Content-Type"] {
            return true
        }
        
        return false
    }
    
    func urlRequestWithHeaders(_ headers: [String : String]?) -> URLRequest {
        var urlRequest = URLRequest(url: action)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = headers ?? [:]
        urlRequest.setValue(enctype, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestBody
        return urlRequest
    }
}

class FormPostHelper: TabContentScript {
    fileprivate weak var tab: Tab?
    fileprivate var blankTargetFormPosts: [FormPostData] = []

    required init(tab: Tab) {
        self.tab = tab
        if let path = Bundle.main.path(forResource: "FormPostHelper", ofType: "js"), let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }
    
    static func name() -> String {
        return "FormPostHelper"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "formPostHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let formPostData = FormPostData(messageBody: message.body) else {
            print("Unable to parse FormPostData from script message body.")
            return
        }
        
        blankTargetFormPosts.append(formPostData)
    }

    func urlRequestForNavigationAction(_ navigationAction: WKNavigationAction) -> URLRequest {
        guard let formPostData = blankTargetFormPosts.first(where: { $0.matchesNavigationAction(navigationAction) }) else {
            return navigationAction.request
        }
        
        let request = formPostData.urlRequestWithHeaders(navigationAction.request.allHTTPHeaderFields)
        
        if let index = blankTargetFormPosts.index(where: { $0.matchesNavigationAction(navigationAction) }) {
            blankTargetFormPosts.remove(at: index)
        }
        
        return request
    }
}

