/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public protocol AccessibilityActionsSource: class {
    func accessibilityCustomActionsForView(view: UIView) -> [UIAccessibilityCustomAction]?
}

public class AccessibleAction {
    public let name: String
    public let handler: () -> Bool

    public init(name: String, handler: () -> Bool) {
        self.name = name
        self.handler = handler
    }
}

extension AccessibleAction { // UIAccessibilityCustomAction
    @objc private func SELperformAccessibilityAction() -> Bool {
        return handler()
    }

    public var accessibilityCustomAction: UIAccessibilityCustomAction {
        return UIAccessibilityCustomAction(name: name, target: self, selector: "SELperformAccessibilityAction")
    }
}


extension AccessibleAction { // UIAlertAction
    private var alertActionHandler: (UIAlertAction!) -> Void {
        return { (_: UIAlertAction!) -> Void in self.handler() }
    }

    public func alertAction(style style: UIAlertActionStyle) -> UIAlertAction {
        return UIAlertAction(title: name, style: style, handler: alertActionHandler)
    }
}