/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import UIKit

enum LongPressElementType {
    case Image
    case Link
}

protocol LongPressGestureDelegate: class {
    func longPressRecognizer(longPressRecognizer: LongPressGestureRecognizer, didLongPressElements elements: [LongPressElementType: NSURL])
}

class LongPressGestureRecognizer: UILongPressGestureRecognizer, UIGestureRecognizerDelegate, BrowserHelper {
    private weak var browser: Browser!
    weak var longPressGestureDelegate: LongPressGestureDelegate?

    override init(target: AnyObject, action: Selector) {
        super.init(target: target, action: action)
    }

    required init?(browser: Browser) {
        super.init()
        self.browser = browser
        delegate = self
        self.minimumPressDuration *= 0.9
        self.addTarget(self, action: "SELdidLongPress:")

        if let path = NSBundle.mainBundle().pathForResource("LongPress", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
                self.browser.webView.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    // MARK: - Gesture Recognizer Delegate Methods
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - Long Press Gesture Handling
    func SELdidLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            //Finding actual touch location in webView
            var touchLocation = gestureRecognizer.locationInView(self.browser.webView)
            touchLocation.x -= self.browser.webView.scrollView.contentInset.left
            touchLocation.y -= self.browser.webView.scrollView.contentInset.top
            touchLocation.x /= self.browser.webView.scrollView.zoomScale
            touchLocation.y /= self.browser.webView.scrollView.zoomScale

            self.browser.webView.evaluateJavaScript("findElementsAtPoint(\(touchLocation.x),\(touchLocation.y))", completionHandler:nil)
        }
    }

    /// Recursively call block on view and its subviews
    private func recursiveBlockOnViewAndSubviews(mainView: UIView, block:(view: UIView) -> Void) {
        block(view: mainView)
        mainView.subviews.map(){ self.recursiveBlockOnViewAndSubviews($0 as UIView, block) }
    }

    /// Find location in screen corresponding to webview - in case it is zoomed or scrolled
    private func rectLocationInWebView(webView:WKWebView,locationRect:CGRect) -> CGRect {
        var rect = locationRect
        var scale = self.browser.webView.scrollView.zoomScale
        rect.origin.x *= scale
        rect.origin.y *= scale
        rect.size.width *= scale
        rect.size.height *= scale
        rect.origin.x += self.browser.webView.scrollView.contentInset.left;
        rect.origin.y += self.browser.webView.scrollView.contentInset.top;

        return rect
    }

    // MARK: - BrowserHelper Mehods
    class func name() -> String {
        return "BrowserLongPressGestureRecognizer"
    }

    func scriptMessageHandlerName() -> String? {
        return "longPressMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        var elementsDict: [String: AnyObject]? = message.body as? [String: AnyObject]
        if elementsDict == nil {
            return
        }

        var elements = [LongPressElementType: NSURL]()
        if let hrefElement = elementsDict!["hrefElement"] as? [String: String] {
            if let hrefStr: String = hrefElement["hrefLink"] {
                if let linkURL = NSURL(string: hrefStr) {
                    elements[LongPressElementType.Link] = linkURL
                }
            }
        }
        if let imageElement = elementsDict!["imageElement"] as? [String: String] {
            if let imageSrcStr: String = imageElement["imageSrc"] {
                if let imageURL = NSURL(string: imageSrcStr) {
                    elements[LongPressElementType.Image] = imageURL
                }
            }
        }

        if elements.count > 0 {
            var disableGestures: [UIGestureRecognizer] = []
            self.recursiveBlockOnViewAndSubviews(self.browser.webView) { view in
                if let gestureRecognizers = view.gestureRecognizers as? [UIGestureRecognizer] {
                    for g in gestureRecognizers {
                        if g != self && g.enabled == true {
                            g.enabled = false
                            disableGestures.append(g)
                        }
                    }
                }
            }

            self.longPressGestureDelegate?.longPressRecognizer(self, didLongPressElements: elements)
            disableGestures.map({ $0.enabled = true })
        }
    }
}