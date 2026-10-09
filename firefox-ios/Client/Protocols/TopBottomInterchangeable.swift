// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A protocol to add and remove a view easily from a parent
/// Used to changed search bar and reader mode bar from header to footer and vice versa
@MainActor
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
        addToParent(parent: parent, addToTop: addToTop, belowView: nil)
    }

    /// Adds `self` to `parent`, directly below `belowView` when it's already an arranged subview there.
    /// Falls back to `addToTop`/`addToBottom` when `belowView` is nil or not present, so callers can keep
    /// a sibling (the top tabs strip) pinned above `self` regardless of insertion order.
    func addToParent(parent: UIStackView, addToTop: Bool = true, belowView: UIView?) {
        self.parent = parent
        if let belowView, let index = parent.arrangedSubviews.firstIndex(of: belowView) {
            parent.insertArrangedView(self, position: index + 1)
        } else if addToTop {
            parent.addArrangedViewToTop(self)
        } else {
            parent.addArrangedViewToBottom(self)
        }

        updateConstraints()
        setNeedsDisplay()
    }
}
