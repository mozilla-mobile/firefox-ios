// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

extension UIControl {
    // MARK: - Logger Swizzling

    static func loggerSwizzle() {
        let originalSingleSelector = #selector(UIControl.sendAction(_:to:for:))
        let swizzledSingleSelector = #selector(UIControl.loggerSendAction(_:to:for:))

        guard let originalSingleMethod = class_getInstanceMethod(self, originalSingleSelector),
              let swizzledSingleMethod = class_getInstanceMethod(self, swizzledSingleSelector)
        else { return }

        method_exchangeImplementations(originalSingleMethod, swizzledSingleMethod)
    }

    @objc
    private func loggerSendAction(_ action: Selector,
                                  to target: Any?,
                                  for event: UIEvent?) {
        var message: String = "Button \(Self.self) [action: \(action)]"
        if let target = target {
            message.append(" [target: \(String(describing: type(of: target)))]")
        }
        message.append(" was clicked")

        DefaultLogger.shared.log(message, level: .info, category: .lifecycle)
        self.loggerSendAction(action, to: target, for: event)
    }
}
