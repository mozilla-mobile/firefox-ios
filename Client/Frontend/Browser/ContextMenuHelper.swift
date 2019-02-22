/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol ContextMenuHelperDelegate: AnyObject {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UIGestureRecognizer)
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didCancelGestureRecognizer: UIGestureRecognizer)
}

class ContextMenuHelper: NSObject {
    struct Elements {
        let link: URL?
        let image: URL?
        let title: String?
        let alt: String?
    }

    fileprivate weak var tab: Tab?

    weak var delegate: ContextMenuHelperDelegate?

    fileprivate var nativeHighlightLongPressRecognizer: UILongPressGestureRecognizer?
    fileprivate var elements: Elements?

    required init(tab: Tab) {
        super.init()
        self.tab = tab
    }

    func replaceWebViewLongPress() {
        // WebKit installs gesture handlers async. If `replaceWebViewLongPress` is called after a wkwebview in most cases a small delay is sufficient
        // See also https://bugs.webkit.org/show_bug.cgi?id=193366
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard self.gestureRecognizerWithDescriptionFragment("ContextMenuHelper") == nil else {
                return
            }

            self.nativeHighlightLongPressRecognizer = self.gestureRecognizerWithDescriptionFragment("action=_highlightLongPressRecognized:") as? UILongPressGestureRecognizer

            if let nativeLongPressRecognizer = self.gestureRecognizerWithDescriptionFragment("action=_longPressRecognized:") as? UILongPressGestureRecognizer {
                nativeLongPressRecognizer.removeTarget(nil, action: nil)
                nativeLongPressRecognizer.addTarget(self, action: #selector(self.longPressGestureDetected))
            } else {
                // The ContextMenuHelper gesture hook is not installed yet, try again
                self.replaceWebViewLongPress()
            }
        }
    }

    func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String) -> UIGestureRecognizer? {
        return tab?.webView?.scrollView.subviews.compactMap({ $0.gestureRecognizers }).joined().first(where: { $0.description.contains(descriptionFragment) })
    }

    @objc func longPressGestureDetected(_ sender: UIGestureRecognizer) {
        if sender.state == .cancelled {
            delegate?.contextMenuHelper(self, didCancelGestureRecognizer: sender)
            return
        }

        guard sender.state == .began else {
            return
        }

        // To prevent the tapped link from proceeding with navigation, "cancel" the native WKWebView
        // `_highlightLongPressRecognizer`. This preserves the original behavior as seen here:
        // https://github.com/WebKit/webkit/blob/d591647baf54b4b300ca5501c21a68455429e182/Source/WebKit/UIProcess/ios/WKContentViewInteraction.mm#L1600-L1614
        if let nativeHighlightLongPressRecognizer = self.nativeHighlightLongPressRecognizer,
            nativeHighlightLongPressRecognizer.isEnabled {
            nativeHighlightLongPressRecognizer.isEnabled = false
            nativeHighlightLongPressRecognizer.isEnabled = true
        }

        if let elements = self.elements {
            delegate?.contextMenuHelper(self, didLongPressElements: elements, gestureRecognizer: sender)

            self.elements = nil
        }
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
                let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .URLAllowed) {
            linkURL = URL(string: escapedURLString)
        }

        var imageURL: URL?
        if let urlString = data["image"] as? String,
                let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .URLAllowed) {
            imageURL = URL(string: escapedURLString)
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
