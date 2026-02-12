// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol JavascriptPromptAlertControllerDelegate: AnyObject {
    @MainActor
    func promptAlertControllerDidDismiss(_ alertController: JavaScriptPromptAlertController)
}

@MainActor
public protocol JavaScriptPromptAlertController: UIViewController {
    var alertInfo: JavaScriptAlertInfo? { get }
    var delegate: JavascriptPromptAlertControllerDelegate? { get set }

    func setDismissalResult(_ result: Any?)
}

public enum JavaScriptAlertType: String {
    case alert
    case confirm
    case textInput = "text input"
}

public protocol JavaScriptAlertInfo {
    var type: JavaScriptAlertType { get }

    @MainActor
    func alertController() -> JavaScriptPromptAlertController
    func cancel()
    func handleAlertDismissal(_ result: Any?)
}
