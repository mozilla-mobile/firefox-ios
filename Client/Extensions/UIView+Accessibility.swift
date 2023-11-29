// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ObjectiveC

extension UIView {
    
    private static var OrderIndexKey: Void?
    
    /// Specifies the item’s focus order of the accessibility.
    ///
    /// This property is ONLY used in **sortAccessibilityByOrderIndex()** . Items with higher index values appear in front of items with lower values. Items with the same value preserve the relative order. The default value of this property is 0.
    var accessibilityOrderIndex: Int {
        get {
            objc_getAssociatedObject(self, &Self.OrderIndexKey) as? Int ?? 0
        }
        set {
            objc_setAssociatedObject(self, &Self.OrderIndexKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Sort the focus order of the accessibilities by accessibilityCustomIndex.
    func sortAccessibilityByOrderIndex(postNotification: Bool = true) {
        guard self.subviews.count > 0 else { return }
        
        self.accessibilityElements = self.subviews.sorted {
            $0.accessibilityOrderIndex > $1.accessibilityOrderIndex
        }
        
        if (postNotification) {
            UIAccessibility.post(notification: .layoutChanged, argument: self)
        }
    }
}

