/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol ContextMenuHelperDelegate: class {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UIGestureRecognizer)
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didCancelGestureRecognizer: UIGestureRecognizer)
}

class ContextMenuHelper: NSObject {
    struct Elements {
        let link: URL?
        let image: URL?
    }

    fileprivate weak var tab: Tab?

    weak var delegate: ContextMenuHelperDelegate?

    fileprivate var nativeHighlightLongPressRecognizer: UILongPressGestureRecognizer?
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

        nativeHighlightLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_highlightLongPressRecognized:") as? UILongPressGestureRecognizer

        if let nativeLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_longPressRecognized:") as? UILongPressGestureRecognizer {
            nativeLongPressRecognizer.removeTarget(nil, action: nil)
            nativeLongPressRecognizer.addTarget(self, action: #selector(longPressGestureDetected(_:)))
        }
    }

    func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String) -> UIGestureRecognizer? {
        return tab?.webView?.scrollView.subviews.flatMap({ $0.gestureRecognizers }).joined().first(where: { $0.description.contains(descriptionFragment) })
    }

    func longPressGestureDetected(_ sender: UIGestureRecognizer) {
        if sender.state == .cancelled {
            delegate?.contextMenuHelper(self, didCancelGestureRecognizer: sender)
            return
        }

        guard sender.state == .began, let elements = self.elements else {
            return
        }

        delegate?.contextMenuHelper(self, didLongPressElements: elements, gestureRecognizer: sender)

        // To prevent the tapped link from proceeding with navigation, "cancel" the native WKWebView
        // `_highlightLongPressRecognizer`. This preserves the original behavior as seen here:
        // https://github.com/WebKit/webkit/blob/d591647baf54b4b300ca5501c21a68455429e182/Source/WebKit/UIProcess/ios/WKContentViewInteraction.mm#L1600-L1614
        if let nativeHighlightLongPressRecognizer = self.nativeHighlightLongPressRecognizer,
            nativeHighlightLongPressRecognizer.isEnabled {
            nativeHighlightLongPressRecognizer.isEnabled = false
            nativeHighlightLongPressRecognizer.isEnabled = true
        }

        self.elements = nil
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
        guard let data = message.body as? [String: AnyObject] else {
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
