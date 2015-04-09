/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

enum LongPressElementType {
    case Image
    case Link
}

protocol LongPressDelegate: class {
    func longPressBrowserHelper(longPressBrowserHelper: LongPressBrowserHelper, didLongPressElements elements: [LongPressElementType: NSURL])
}

private let URLCharacterSet = NSCharacterSet(charactersInString: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%")

class LongPressBrowserHelper: NSObject, BrowserHelper, UIGestureRecognizerDelegate {
    weak var delegate: LongPressDelegate?
    private weak var browser: Browser?
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    class func name() -> String {
        return "LongPressBrowserHelper"
    }
    
    required init(browser: Browser) {
        super.init()
        
        self.browser = browser        
        
        if let path = NSBundle.mainBundle().pathForResource("LongPress", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: false)
                browser.webView.configuration.userContentController.addUserScript(userScript)
            }
        }

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "SELdidLongPress:")
        longPressGestureRecognizer.delegate = self
        browser.webView.addGestureRecognizer(longPressGestureRecognizer)
    }

    func scriptMessageHandlerName() -> String? {
        return "longPressMessageHandler"
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UILongPressGestureRecognizer
            && otherGestureRecognizer.delegate?.description.rangeOfString("WKContentView") != nil
    }
    
    func SELdidLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if let webView = browser?.webView {
            if gestureRecognizer.state == UIGestureRecognizerState.Began {
                //Finding actual touch location in webView
                var touchLocation = gestureRecognizer.locationInView(webView)
                touchLocation.x -= webView.scrollView.contentInset.left
                touchLocation.y -= webView.scrollView.contentInset.top
                touchLocation.x /= webView.scrollView.zoomScale
                touchLocation.y /= webView.scrollView.zoomScale

                webView.evaluateJavaScript("__firefox__.LongPress.findElementsAtPoint(\(touchLocation.x),\(touchLocation.y))") { (response: AnyObject!, error: NSError!) in
                    if error != nil {
                        println("Long press gesture recognizer error: \(error.description)")
                    } else {
                        self.handleTouchResult(response as! [String: AnyObject])
                    }
                }
            }
        }
    }
    
    private func handleTouchResult(elementsDict: [String: AnyObject]) {
        var elements = [LongPressElementType: NSURL]()
        if let hrefElement = elementsDict["hrefElement"] as? [String: String] {
            if let hrefStr: String = hrefElement["hrefLink"] {
                if let encodedString = hrefStr.stringByAddingPercentEncodingWithAllowedCharacters(URLCharacterSet) {
                    if let linkURL = NSURL(string: encodedString) {
                        elements[LongPressElementType.Link] = linkURL
                    }
                }
            }
        }
        if let imageElement = elementsDict["imageElement"] as? [String: String] {
            if let imageSrcStr: String = imageElement["imageSrc"] {
                if let encodedString = imageSrcStr.stringByAddingPercentEncodingWithAllowedCharacters(URLCharacterSet) {
                    if let imageURL = NSURL(string: encodedString) {
                        elements[LongPressElementType.Image] = imageURL
                    }
                }
            }
        }
        
        if !elements.isEmpty {
            delegate?.longPressBrowserHelper(self, didLongPressElements: elements)
        }
    }    
}