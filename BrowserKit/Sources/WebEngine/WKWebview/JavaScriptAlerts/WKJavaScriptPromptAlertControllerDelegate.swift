// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

@objc
public protocol WKJavaScriptPromptAlertControllerDelegate: AnyObject {
    @MainActor
    func promptAlertControllerDidDismiss(_ alertController: WKJavaScriptPromptAlertController)
}

/// A simple version of UIAlertController that attaches a delegate to the viewDidDisappear method
/// to allow forwarding the event. The reason this is needed for prompts from Javascript is we
/// need to invoke the completionHandler passed to us from the WKWebView delegate or else
/// a runtime exception is thrown.
public class WKJavaScriptPromptAlertController: UIAlertController {
    var alertInfo: WKJavaScriptAlertInfo?
    public weak var delegate: WKJavaScriptPromptAlertControllerDelegate?
    private var handledAction = false
    private var dismissalResult: Any?

    convenience init(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style = .alert,
        alertInfo: WKJavaScriptAlertInfo
    ) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.alertInfo = alertInfo
    }

    /// Set the result to pass during dismissal
    func setDismissalResult(_ result: Any?) {
        handledAction = true
        dismissalResult = result
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // The alert controller is dismissed before the UIAlertAction handler is called so a delay is needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            // Call the dismissal completion handler if it wasn't handled yet
            if !handledAction {
                alertInfo?.cancel()
            }

            // Notify the delegate about dismissal and pass the result
            delegate?.promptAlertControllerDidDismiss(self)

            alertInfo?.handleAlertDismissal(dismissalResult)
        }
    }
}
