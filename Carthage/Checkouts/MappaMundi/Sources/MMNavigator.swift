/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import AStar

public typealias NodeVisitor = (String) -> Void

let noopNodeVisitor: NodeVisitor = { _ in }

/**
 * The Navigator provides a set of methods to navigate around the app. You can `goto` nodes, `visit` multiple nodes,
 * or visit all nodes, but mostly you just goto. If you take actions that move around the app outside of the
 * navigator, you can re-sync app with navigator my telling it which node it is now at, using the `nowAt` method.
 */
open class MMNavigator<T: MMUserState> {
    fileprivate let map: MMScreenGraph<T>
    fileprivate var currentGraphNode: MMGraphNode<T>
    fileprivate var returnToRecentScene: MMScreenStateNode<T>
    fileprivate let xcTest: XCTestCase

    public var userState: T

    public var screenState: String {
        return currentGraphNode.name
    }

    init(_ map: MMScreenGraph<T>,
                     xcTest: XCTestCase,
                     startingScreenState: MMScreenStateNode<T>,
                     userState: T) {
        self.map = map
        self.xcTest = xcTest
        self.currentGraphNode = startingScreenState
        self.returnToRecentScene = startingScreenState
        self.userState = userState

        // We should let the initial state update the user state.
        // This should probably use the enter() methods.
        if let node = currentGraphNode as? MMScreenStateNode<T> {
            node.onEnterStateRecorder?(userState)
        } else if let node = currentGraphNode as? MMScreenActionNode<T> {
            node.onEnterStateRecorder?(userState)
        } else if let node = currentGraphNode as? MMNavigatorActionNode<T> {
            node.action(self)
        }

        // Then, we should update the routable graph with respect
        // to the user state.
        _ = userStateShouldChangeGraph(userState)
    }

    public func synchronizeWithUserState() {
        _ = userStateShouldChangeGraph(self.userState)
    }

    /**
     * Returns true if this node (action or screen state) is directly reachable from the current point.
     * This is relatively naive: it doesn't take into account conditional edges (those with `if:` predicates),
     * that change while you're moving _to_ nodeName from here,
     * so is not useful in the general case, but it is if you know the specific graph.
     */
    public func can(goto nodeName: String) -> Bool {
        let mmSrc = currentGraphNode.mmNode
        guard let mmDest = map.namedScenes[nodeName]?.mmNode else {
            return false
        }
        let mmPath = mmSrc.findPath(to: mmDest)
        return mmPath.count > 0
    }

    public func can(performAction nodeName: String, file: String = #file, line: UInt = #line) -> Bool {
        guard isActionOrFail(nodeName, file: file, line: line) else {
            return false
        }
        return can(goto: nodeName)
    }

    public func plan(startAt startNode: String? = nil, goto nodeName: String) -> [String] {
        let mmSrc: MMNode
        if let startNode = startNode,
            let node = map.namedScenes[startNode] {
            mmSrc = node.mmNode
        } else {
            mmSrc = currentGraphNode.mmNode
        }

        guard let destNode = map.namedScenes[nodeName] else {
            return []
        }

        let mmDest = destNode.mmNode
        let mmPath = mmSrc.findPath(to: mmDest)

        let path = mmPath.compactMap { mmNode in
            return self.map.nodedScenes[mmNode]?.name
        }

        if path.isEmpty {
            return path
        }

        let extras = followUpActions(destNode).compactMap { $0.name }

        return path + extras
    }

    public func plan(startAt startNode: String? = nil, performAction nodeName: String, file: String = #file, line: UInt = #line) -> [String] {
        guard isActionOrFail(nodeName, file: file, line: line) else {
            return []
        }
        return plan(startAt: startNode, goto: nodeName)
    }

    /**
     * Move the application to the named node.
     */
    public func goto(_ nodeName: String, file: String = #file, line: UInt = #line) {
        goto(nodeName, file: file, line: line, visitWith: noopNodeVisitor)
    }

    /**
     * Move the application to the named node, wth an optional node visitor closure, which is called each time the
     * node changes.
     */
    public func goto(_ nodeName: String, file: String = #file, line: UInt = #line, visitWith nodeVisitor: @escaping NodeVisitor) {
        let mmSrc = currentGraphNode.mmNode
        guard let mmDest = map.namedScenes[nodeName]?.mmNode else {
            xcTest.recordFailure(withDescription: "Cannot route to \(nodeName), because it doesn't exist", inFile: file, atLine: Int(line), expected: false)
            return
        }
        
        var mmPath = mmSrc.findPath(to: mmDest)

        guard mmPath.count > 0 else {
            xcTest.recordFailure(withDescription: "Cannot route from \(currentGraphNode.name) to \(nodeName)", inFile: file, atLine: Int(line), expected: false)
            return
        }

        // moveDirectlyTo lets us move from the current node to the next.
        // We'll use it to follow the path we've calculated,
        // and to move back to the final screen state once we're done.
        // It takes care of exiting the current node, and moving to the next.
        @discardableResult func moveDirectlyTo(_ nextScene: MMGraphNode<T>) -> Bool {
            var maybeStateChanged = false
            if let node = currentGraphNode as? MMScreenStateNode<T> {
                leave(node, to: nextScene, file: file, line: line)
                maybeStateChanged = node.onExitStateRecorder != nil
            } else if let node = currentGraphNode as? MMActionNode<T> {
                leave(node, to: nextScene, file: file, line: line)
            }

            if let node = nextScene as? MMScreenStateNode<T> {
                enter(node, withVisitor: nodeVisitor)
                maybeStateChanged = maybeStateChanged || node.onEnterStateRecorder != nil
            } else if let node = nextScene as? MMActionNode<T> {
                let thisNodeChangedState = enter(node)
                maybeStateChanged = maybeStateChanged || thisNodeChangedState
            }
            currentGraphNode = nextScene

            return maybeStateChanged && self.userStateShouldChangeGraph(userState)
        }

        mmPath.removeFirst()
        let graphNodes = mmPath.compactMap { map.nodedScenes[$0] }

        for i in 0 ..< graphNodes.count {
            let graphChanged = moveDirectlyTo(graphNodes[i])
            if graphChanged {
                // Whelp! The graph has changed under our feet. Our original path
                // may not be valid. We should re-calculate.
                return goto(nodeName, file: file, line: line, visitWith: nodeVisitor)
            }
        }

        // If the path ends on an action, then we should follow that action
        // until we're on a valid screen state, or there's nothing left to do.

        let extras = followUpActions(currentGraphNode)
        if !extras.isEmpty {
            extras.forEach { nextScene in
                moveDirectlyTo(nextScene)
            }
        }

        if let _ = currentGraphNode as? MMScreenStateNode<T> {
            // ok, we're done; we should return the app
            // back to the screen state, and this path did that.
            return
        }

        moveDirectlyTo(returnToRecentScene)
    }

    /// Perform an app action, as defined by the graph.
    /// Actions can cause userState to change. They only have one edge out,
    /// which could be another action or a screen state.
    /// This method will always return the app to a valid screen state.
    public func performAction(_ actionName: String, file: String = #file, line: UInt = #line) {
        guard isActionOrFail(actionName, file: file, line: line) else {
            return
        }

        if let navigatorAction = map.namedScenes[actionName] as? MMNavigatorActionNode,
            !can(performAction: actionName) {
            navigatorAction.action(self)
        } else {
            goto(actionName, file: file, line: line)
        }
    }

    func isActionOrFail(_ screenActionName: String, file: String = #file, line: UInt = #line) -> Bool {
        guard let _ = map.namedScenes[screenActionName] as? MMActionNode else {
            xcTest.recordFailure(withDescription: "\(screenActionName) is not an action", inFile: file, atLine: Int(line), expected: false)
            return false
        }
        return true
    }

    public func back(file: String = #file, line: UInt = #line) {
        guard let currentScene = currentGraphNode as? MMScreenStateNode else {
            return
        }

        guard let returnNode = currentScene.returnNode,
            let _ = currentScene.backAction else {
                xcTest.recordFailure(withDescription: "No valid back action", inFile: currentScene.file, atLine: Int(currentScene.line), expected: false)
                xcTest.recordFailure(withDescription: "No valid back action", inFile: file, atLine: Int(line), expected: false)
                return
        }

        goto(returnNode.name)
    }


    public func toggleOn(_ flag: Bool, withAction action: String, file: String = #file, line: UInt = #line) {
        if !flag {
            performAction(action, file: file, line: line)
        }
    }

    public func toggleOff(_ flag: Bool, withAction action: String, file: String = #file, line: UInt = #line) {
        toggleOn(!flag, withAction: action, file: file, line: line)
    }

    /**
     * Helper method when the navigator gets out of sync with the actual app.
     * This should not be used too often, as it indicates you should probably have another node in your graph,
     * or you should be using `screen.dismissOnUse = true`.
     * Also useful if you're using XCUIElement taps directly to navigate from one node to another.
     */
    public func nowAt(_ nodeName: String, file: String = #file, line: UInt = #line) {
        guard let newScene = map.namedScenes[nodeName] else {
            xcTest.recordFailure(withDescription: "Cannot force to unknown \(nodeName). Currently at \(currentGraphNode.name)", inFile: file, atLine: Int(line), expected: false)
            return
        }
        currentGraphNode = newScene
    }

    /**
     * Visit the named nodes, calling the NodeVisitor the first time it is encountered.
     */
    func visitNodes(_ nodes: [String], file: String = #file, line: UInt = #line, f: @escaping NodeVisitor) {
        nodes.forEach { node in
            self.goto(node, file: file, line: line)
            f(node)
        }
    }

    /**
     * Visit all nodes, calling the NodeVisitor the first time it is encountered.
     *
     * Some nodes may not be immediately available, depending on the state of the app.
     */
    func visitAll(_ file: String = #file, line: UInt = #line, f: @escaping NodeVisitor) {
        let nodes: [String] = self.map.namedScenes.keys.map { $0 } // keys can't be coerced into a [String]
        self.visitNodes(nodes, file: file, line: line, f: f)
    }

    /**
     * Move the app back to its initial state.
     * This may not be possible.
     */
    func revert(_ file: String = #file, line: UInt = #line) {
        if let initial = self.userState.initialScreenState {
            self.goto(initial, file: file, line: line)
        }
    }
}

// Private methods to help with goto.
fileprivate extension MMNavigator {
    func leave(_ exitingNode: MMScreenStateNode<T>, to nextNode: MMGraphNode<T>, file: String, line: UInt) {
        if !exitingNode.dismissOnUse {
            self.returnToRecentScene = exitingNode
        }

        // Before moving to the next node, we may like to record the
        // state of the app.
        exitingNode.onExitStateRecorder?(userState)

        if let edge = exitingNode.edges[nextNode.name] {
            // We definitely have an action, so it's safe to unbox.
            edge.transition(xcTest, file, line)
        }

        if exitingNode.hasBack {
            // we've had a backAction, and we're going to go back the previous
            // state. Here we check if the transition above has taken us
            // back to the previous screen.
            if nextNode.name == exitingNode.returnNode?.name {
                // currentScene is the state we're returning from.
                // nextScene is the state we're returning to.
                exitingNode.returnNode = nil
                exitingNode.mmNode.connectedNodes.remove(nextNode.mmNode)
            }
        }
    }

    func enter(_ enteringNode: MMScreenStateNode<T>, withVisitor nodeVisitor: NodeVisitor) {
        if let condition = enteringNode.onEnterWaitCondition {
            let shouldWait: Bool
            if let predicate = condition.userStatePredicate {
                shouldWait = predicate.evaluate(with: userState)
            } else {
                shouldWait = true
            }

            if shouldWait {
                condition.wait { 
                    self.xcTest.recordFailure(withDescription: "Unsuccessfully entered \(enteringNode.name)",
                        inFile: condition.file,
                        atLine: Int(condition.line),
                        expected: false)
                }
            }
        }

        // Now we've transitioned to the next node, we might want to note some state.
        enteringNode.onEnterStateRecorder?(userState)

        if let backAction = enteringNode.backAction {
            if enteringNode.returnNode == nil {
                enteringNode.returnNode = returnToRecentScene
                enteringNode.mmNode.connectedNodes.insert(returnToRecentScene.mmNode)
                enteringNode.gesture(to: returnToRecentScene.name, g: backAction)
            }
        } else {
            // We don't have a back here, but we might've had a back stack in the last node.
            // If that's the case, we should clear it down to make routing easier.
            // This is important in more complex graph structures that possibly have backActions and cycles.
            var screen: MMScreenStateNode? = self.returnToRecentScene
            while screen != nil {
                guard let thisScene = screen,
                    let prevScene = thisScene.returnNode else {
                        break
                }

                thisScene.returnNode = nil
                thisScene.edges.removeValue(forKey: prevScene.name)
                thisScene.mmNode.connectedNodes.remove(prevScene.mmNode)

                screen = prevScene
            }
        }

        nodeVisitor(currentGraphNode.name)
    }

    func leave(_ exitingNode: MMActionNode<T>, to nextNode: MMGraphNode<T>, file: String, line: UInt) {
        // NOOP
    }

    func enter(_ enteringNode: MMActionNode<T>) -> Bool {
        if let node = enteringNode as? MMScreenActionNode<T>,
            let onEnterStateRecorder = node.onEnterStateRecorder {
            onEnterStateRecorder(userState)
            return true
        } else if let node = enteringNode as? MMNavigatorActionNode<T> {
            node.action(self)
            return true
        }

        return false
    }

    func followUpActions(_ lastStep: MMGraphNode<T>) -> [MMGraphNode<T>] {
        guard let lastAction = lastStep as? MMScreenActionNode else {
            return []
        }
        var action = lastAction
        var extras = [MMGraphNode<T>]()
        while true {
            if let nextNodeName = action.nextNodeName,
                let next = map.namedScenes[nextNodeName] {
                extras.append(next)
                if let nextAction = next as? MMScreenActionNode<T> {
                    action = nextAction
                    continue
                }
            }
            break
        }
        return extras
    }
}

// Private methods to help with conditional edges.
fileprivate extension MMNavigator {
    func userStateShouldChangeGraph(_ userState: T) -> Bool {
        var graphChanged = false
        map.conditionalEdges.forEach { edge in
            if !edge.userStateShouldChangeEdge(userState) {
                return
            }
            graphChanged = true
            if edge.isOpen {
                edge.src.connectedNodes.insert(edge.dest)
            } else {
                edge.src.connectedNodes.remove(edge.dest)
            }
        }
        return graphChanged
    }
}

/// Helper methods to be used from within tests.
/// These methods allow tests to wait for an element to reach a condition, or timeout.
/// If the condition is never reached, the timeout is reported in-line where the navigator was asked to wait.
public extension MMNavigator {
    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 7.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "exists == true", timeout: timeout, file: file, line: line)
    }

    func waitForNonExistence(_ element: XCUIElement, timeoutValue: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "exists != true", timeout: timeoutValue, file: file, line: line)
    }

    func waitFor(_ element: XCUIElement, toContain value: String, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "value CONTAINS '\(value)'", file: file, line: line)
    }

    func waitFor(_ element: XCUIElement,
                         with predicateString: String,
                         description: String? = nil,
                         timeout: TimeInterval = 5.0,
                         file: String = #file, line: UInt = #line) {

        let predicate = NSPredicate(format: predicateString)
        waitOrTimeout(predicate, object: element, timeout: timeout) {
            let message = description ?? "Expect predicate \(predicateString) for \(element.description)"
            xcTest.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: false)
        }
    }
}
