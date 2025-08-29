// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
public protocol AccessibilityActionsSource: AnyObject {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]?
}

public final class AccessibleAction {
    public let name: String
    public let handler: () -> Bool

    public init(name: String, handler: @escaping () -> Bool) {
        self.name = name
        self.handler = handler
    }

    @MainActor
    public var accessibilityCustomAction: UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: name, target: self, selector: #selector(performAccessibilityAction))
    }

    @objc
    private func performAccessibilityAction() -> Bool {
        return handler()
    }
}
