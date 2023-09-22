// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

protocol ContextMenuHelperDelegate: AnyObject {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UIGestureRecognizer)
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didCancelGestureRecognizer: UIGestureRecognizer)
}

class ContextMenuHelper: NSObject {
    var touchPoint = CGPoint()

    struct Elements {
        let link: URL?
        let image: URL?
        let title: String?
        let alt: String?
    }

    fileprivate weak var tab: Tab?

    weak var delegate: ContextMenuHelperDelegate?

    fileprivate(set) var elements: Elements?

    required init(tab: Tab) {
        super.init()
        self.tab = tab
    }
}

extension ContextMenuHelper: TabContentScript {
    class func name() -> String {
        return "ContextMenuHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "contextMenuMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = message.body as? [String: AnyObject] else { return }

        if let x = data["touchX"] as? Double, let y = data["touchY"] as? Double {
            touchPoint = CGPoint(x: x, y: y)
        }

        var linkURL: URL?
        if let urlString = data["link"] as? String,
                let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .URLAllowed) {
            linkURL = URL(string: escapedURLString, encodingInvalidCharacters: false)
        }

        var imageURL: URL?
        if let urlString = data["image"] as? String,
                let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .URLAllowed) {
            imageURL = URL(string: escapedURLString, encodingInvalidCharacters: false)
        }

        if linkURL != nil || imageURL != nil {
            let title = data["title"] as? String
            let alt = data["alt"] as? String
            elements = Elements(link: linkURL, image: imageURL, title: title, alt: alt)
        } else {
            elements = nil
        }
    }
}
