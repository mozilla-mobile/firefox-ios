// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import WebEngine

/// A note on async handling of JavaScript alerts: WebKit expects your app to present the alert and await user interaction
/// before returning. Meanwhile, the web page will pause JavaScript execution until the method execution ends. If the
/// `WKNavigationDelegate` JS alert async methods return prematurely, the web page may resume early, leading to incorrect
/// behavior.
/// Previously we used the `WKNavigationDelegate` JS alert methods with `completionHandler`s. Failing to call the
/// `completionHandler` would crash the app with a runtime exception. We've replace them with `continuation`s to
/// work with the async methods from WKWebView delegate.
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
            // Call the continuation if it wasn't handled yet
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
    var continuation: CheckedContinuation<Void?, Never>?
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
        logger.log("Message alert continuation called through cancel", level: .info, category: .webview)
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
    var continuation: CheckedContinuation<Bool, Never>?
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
        logger.log("Confirm panel alert continuation called through cancel", level: .info, category: .webview)
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
    var continuation: CheckedContinuation<String?, Never>?
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
        logger.log("Text input alert continuation called through cancel", level: .info, category: .webview)
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
