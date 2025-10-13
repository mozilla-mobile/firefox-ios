// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import WebEngine

class MockWKJavaScriptPromptAlertController: UIViewController, WKJavaScriptPromptAlertController {
    var alertInfo: (any WKJavaScriptAlertInfo)?
    weak var delegate: (any WKJavascriptPromptAlertControllerDelegate)?
    var setDismissalResultCalled = 0

    func setDismissalResult(_ result: Any?) {
        setDismissalResultCalled += 1
    }
}

class MockWKJavaScriptAlertInfo: WKJavaScriptAlertInfo {
    let type: WKJavaScriptAlertType
    var alertControllerCalled = 0
    var cancelCalled = 0
    var handleAlertDismissalCalled = 0
    let controller = MockWKJavaScriptPromptAlertController()

    init(type: WKJavaScriptAlertType) {
        self.type = type
    }

    func alertController() -> any WKJavaScriptPromptAlertController {
        alertControllerCalled += 1
        return controller
    }

    func cancel() {
        cancelCalled += 1
    }

    func handleAlertDismissal(_ result: Any?) {
        handleAlertDismissalCalled += 1
    }
}

class MockWKJavaScriptAlertFactory: WKJavaScriptAlertInfoFactory {
    var stubAlert = MockWKJavaScriptAlertInfo(type: .alert)
    var makeMessageAlertCalled = 0
    var makeConfirmationAlertCalled = 0
    var makeTextInputAlertCalled = 0

    func makeMessageAlert(
        message: String,
        frame: WKFrameInfo,
        completion: @escaping @MainActor () -> Void
    ) -> any WKJavaScriptAlertInfo {
        makeMessageAlertCalled += 1
        return stubAlert
    }

    func makeConfirmationAlert(
        message: String,
        frame: WKFrameInfo,
        completion: @escaping @MainActor (Bool) -> Void
    ) -> any WKJavaScriptAlertInfo {
        makeConfirmationAlertCalled += 1
        return stubAlert
    }

    func makeTextInputAlert(
        message: String,
        frame: WKFrameInfo,
        defaultText: String?,
        completion: @escaping @MainActor (String?) -> Void
    ) -> any WKJavaScriptAlertInfo {
        makeTextInputAlertCalled += 1
        return stubAlert
    }
}
