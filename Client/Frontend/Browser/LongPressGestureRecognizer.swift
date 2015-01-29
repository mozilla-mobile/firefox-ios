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

class LongPressGestureRecognizer: UILongPressGestureRecognizer, UIGestureRecognizerDelegate {
    private weak var webView: WKWebView!
    weak var longPressGestureDelegate: LongPressGestureDelegate?

    override init(target: AnyObject, action: Selector) {
        super.init(target: target, action: action)
    }

    required init?(webView: WKWebView) {
        super.init()
        self.webView = webView
        delegate = self
        self.minimumPressDuration *= 0.9
        self.addTarget(self, action: "SELdidLongPress:")

        if let path = NSBundle.mainBundle().pathForResource("LongPress", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
                self.webView.configuration.userContentController.addUserScript(userScript)
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
            var touchLocation = gestureRecognizer.locationInView(self.webView)
            touchLocation.x -= self.webView.scrollView.contentInset.left
            touchLocation.y -= self.webView.scrollView.contentInset.top
            touchLocation.x /= self.webView.scrollView.zoomScale
            touchLocation.y /= self.webView.scrollView.zoomScale

            self.webView.evaluateJavaScript("findElementsAtPoint(\(touchLocation.x),\(touchLocation.y))") { (response: AnyObject!, error: NSError!) in
                if error != nil {
                    println("Long press gesture recognizer error: \(error.description)")
                } else {
                    self.handleTouchResult(response as [String: AnyObject])
                }
            }
        }
    }

    /// Recursively call block on view and its subviews
    private func recursiveBlockOnViewAndSubviews(mainView: UIView, block:(view: UIView) -> Void) {
        block(view: mainView)
        mainView.subviews.map(){ self.recursiveBlockOnViewAndSubviews($0 as UIView, block) }
    }

    private func handleTouchResult(elementsDict: [String: AnyObject]) {
        var elements = [LongPressElementType: NSURL]()
        if let hrefElement = elementsDict["hrefElement"] as? [String: String] {
            if let hrefStr: String = hrefElement["hrefLink"] {
                if let linkURL = NSURL(string: hrefStr) {
                    elements[LongPressElementType.Link] = linkURL
                }
            }
        }
        if let imageElement = elementsDict["imageElement"] as? [String: String] {
            if let imageSrcStr: String = imageElement["imageSrc"] {
                if let imageURL = NSURL(string: imageSrcStr) {
                    elements[LongPressElementType.Image] = imageURL
                }
            }
        }

        if elements.count > 0 {
            var disableGestures: [UIGestureRecognizer] = []
            self.recursiveBlockOnViewAndSubviews(self.webView) { view in
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