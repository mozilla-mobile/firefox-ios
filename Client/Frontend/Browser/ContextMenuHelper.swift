/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol ContextMenuHelperDelegate: class {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UILongPressGestureRecognizer)
}

class ContextMenuHelper: NSObject, TabHelper, UIGestureRecognizerDelegate {
    fileprivate weak var tab: Tab?
    weak var delegate: ContextMenuHelperDelegate?
    fileprivate let gestureRecognizer = UILongPressGestureRecognizer()
    fileprivate weak var selectionGestureRecognizer: UIGestureRecognizer?

    struct Elements {
        let link: URL?
        let image: URL?
    }

    class func name() -> String {
        return "ContextMenuHelper"
    }

    /// Clicking an element with VoiceOver fires touchstart, but not touchend, causing the context
    /// menu to appear when it shouldn't (filed as rdar://22256909). As a workaround, disable the custom
    /// context menu for VoiceOver users.
    fileprivate var showCustomContextMenu: Bool {
        return !UIAccessibilityIsVoiceOverRunning()
    }

    required init(tab: Tab) {
        super.init()
        self.tab = tab

        let path = Bundle.main.path(forResource: "ContextMenu", ofType: "js")!
        let source = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        tab.webView!.configuration.userContentController.addUserScript(userScript)

        // Add a gesture recognizer that disables the built-in context menu gesture recognizer.
        gestureRecognizer.delegate = self
        tab.webView!.addGestureRecognizer(gestureRecognizer)
    }

    func scriptMessageHandlerName() -> String? {
        return "contextMenuMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if !showCustomContextMenu {
            return
        }

        let data = message.body as! [String: AnyObject]

        // On sites where <a> elements have child text elements, the text selection delegate can be triggered
        // when we show a context menu. To prevent this, cancel the text selection delegate if we know the
        // user is long-pressing a link.
        if let handled = data["handled"] as? Bool, handled {
            // Setting `enabled = false` cancels the current gesture for this recognizer.
            selectionGestureRecognizer?.isEnabled = false
            selectionGestureRecognizer?.isEnabled = true
        }

        var linkURL: URL?
        if let urlString = data["link"] as? String {
            linkURL = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.URLAllowedCharacterSet())!)
        }

        var imageURL: URL?
        if let urlString = data["image"] as? String {
            imageURL = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.URLAllowedCharacterSet())!)
        }

        if linkURL != nil || imageURL != nil {
            let elements = Elements(link: linkURL, image: imageURL)
            delegate?.contextMenuHelper(self, didLongPressElements: elements, gestureRecognizer: gestureRecognizer)
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Hack to detect the built-in text selection gesture recognizer.
        if let otherDelegate = otherGestureRecognizer.delegate, String(describing: otherDelegate).contains("_UIKeyboardBasedNonEditableTextSelectionGestureController") {
            selectionGestureRecognizer = otherGestureRecognizer
        }

        // Hack to detect the built-in context menu gesture recognizer.
        return otherGestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer.delegate?.description.range(of: "WKContentView") != nil
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return showCustomContextMenu
    }
}
