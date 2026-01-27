// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import WebEngine

/// A simple version of UIAlertController that attaches a delegate to the viewDidDisappear method
/// to allow forwarding the event. The reason this is needed for prompts from Javascript is we
/// need to invoke the completionHandler passed to us from the WKWebView delegate or else
/// a runtime exception is thrown.
class JSPromptAlertController: UIAlertController, JavaScriptPromptAlertController {
    var alertInfo: JavaScriptAlertInfo?
    weak var delegate: JavascriptPromptAlertControllerDelegate?
    private var handledAction = false
    private var dismissalResult: Any?

    convenience init(
        title: String?,
        message: String?,
        preferredStyle: UIAlertController.Style = .alert,
        alertInfo: JavaScriptAlertInfo
    ) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        self.alertInfo = alertInfo
    }

    /// Set the result to pass during dismissal
    func setDismissalResult(_ result: Any?) {
        handledAction = true
        dismissalResult = result
    }

    override func viewDidDisappear(_ animated: Bool) {
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

struct MessageAlert: JavaScriptAlertInfo {
    let type: JavaScriptAlertType = .alert
    let message: String
    let frame: WKFrameInfo
    var continuation: CheckedContinuation<Any?, Never>?
    var logger: Logger = DefaultLogger.shared

    func alertController() -> JavaScriptPromptAlertController {
        let alertController = JSPromptAlertController(
            title: titleForJavaScriptPanelInitiatedByFrame(frame),
            message: message,
            alertInfo: self
        )
        alertController.addAction(
            UIAlertAction(title: .OKString, style: .default) { [weak alertController] _ in
                alertController?.setDismissalResult(nil)
                self.continuation?.resume(returning: nil)
            }
        )
        alertController.alertInfo = self
        return alertController
    }

    func cancel() {
        logger.log("Message alert completion handler called through cancel", level: .info, category: .webview)
        self.continuation?.resume(returning: nil)
    }

    func handleAlertDismissal(_ result: Any?) {
        logger.log("Message alert dismissed with no result.", level: .info, category: .webview)
    }
}

struct ConfirmPanelAlert: JavaScriptAlertInfo {
    let type: JavaScriptAlertType = .confirm
    let message: String
    let frame: WKFrameInfo
    var continuation: CheckedContinuation<Any?, Never>?
    var logger: Logger = DefaultLogger.shared

    func alertController() -> JavaScriptPromptAlertController {
        let alertController = JSPromptAlertController(
            title: titleForJavaScriptPanelInitiatedByFrame(frame),
            message: message,
            alertInfo: self
        )

        alertController.addAction(UIAlertAction(title: .OKString, style: .default) { _ in
            alertController.setDismissalResult(true)
            self.continuation?.resume(returning: true)
        })
        alertController.addAction(UIAlertAction(title: .CancelString, style: .cancel) { _ in
            alertController.setDismissalResult(false)
            self.continuation?.resume(returning: false)
        })
        return alertController
    }

    func cancel() {
        logger.log("Confirm panel alert completion handler called through cancel", level: .info, category: .webview)
        continuation?.resume(returning: false)
    }

    func handleAlertDismissal(_ result: Any?) {
        if (result as? Bool) != nil {
            logger.log("Confirm alert dismissed with result.", level: .info, category: .webview)
        } else {
            logger.log("Confirm alert dismissed with no result.", level: .info, category: .webview)
        }
    }
}

struct TextInputAlert: JavaScriptAlertInfo {
    let type: JavaScriptAlertType = .textInput
    let message: String
    let frame: WKFrameInfo
    let defaultText: String?
    var continuation: CheckedContinuation<Any?, Never>?
    var logger: Logger = DefaultLogger.shared

    func alertController() -> JavaScriptPromptAlertController {
        let alertController = JSPromptAlertController(
            title: titleForJavaScriptPanelInitiatedByFrame(frame),
            message: message,
            alertInfo: self
        )

        alertController.addTextField { textField in
            textField.text = self.defaultText
        }

        alertController.addAction(UIAlertAction(title: .OKString, style: .default) { _ in
            let result = alertController.textFields?.first?.text
            alertController.setDismissalResult(result)
            self.continuation?.resume(returning: result)
        })

        alertController.addAction(UIAlertAction(title: .CancelString, style: .cancel) { _ in
            alertController.setDismissalResult(nil)
            self.continuation?.resume(returning: nil)
        })

        alertController.alertInfo = self
        return alertController
    }

    func cancel() {
        logger.log("Text input alert completion handler called through cancel", level: .info, category: .webview)
        self.continuation?.resume(returning: nil)
    }

    func handleAlertDismissal(_ result: Any?) {
        if (result as? String) != nil {
            logger.log("Text input alert dismissed with input.", level: .info, category: .webview)
        } else {
            logger.log("Text input alert dismissed with no input.", level: .info, category: .webview)
        }
    }
}

/// Show a title for a JavaScript Panel (alert) based on the WKFrameInfo. On iOS9 we will use the new securityOrigin
/// and on iOS 8 we will fall back to the request URL. If the request URL is nil, which happens for JavaScript pages,
/// we fall back to "JavaScript" as a title.
@MainActor
private func titleForJavaScriptPanelInitiatedByFrame(_ frame: WKFrameInfo) -> String {
    var title = "\(frame.securityOrigin.`protocol`)://\(frame.securityOrigin.host)"
    if frame.securityOrigin.port != 0 {
        title += ":\(frame.securityOrigin.port)"
    }
    return title
}
