// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol WKJavascriptPromptAlertControllerDelegate: AnyObject {
    @MainActor
    func promptAlertControllerDidDismiss(_ alertController: WKJavaScriptPromptAlertController)
}

@MainActor
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
