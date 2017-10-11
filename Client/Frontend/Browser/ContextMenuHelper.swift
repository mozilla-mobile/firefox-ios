/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol ContextMenuHelperDelegate: class {
    func contextMenuHelper(_ contextMenuHelper: ContextMenuHelper, didLongPressElements elements: ContextMenuHelper.Elements, gestureRecognizer: UILongPressGestureRecognizer)
}

class ContextMenuHelper: NSObject {
    fileprivate weak var tab: Tab?

    weak var delegate: ContextMenuHelperDelegate?

    fileprivate let gestureRecognizer = UILongPressGestureRecognizer()
    fileprivate weak var selectionGestureRecognizer: UIGestureRecognizer?

    struct Elements {
        let link: URL?
        let image: URL?
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

        // Disable the native long-press gesture recognizer to prevent the native WKWebView context
        // menu from appearing.
        if let nativeLongPressRecognizer = gestureRecognizerWithDescriptionFragment("action=_longPressRecognized:") {
            nativeLongPressRecognizer.isEnabled = false
        }

        // Add a gesture recognizer that disables the built-in context menu gesture recognizer.
        // This works by making wkwebview's longpress gestures pass through our gestureRecognizer first.
        // We have to allow textselection gestures to pass through while stopping long press of links.
        gestureRecognizer.delegate = self
        tab.webView!.addGestureRecognizer(gestureRecognizer)
    }

    func gestureRecognizerWithDescriptionFragment(_ descriptionFragment: String) -> UIGestureRecognizer? {
        guard let tab = self.tab else {
            return nil
        }

        guard let webView = tab.webView else {
            return nil
        }

        for subview in webView.scrollView.subviews {
            guard let nativeRecognizers = subview.gestureRecognizers else {
                continue
            }

            if let matchingRecognizer = nativeRecognizers.find({ recognizer -> Bool in
                recognizer.description.contains(descriptionFragment)
            }) {
                return matchingRecognizer
            }
        }

        return nil
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
        if !showCustomContextMenu {
            return
        }

        guard let data = message.body as? [String : AnyObject] else {
            return
        }

        // On sites where <a> elements have child text elements, the text selection delegate can be triggered
        // when we show a context menu. To prevent this, cancel the text selection delegate if we know the
        // user is long-pressing a link.
        if let longPressStarted = data["longPressStarted"] as? Bool, longPressStarted {
            // Setting `enabled = false` cancels the current gesture for this recognizer.
            selectionGestureRecognizer?.isEnabled = false
            selectionGestureRecognizer?.isEnabled = true
        }
        selectionGestureRecognizer = nil

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
}

extension ContextMenuHelper: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // Hack to detect the built-in context menu gesture recognizer.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // On iOS 11 the gestureRecognizer has been renamed. Check for both names.
        let gestureNames = ["_UIKeyboardBasedTextSelectionGestureCluster",
                            "_UIKeyboardBasedNonEditableTextSelectionGestureCluster",
                            "_UIKeyboardBasedNonEditableTextSelectionGestureController"]
        if let otherDelegate = otherGestureRecognizer.delegate, gestureNames.reduce(false, { $0 || String(describing: otherDelegate).contains($1) }) {
            selectionGestureRecognizer = otherGestureRecognizer
        }
        return otherGestureRecognizer.delegate?.description.contains("WKContentView") ?? false
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // If the selection gesture is nil we are likely not trying to select text in the webview.
        return selectionGestureRecognizer == nil && showCustomContextMenu
    }
}
