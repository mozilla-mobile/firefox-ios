// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// https://medium.com/@BeauNouvelle/adding-a-closure-to-uibarbuttonitem-24dfc217fe72
extension UIBarButtonItem {
    private class UIBarButtonItemClosureWrapper: NSObject {
        let closure: (UIBarButtonItem) -> Void
        init(_ closure: @escaping (UIBarButtonItem) -> Void) {
            self.closure = closure
        }
    }

    private struct AssociatedKeys {
        // This property's address will be used as a unique address for the associated object's handle
        static var targetClosure: UInt8 = 0
    }

    private var targetClosure: ((UIBarButtonItem) -> Void)? {
        get {
            guard let closureWrapper = objc_getAssociatedObject(
                self,
                &AssociatedKeys.targetClosure
            ) as? UIBarButtonItemClosureWrapper else { return nil }
            return closureWrapper.closure
        }
        set(newValue) {
            guard let newValue = newValue else { return }
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.targetClosure,
                UIBarButtonItemClosureWrapper(newValue),
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    public convenience init(
        title: String?,
        style: UIBarButtonItem.Style,
        closure: @escaping (UIBarButtonItem) -> Void
    ) {
        self.init(title: title, style: style, target: nil, action: #selector(UIBarButtonItem.closureAction))
        self.target = self
        targetClosure = closure
    }

    public convenience init(
        barButtonSystemItem systemItem: UIBarButtonItem.SystemItem,
        closure: @escaping (UIBarButtonItem) -> Void
    ) {
        self.init(barButtonSystemItem: systemItem, target: nil, action: #selector(UIBarButtonItem.closureAction))
        self.target = self
        targetClosure = closure
    }

    @objc
    func closureAction() {
        targetClosure?(self)
    }
}
