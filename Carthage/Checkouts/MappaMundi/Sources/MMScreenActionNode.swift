/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

public class MMActionNode<T: MMUserState>: MMGraphNode<T> {
    // marker
}

// Gestures which affect user state are called ScreenActions.
// These cannot be constructed or manipulated directly, but can be added to the graph using `screenStateNode.*(forAction:)` methods.
public class MMScreenActionNode<T: MMUserState>: MMActionNode<T> {
    public typealias UserStateChange = (T) -> ()
    let onEnterStateRecorder: UserStateChange?

    let nextNodeName: String?

    override var nodeType: String { return "Screen action" }

    init(_ map: MMScreenGraph<T>, name: String, then nextNodeName: String?, file: String, line: UInt, recorder: UserStateChange?) {
        self.onEnterStateRecorder = recorder
        self.nextNodeName = nextNodeName
        super.init(map, name: name, file: file, line: line)
    }

    
}

public class MMNavigatorActionNode<T: MMUserState>: MMActionNode<T> {
    let action: MMNavigatorAction<T>

    override var nodeType: String { return "Navigator action" }

    init(_ map: MMScreenGraph<T>, name: String, file: String, line: UInt, navigatorAction: @escaping MMNavigatorAction<T>) {
        self.action = navigatorAction

        super.init(map, name: name, file: file, line: line)
    }
}
