/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class MMGraphElement {
    let name: String

    let file: String
    let line: UInt

    init(name: String, file: String, line: UInt) {
        self.name = name
        self.file = file
        self.line = line
    }
}

/// The super class of screen action and screen state nodes.
/// By design, the user should not be able to construct these nodes.
public class MMGraphNode<T: MMUserState>: MMGraphElement {
    var nodeType: String { return "Node" }

    let mmNode: MMNode

    weak var map: MMScreenGraph<T>?

    init(_ map: MMScreenGraph<T>, name: String, file: String, line: UInt) {
        self.map = map

        self.mmNode = MMNode(name: name)

        super.init(name: name, file: file, line: line)
    }
}
