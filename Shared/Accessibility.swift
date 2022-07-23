// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

public protocol AccessibilityActionsSource: AnyObject {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]?
}

open class AccessibleAction: NSObject {
    public let name: String
    public let handler: () -> Bool

    public init(name: String, handler: @escaping () -> Bool) {
        self.name = name
        self.handler = handler
    }
}

extension AccessibleAction { // UIAccessibilityCustomAction
    @objc private func performAccessibilityAction() -> Bool {
        handler()
    }

    public var accessibilityCustomAction: UIAccessibilityCustomAction {
        UIAccessibilityCustomAction(name: name, target: self, selector: #selector(performAccessibilityAction))
    }
}

extension AccessibleAction { // UIAlertAction
    private var alertActionHandler: (UIAlertAction?) -> Void {
        { (_: UIAlertAction?) -> Void in
            _ = self.handler()
        }
    }

    public func alertAction(style: UIAlertAction.Style) -> UIAlertAction {
        UIAlertAction(title: name, style: style, handler: alertActionHandler)
    }
}
