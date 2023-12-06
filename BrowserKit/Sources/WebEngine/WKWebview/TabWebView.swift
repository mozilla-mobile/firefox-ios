// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

protocol TabWebViewDelegate: AnyObject {
    func tabWebView(_ tabWebView: TabWebView,
                    didSelectFindInPageForSelection selection: String)
    func tabWebViewSearchWithFirefox(_ tabWebViewSearchWithFirefox: TabWebView,
                                     didSelectSearchWithFirefoxForSelection selection: String)
}

// TODO: FXIOS-7895 #17640 Handle TabWebView MenuHelperInterface
// TODO: FXIOS-7896 #17641 Handle TabWebView ThemeApplicable
// TODO: FXIOS-7897 #17642 Handle TabWebView AccessoryViewProvider
class TabWebView: WKWebView {
    private var logger: Logger = DefaultLogger.shared
    private weak var delegate: TabWebViewDelegate?

    func configure(delegate: TabWebViewDelegate,
                   navigationDelegate: WKNavigationDelegate?) {
        self.delegate = delegate
        self.navigationDelegate = navigationDelegate
    }

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func menuHelperFindInPage() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebView(self, didSelectFindInPageForSelection: selection)
        }
    }

    func menuHelperSearchWithFirefox() {
        evaluateJavascriptInDefaultContentWorld("getSelection().toString()") { result, _ in
            let selection = result as? String ?? ""
            self.delegate?.tabWebViewSearchWithFirefox(self, didSelectSearchWithFirefoxForSelection: selection)
        }
    }

    override internal func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // The find-in-page selection menu only appears if the webview is the first responder.
        // Do not becomeFirstResponder on a mouse event.
        if let event = event, event.allTouches?.contains(where: { $0.type != .indirectPointer }) ?? false {
            becomeFirstResponder()
        }
        return super.hitTest(point, with: event)
    }

    /// Override evaluateJavascript - should not be called directly on TabWebViews any longer
    /// We should only be calling evaluateJavascriptInDefaultContentWorld
    @available(*,
                unavailable,
                message: "Do not call evaluateJavaScript directly on TabWebViews")
    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        super.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}
