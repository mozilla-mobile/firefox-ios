// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit

protocol WKJavaScriptAlertInfo {
    @MainActor
    func alertController() -> WKJavaScriptPromptAlertController
    func cancel()
    func handleAlertDismissal(_ result: Any?)
}

protocol WKJavaScriptAlertProtocol {
    static var alertType: String { get }
}

struct MessageAlert: WKJavaScriptAlertInfo {
    let message: String
    let frame: WKFrameInfo
    let completionHandler: () -> Void
    var logger: Logger = DefaultLogger.shared

    func alertController() -> WKJavaScriptPromptAlertController {
        let alertController = WKJavaScriptPromptAlertController(
            title: titleForJavaScriptPanelInitiatedByFrame(frame),
            message: message,
            alertInfo: self
        )
        alertController.addAction(
            UIAlertAction(title: "Ok", style: .default) { [weak alertController] _ in
                alertController?.setDismissalResult(nil)
                self.completionHandler()
            }
        )
        alertController.alertInfo = self
        return alertController
    }

    func cancel() {
        logger.log("Message alert completion handler called through cancel", level: .info, category: .webview)
        completionHandler()
    }

    func handleAlertDismissal(_ result: Any?) {
        logger.log("Message alert dismissed with no result.", level: .info, category: .webview)
    }
}

struct ConfirmPanelAlert: WKJavaScriptAlertInfo {
    let message: String
    let frame: WKFrameInfo
    let completionHandler: (Bool) -> Void
    var logger: Logger = DefaultLogger.shared

    func alertController() -> WKJavaScriptPromptAlertController {
        let alertController = WKJavaScriptPromptAlertController(
            title: titleForJavaScriptPanelInitiatedByFrame(frame),
            message: message,
            alertInfo: self
        )

        alertController.addAction(UIAlertAction(title: "Ok", style: .default) { _ in
            alertController.setDismissalResult(true)
            self.completionHandler(true)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.setDismissalResult(false)
            self.completionHandler(false)
        })
        return alertController
    }

    func cancel() {
        logger.log("Confirm panel alert completion handler called through cancel", level: .info, category: .webview)
        completionHandler(false)
    }

    func handleAlertDismissal(_ result: Any?) {
        if (result as? Bool) != nil {
            logger.log("Confirm alert dismissed with result.", level: .info, category: .webview)
        } else {
            logger.log("Confirm alert dismissed with no result.", level: .info, category: .webview)
        }
    }
}

struct TextInputAlert: WKJavaScriptAlertInfo {
    let message: String
    let frame: WKFrameInfo
    let defaultText: String?
    let completionHandler: (String?) -> Void
    var logger: Logger = DefaultLogger.shared

    func alertController() -> WKJavaScriptPromptAlertController {
        let alertController = WKJavaScriptPromptAlertController(
            title: titleForJavaScriptPanelInitiatedByFrame(frame),
            message: message,
            alertInfo: self
        )

        alertController.addTextField { textField in
            textField.text = self.defaultText
        }

        // TODO: - Strings localized
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let result = alertController.textFields?.first?.text
            alertController.setDismissalResult(result)
            self.completionHandler(result)
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.setDismissalResult(nil)
            self.completionHandler(nil)
        })

        alertController.alertInfo = self
        return alertController
    }

    func cancel() {
        logger.log("Text input alert completion handler called through cancel", level: .info, category: .webview)
        completionHandler(nil)
    }

    func handleAlertDismissal(_ result: Any?) {
        if (result as? String) != nil {
            logger.log("Text input alert dismissed with input.", level: .info, category: .webview)
        } else {
            logger.log("Text input alert dismissed with no input.", level: .info, category: .webview)
        }
    }
}

// MARK: - Alert Type Extensions
extension MessageAlert: WKJavaScriptAlertProtocol {
    static var alertType: String { "alert" }
}

extension ConfirmPanelAlert: WKJavaScriptAlertProtocol {
    static var alertType: String { "confirm" }
}

extension TextInputAlert: WKJavaScriptAlertProtocol {
    static var alertType: String { "text input" }
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
