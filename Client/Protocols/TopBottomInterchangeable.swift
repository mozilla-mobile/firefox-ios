// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A protocol to add and remove a view easily from a parent
/// Used to changed search bar and reader mode bar from header to footer and vice versa
protocol TopBottomInterchangeable: UIView {
    var parent: UIStackView? { get set }
    func removeFromParent()
    func addToParent(parent: UIStackView, addToTop: Bool)
}

extension TopBottomInterchangeable {
    func removeFromParent() {
        parent?.removeArrangedView(self)
    }

    func addToParent(parent: UIStackView, addToTop: Bool = true) {
        self.parent = parent
        if addToTop {
            parent.addArrangedViewToTop(self)
        } else {
            parent.addArrangedViewToBottom(self)
        }
        
        updateConstraints()
        setNeedsDisplay()
    }
}
