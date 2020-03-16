/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

/**
 * The ScreenGraph is made up of nodes. It is not possible to init these directly, only by creating
 * screen nodes from the ScreenGraph object.
 *
 * The ScreenGraphNode has all the methods needed to define edges from this node to another node, using the usual
 * XCUIElement method of moving about.
 */
public class MMScreenStateNode<T: MMUserState>: MMGraphNode<T> {
    override var nodeType: String { return "Screen state" }

    let builder: MMScreenStateBuilder<T>
    var edges: [String: Edge] = [:]

    public typealias UserStateChange = (T) -> ()
    let noopUserStateChange: UserStateChange = { _ in }

    // Iff this node has a backAction, this store temporarily stores
    // the node we were at before we got to this one. This becomes the node we return to when the backAction is
    // invoked.
    weak var returnNode: MMScreenStateNode<T>?

    var hasBack: Bool {
        return backAction != nil
    }

    /**
     * This is an action that will cause us to go back from where we came from.
     * This is most useful when the same screen is accessible from multiple places,
     * and we have a back button to return to where we came from.
     */
    public var backAction: (() -> Void)?

    /**
     * This flag indicates that once we've moved on from this node, we can't come back to
     * it via `backAction`. This is especially useful for Menus, and dialogs.
     */
    public var dismissOnUse: Bool = false

    var onEnterStateRecorder: UserStateChange? = nil

    var onExitStateRecorder: UserStateChange? = nil

    var onEnterWaitCondition: WaitCondition? = nil

    init(map: MMScreenGraph<T>, name: String, file: String, line: UInt, builder: @escaping MMScreenStateBuilder<T>) {
        self.builder = builder
        super.init(map, name: name, file: file, line: line)
    }

    fileprivate func addEdge(_ dest: String, by edge: Edge) {
        edges[dest] = edge
        // by this time, we should've added all nodes in to the rootNode.

        assert(map?.namedScenes[dest] != nil, "Destination node '\(dest)' has not been created anywhere")
    }
}

// Public methods for defining gestures out of this screen state to other screen states.
public extension MMScreenStateNode {
    /**
     * Declare that by performing the given action/gesture, then we can navigate from this node to the next.
     *
     * @param withElement – optional, but if provided will attempt to verify it is there before performing the action.
     * @param to – the destination node.
     */
    func gesture(withElement element: XCUIElement? = nil, to nodeName: String, if predicateString: String? = nil, file declFile: String = #file, line declLine: UInt = #line, g: @escaping () -> Void) {
        let predicate: NSPredicate?
        if let predicateString = predicateString {
            predicate = NSPredicate(format: predicateString)
        } else {
            predicate = nil
        }

        let edge = Edge(destinationName: nodeName, predicate: predicate, transition: { xcTest, file, line in
            if let el = element {
                waitOrTimeout(existsPredicate, object: el) {
                    xcTest.recordFailure(withDescription: "Cannot get from \(self.name) to \(nodeName). See \(declFile):\(declLine)", inFile: file, atLine: Int(line), expected: false)
                    xcTest.recordFailure(withDescription: "Cannot find \(el)", inFile: declFile, atLine: Int(declLine), expected: false)
                }
            }
            g()
        })

        guard let _ = map?.namedScenes[nodeName] else {
            map?.xcTest.recordFailure(withDescription: "Node \(nodeName) has not been declared anywhere", inFile: file, atLine: Int(line), expected: false)
            return
        }
        addEdge(nodeName, by: edge)
    }

    func noop(to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(to: nodeName, if: predicate, file: file, line: line) {
            // NOOP.
        }
    }

    /**
     * Declare that by tapping a given element, we should be able to navigate from this node to another.
     *
     * @param element - the element to tap
     * @param to – the destination node.
     */
    func tap(_ element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.tap()
        }
    }

    func doubleTap(_ element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.doubleTap()
        }
    }

    func press(_ element: XCUIElement, forDuration duration: TimeInterval = 1, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.press(forDuration: duration)
        }
    }

    func typeText(_ text: String, into element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.typeText(text)
        }
    }

    func swipeLeft(_ element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.swipeLeft()
        }
    }

    func swipeRight(_ element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.swipeRight()
        }
    }

    func swipeUp(_ element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.swipeUp()
        }
    }

    func swipeDown(_ element: XCUIElement, to nodeName: String, if predicate: String? = nil, file: String = #file, line: UInt = #line) {
        self.gesture(withElement: element, to: nodeName, if: predicate, file: file, line: line) {
            element.swipeDown()
        }
    }
}

// Public methods for defining actions possible from this screen state.
public extension MMScreenStateNode {
    func gesture(withElement element: XCUIElement? = nil, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        gesture(withElement: element, to: actions[0], if: predicate, file: file, line: line) {
            // NOP
        }
    }

    func noop(forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        noop(to: actions[0], if: predicate, file: file, line: line)
    }

    func tap(_ element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        tap(element, to: actions[0], if: predicate, file: file, line: line)
    }

    func doubleTap(_ element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        doubleTap(element, to: actions[0], if: predicate, file: file, line: line)
    }

    func press(_ element: XCUIElement, forDuration duration: TimeInterval = 1, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        press(element, forDuration: duration, to: actions[0], if: predicate, file: file, line: line)
    }


    func typeText(_ text: String, into element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        typeText(text, into: element, to: actions[0], if: predicate, file: file, line: line)
    }

    func swipeLeft(_ element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        swipeLeft(element, to: actions[0], if: predicate, file: file, line: line)
    }

    func swipeRight(_ element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        swipeRight(element, to: actions[0], if: predicate, file: file, line: line)
    }

    func swipeUp(_ element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        swipeUp(element, to: actions[0], if: predicate, file: file, line: line)
    }

    func swipeDown(_ element: XCUIElement, forAction actions: String..., transitionTo screenState: String? = nil, if predicate: String? = nil, file: String = #file, line: UInt = #line, recorder: @escaping UserStateChange = { _ in }) {
        map?.addActionChain(actions, finalState: screenState, recorder: recorder, file: file, line: line)
        swipeDown(element, to: actions[0], if: predicate, file: file, line: line)
    }
}

/// Methods for recording state when we enter or exit this state. Also waiting for conditions to be
/// true before this state  is entered.
extension MMScreenStateNode {
    /// This allows us to record state changes in the app as the navigator moves into a given screen state.
    public func onEnter(recorder: @escaping UserStateChange) {
        onEnterStateRecorder = recorder
    }

    /// When entering the screenState, the navigator should wait for element.
    /// The waiting can be made to be optional by specifying a predicate against the userState.
    public func onEnterWaitFor(_ predicate: String = "exists == true", element: Any, if userStatePredicate: String? = nil, file: String = #file, line: UInt = #line) {
        onEnterWaitCondition = WaitCondition(predicate, object: element, if: userStatePredicate, file: file, line: line)
    }


    /// This allows us to record state changes in the app as the navigator leaves a given screen state.
    public func onExit(recorder: @escaping UserStateChange) {
        onExitStateRecorder = recorder
    }
}
