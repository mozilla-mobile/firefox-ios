// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest
import MappaMundi

class FxScreenGraphTests: XCTestCase {
    func testRenderDotFile() {
        // This will render to $HOME/Library/Caches/tools.mappamundi/graph.dot, falling back to $HOME/Library/Caches/graph.dot
        // Shell command:
        // % dot -Tpng $HOME/Library/Caches/tools.mappamundi/graph.dot -ograph.png
        //
        // dot is provided by graphviz.
        // To install:
        // % brew install graphviz
        // MMTestUtils.render(graph: createScreenGraph(for: self, with: XCUIApplication()))
    }
}
