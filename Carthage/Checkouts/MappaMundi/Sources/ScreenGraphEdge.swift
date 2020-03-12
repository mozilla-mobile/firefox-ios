/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

// These are two data structures that define an edge between nodes.
// All edges (regardless of the nodes they connect) may be conditional — that is
// their traversibility is conditional upon the current user defined app state.

// This first struct is a simple retelling of how the API allows us to construct the edge,
// using the gestures defined from the `ScreenStateNode`.
struct Edge {
    let destinationName: String
    let predicate: NSPredicate?
    let transition: (XCTestCase, String, UInt) -> Void
}

// This second is one we have processed for easier manipulation while the navigator is
// moving around the graph. Each time a UserStateChange recorder is used, then _all_ `ConditionalEdges` are
// re-evaluated.
class ConditionalEdge<T> {
    let predicate: NSPredicate
    let src: MMNode
    let dest: MMNode

    var isOpen: Bool = true

    init(src: MMNode, dest: MMNode, predicate: NSPredicate) {
        self.src = src
        self.dest = dest
        self.predicate = predicate
    }

    func userStateShouldChangeEdge(_ state: T) -> Bool {
        let newValue = predicate.evaluate(with: state)
        defer { self.isOpen = newValue }
        return isOpen != newValue
    }
}
