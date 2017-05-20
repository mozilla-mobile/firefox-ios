/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public protocol AccessibilityActionsSource: class {
    func accessibilityCustomActionsForView(_ view: UIView) -> [UIAccessibilityCustomAction]?
}

open class AccessibleAction {
    open let name: String
    open let handler: () -> Bool

    public init(name: String, handler: @escaping () -> Bool) {
        self.name = name
        self.handler = handler
    }
}

extension AccessibleAction { // UIAccessibilityCustomAction
    @objc private func SELperformAccessibilityAction() -> Bool {
        return handler()
    }

    public var accessibilityCustomAction: UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: name, target: self, selector: #selector(AccessibleAction.SELperformAccessibilityAction))
    }
}

extension AccessibleAction { // UIAlertAction
    private var alertActionHandler: (UIAlertAction!) -> Void {
        return { (_: UIAlertAction!) -> Void in
            _ = self.handler()
        }
    }

    public func alertAction(style: UIAlertActionStyle) -> UIAlertAction {
        return UIAlertAction(title: name, style: style, handler: alertActionHandler)
    }
}
