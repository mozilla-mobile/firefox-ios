/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol ContextMenuHelperDelegate: class {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UIGestureRecognizer)
}

class ContextMenuHelper: NSObject {
    struct Elements {
        let link: URL?
        let image: URL?
    }

    fileprivate weak var tab: Tab?

    weak var delegate: ContextMenuHelperDelegate?

    fileprivate var elements: Elements?

    required init(tab: Tab) {
        super.init()

        self.tab = tab

        guard let path = Bundle.main.path(forResource: "ContextMenu", ofType: "js"),
                let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String,
                let webView = tab.webView else {
            return
        }

        let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)

        if let nativeLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_longPressRecognized:") {
            nativeLongPressRecognizer.removeTarget(nil, action: nil)
            nativeLongPressRecognizer.addTarget(self, action: #selector(longPressGestureDetected(_:)))
        }
    }

    func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String) -> UIGestureRecognizer? {
        return tab?.webView?.scrollView.subviews.flatMap({ $0.gestureRecognizers }).joined().first(where: { $0.description.contains(descriptionFragment) })
    }

    func longPressGestureDetected(_ sender: UIGestureRecognizer) {
        guard sender.state == .began, let elements = self.elements else {
            return
        }

        delegate?.contextMenuHelper(self, didLongPressElements: elements, gestureRecognizer: sender)

        self.elements = nil
    }
}

extension ContextMenuHelper: TabHelper {
    class func name() -> String {
        return "ContextMenuHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "contextMenuMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = message.body as? [String : AnyObject] else {
            return
        }

        var linkURL: URL?
        if let urlString = data["link"] as? String,
                let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.URLAllowedCharacterSet()) {
            linkURL = URL(string: escapedURLString)
        }

        var imageURL: URL?
        if let urlString = data["image"] as? String,
                let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.URLAllowedCharacterSet()) {
            imageURL = URL(string: escapedURLString)
        }

        if linkURL != nil || imageURL != nil {
            elements = Elements(link: linkURL, image: imageURL)
        } else {
            elements = nil
        }
    }
}
