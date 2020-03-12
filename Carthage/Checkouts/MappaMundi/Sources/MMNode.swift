/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AStar
final class MMNode: GraphNode {
    var name: String?
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
    
    static func == (lhs: MMNode, rhs: MMNode) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    
    var connectedNodes = Set<MMNode>()
    
    func cost(to node: MMNode) -> Float {
        return 1
    }
    
    func estimatedCost(to node: MMNode) -> Float {
        return cost(to: node)
    }
}
