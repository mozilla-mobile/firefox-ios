// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Glean

enum KeyboardType: String {
    case `default`
    case custom

    init(identifier: String = "@sw=") {
        self = identifier.contains("@sw=") ? .default : .custom
    }

    private func gleanDescription(identifier: String) -> String {
        self == .default ?
        "Default Keyboard: \(identifier)" :
        "Custom Keyboard: \(identifier)"
    }

    static func identifyKeyboardNameTelemetry() {
        guard UIApplication.textInputMode?.responds(to: NSSelectorFromString("identifier")) == true else { return }
        (UIApplication.textInputMode?.perform(NSSelectorFromString("identifier")).takeUnretainedValue() as? String)
            .map { KeyboardType.init(identifier: $0).gleanDescription(identifier: $0) }
            .map { description in
                GleanMetrics.App.keyboardType.set(description)
            }
    }
}
