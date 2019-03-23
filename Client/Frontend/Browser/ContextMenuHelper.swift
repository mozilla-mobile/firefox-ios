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
    private var kvoInfo: (layer: CALayer?, observation: NSKeyValueObservation?) = (nil, nil)

    required init(tab: Tab) {
        super.init()
        self.tab = tab
    }

    func uninstall() {
        kvoInfo.observation?.invalidate()
    }

    // BVC KVO events for all changes on the webview will call this. It is called a lot during a page load.
    func replaceGestureHandlerIfNeeded() {
        // If the main layer changes, re-install KVO observation.
        // It seems the main layer changes only once after intialization of the webview,
        // so the if condition only runs twice.

        guard let scrollview = tab?.webView?.scrollView else { return }
        let wkContentView = scrollview.subviews.first { String(describing: $0).hasPrefix("<WKContentView") }
        guard let layer = wkContentView?.layer, layer != kvoInfo.layer else {
            return
        }

        kvoInfo.layer = layer
        kvoInfo.observation = layer.observe(\.bounds) { [weak self] (_, _) in
            // The layer bounds updates when the document context (and gestures) have been setup
            if self?.gestureRecognizerWithDescriptionFragment("ContextMenuHelper") == nil {
                self?.replaceWebViewLongPress()
            }
        }
    }

    private func replaceWebViewLongPress() {
        // WebKit installs gesture handlers async. If `replaceWebViewLongPress` is called after a wkwebview in most cases a small delay is sufficient
        // See also https://bugs.webkit.org/show_bug.cgi?id=193366

        nativeHighlightLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_highlightLongPressRecognized:")

        if let nativeLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_longPressRecognized:") {
            nativeLongPressRecognizer.removeTarget(nil, action: nil)
            nativeLongPressRecognizer.addTarget(self, action: #selector(self.longPressGestureDetected))
        }
    }

    func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String) -> UILongPressGestureRecognizer? {
        let result = tab?.webView?.scrollView.subviews.compactMap({ $0.gestureRecognizers }).joined().first(where: {
            (($0 as? UILongPressGestureRecognizer) != nil) && $0.description.contains(descriptionFragment)
        })
        return result as? UILongPressGestureRecognizer
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
