/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol ContextMenuHelperDelegate: class {
    func contextMenuHelper(contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UILongPressGestureRecognizer)
}

class ContextMenuHelper: NSObject, BrowserHelper, UIGestureRecognizerDelegate {
    private weak var browser: Browser?
    weak var delegate: ContextMenuHelperDelegate?
    private let gestureRecognizer = UILongPressGestureRecognizer()

    struct Elements {
        let link: NSURL?
        let image: NSURL?
    }

    class func name() -> String {
        return "ContextMenuHelper"
    }

    required init(browser: Browser) {
        super.init()
        self.browser = browser

        let path = NSBundle.mainBundle().pathForResource("ContextMenu", ofType: "js")!
        let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as! String
        let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
        browser.webView.configuration.userContentController.addUserScript(userScript)

        // Add a gesture recognizer that disables the built-in context menu gesture recognizer.
        gestureRecognizer.delegate = self
        browser.webView.addGestureRecognizer(gestureRecognizer)
    }

    func scriptMessageHandlerName() -> String? {
        return "contextMenuMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let data = message.body as! [String: String]

        var linkURL: NSURL?
        if let urlString = data["link"] {
            linkURL = NSURL(string: urlString)
        }

        var imageURL: NSURL?
        if let urlString = data["image"] {
            imageURL = NSURL(string: urlString)
        }

        if linkURL != nil || imageURL != nil {
            let elements = Elements(link: linkURL, image: imageURL)
            delegate?.contextMenuHelper(self, didLongPressElements: elements, gestureRecognizer: gestureRecognizer)
        }
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Hack to detect the built-in context menu gesture recognizer.
        return otherGestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer.delegate?.description.rangeOfString("WKContentView") != nil
    }
}