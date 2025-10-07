// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit

public protocol WKJavascriptPromptAlertControllerDelegate: AnyObject {
    @MainActor
    func promptAlertControllerDidDismiss(_ alertController: WKJavaScriptPromptAlertController)
}

public protocol WKJavaScriptPromptAlertController: UIViewController {
    var alertInfo: WKJavaScriptAlertInfo? { get }
    var delegate: WKJavascriptPromptAlertControllerDelegate? { get set }

    func setDismissalResult(_ result: Any?)
}

public enum WKJavaScriptAlertType: String {
    case alert
    case confirm
    case textInput = "text input"
}

public protocol WKJavaScriptAlertInfo {
    var type: WKJavaScriptAlertType { get }

    @MainActor
    func alertController() -> WKJavaScriptPromptAlertController
    func cancel()
    func handleAlertDismissal(_ result: Any?)
}

@MainActor
public protocol WKJavaScriptAlertStore {
    var popupThrottler: PopupThrottler { get }

    func cancelQueuedAlerts()

    func queueJavascriptAlertPrompt(_ alert: WKJavaScriptAlertInfo)

    func dequeueJavascriptAlertPrompt() -> WKJavaScriptAlertInfo?

    func hasJavascriptAlertPrompt() -> Bool
}

@MainActor
public protocol WKJavaScriptAlertInfoFactory {
    func makeMessageAlert(
        message: String,
        frame: WKFrameInfo,
        completion: @escaping @MainActor () -> Void
    ) -> WKJavaScriptAlertInfo
    
    func makeConfirmationAlert(
        message: String,
        frame: WKFrameInfo,
        completion: @escaping @MainActor (Bool) -> Void
    ) -> WKJavaScriptAlertInfo
    
    func makeTextInputAlert(
        message: String,
        frame: WKFrameInfo,
        defaultText: String?,
        completion: @escaping @MainActor (String?) -> Void
    ) -> WKJavaScriptAlertInfo
}
