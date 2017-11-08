/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * ScreenGraph helps you get rid of the navigation boiler plate found in a lot of whole-application UI testing.
 *
 * You create a shared graph of UI 'screens' or 'scenes' for your app, and use it for every test.
 *
 * In your tests, you use a navigator which does the job of getting your tests from place to place in your application,
 * leaving you to concentrate on testing, rather than maintaining brittle and duplicated navigation code.
 * 
 * The shared graph may also have other uses, such as generating screen shots for the App Store or L10n translators.
 *
 * Under the hood, the ScreenGraph is using GameplayKit's path finding to do the heavy lifting.
 */

import Foundation
import GameplayKit
import XCTest

struct Edge {
    let destinationName: String
    let predicate: NSPredicate?
    let transition: (XCTestCase, String, UInt) -> Void
}

typealias SceneBuilder<T: UserState> = (ScreenStateNode<T>) -> Void
typealias NodeVisitor = (String) -> Void

open class UserState: NSObject {
    public required override init() {}
    var initialScreenState: String?
}

/**
 * ScreenGraph
 * This is the main interface to building a graph of screens/app states and how to navigate between them.
 * The ScreenGraph will be used as a map to navigate the test agent around the app.
 */
open class ScreenGraph<T: UserState> {
    fileprivate let userStateType: T.Type
    fileprivate let xcTest: XCTestCase

    fileprivate var namedScenes: [String: GraphNode<T>] = [:]
    fileprivate var nodedScenes: [GKGraphNode: GraphNode<T>] = [:]

    fileprivate var conditionalEdges: [ConditionalEdge<T>] = []

    fileprivate var isReady: Bool = false

    fileprivate let gkGraph: GKGraph

    fileprivate typealias UserStateChange = (T) -> ()
    fileprivate let defaultStateRecorder: UserStateChange = { _ in }

    init(for test: XCTestCase, with userStateType: T.Type) {
        self.gkGraph = GKGraph()
        self.userStateType = userStateType
        self.xcTest = test
    }
}

extension ScreenGraph {
    /**
     * Method for creating a ScreenStateNode in the graph. The node should be accompanied by a closure
     * used to document the exits out of this node to other nodes.
     */
    func createScene(_ name: String, file: String = #file, line: UInt = #line, builder: @escaping SceneBuilder<T>) {
        addScreenState(name, file: file, line: line, builder: builder)
    }

    /**
     * Method for creating a ScreenStateNode in the graph. The node should be accompanied by a closure
     * used to document the exits out of this node to other nodes.
     */
    func addScreenState(_ name: String, file: String = #file, line: UInt = #line, builder: @escaping SceneBuilder<T>) {
        let scene = ScreenStateNode(map: self, name: name, file: file, line: line, builder: builder)
        namedScenes[name] = scene
    }

    /**
     * Method for creating a ScreenActionNode in the graph.
     * The transitionTo: node is the screen state that the navigator should go to next from here. It will be called with the userState as an argument.
     * The recorder: closure will be called when the navigator travels to this node.
     */
    func addScreenAction(_ name: String, transitionTo nextNodeName: String, file: String = #file, line: UInt = #line, recorder: @escaping (T) -> ()) {
        addOrCheckScreenAction(name, transitionTo: nextNodeName, file: file, line: line, recorder: recorder)
    }

    /**
     * Method for creating a ScreenActionNode in the graph.
     * The transitionTo: node is the screen state that the navigator should go to next from here. It will be called with the userState as an argument.
     */
    func addScreenAction(_ name: String, transitionTo nextNodeName: String, file: String = #file, line: UInt = #line) {
        addOrCheckScreenAction(name, transitionTo: nextNodeName, file: file, line: line, recorder: defaultStateRecorder)
    }
}

extension ScreenGraph {
    fileprivate func addActionChain(_ actions: [String], finalState screenState: String?, recorder: @escaping UserStateChange, file: String, line: UInt) {
        guard actions.count > 0 else {
            return
        }

        let firstNodeName = actions[0]
        if let existing = namedScenes[firstNodeName] {
            xcTest.recordFailure(withDescription: "Action \(firstNodeName) is defined elsewhere, but should be unique", inFile: file, atLine: line, expected: true)
            xcTest.recordFailure(withDescription: "Action \(firstNodeName) is defined elsewhere, but should be unique", inFile: existing.file, atLine: existing.line, expected: true)
        }

        if let screenState = screenState {
            guard let _ = namedScenes[screenState] as? ScreenStateNode else {
                xcTest.recordFailure(withDescription: "Expected \(screenState) to be a screen state", inFile: file, atLine: line, expected: false)
                return
            }
        }

        for i in 0..<actions.count {
            let thisNodeName = actions[i]
            let nextNodeName = i + 1 < actions.count ? actions[i + 1] : screenState
            let thisRecorder: UserStateChange?
            if i == 0 {
                thisRecorder = recorder
            } else {
                thisRecorder = nil
            }
            addOrCheckScreenAction(thisNodeName, transitionTo: nextNodeName, file: file, line: line, recorder: thisRecorder)
        }
    }

    fileprivate func addOrCheckScreenAction(_ name: String, transitionTo nextNodeName: String? = nil, file: String = #file, line: UInt = #line, recorder: UserStateChange?) {
        let actionNode: ScreenActionNode<T>
        if let existingNode = namedScenes[name] {
            guard let existing = existingNode as? ScreenActionNode else {
                self.xcTest.recordFailure(withDescription: "Screen state \(name) conflicts with an identically named action", inFile: existingNode.file, atLine: existingNode.line, expected: false)
                self.xcTest.recordFailure(withDescription: "Action \(name) conflicts with an identically named screen state", inFile: file, atLine: line, expected: false)
                return
            }
            // The new node has to have the same nextNodeName as the existing node.
            // unless either one of them is nil, so use whichever is the non nil one.
            if let d1 = existing.nextNodeName,
                let d2 = nextNodeName,
                d1 != d2 {
                self.xcTest.recordFailure(withDescription: "\(name) action points to \(d2) elsewhere", inFile: existing.file, atLine: existing.line, expected: false)
                self.xcTest.recordFailure(withDescription: "\(name) action points to \(d1) elsewhere", inFile: file, atLine: line, expected: false)
                return
            }

            let overwriteNodeName = existing.nextNodeName ?? nextNodeName

            // The new version of the same node can have additional UserStateChange recorders,
            // so we just combine these together.
            let overwriteRecorder: UserStateChange?
            if let r1 = existing.recorder,
                let r2 = recorder {
                overwriteRecorder = { userState in
                    r1(userState)
                    r2(userState)
                }
            } else {
                overwriteRecorder = existing.recorder ?? recorder
            }

            actionNode = ScreenActionNode(self,
                                          name: name,
                                          then: overwriteNodeName,
                                          file: file,
                                          line: line,
                                          recorder: overwriteRecorder)

        } else {
            actionNode = ScreenActionNode(self,
                                          name: name,
                                          then: nextNodeName,
                                          file: file,
                                          line: line,
                                          recorder: recorder)
        }

        self.namedScenes[name] = actionNode
    }
}

extension ScreenGraph {
    /**
     * Create a new navigator object. Navigator objects are the main way of getting around the app.
     * Typically, you'll do this in `TestCase.setUp()`
     */
    func navigator(startingAt: String? = nil, file: String = #file, line: UInt = #line) -> Navigator<T> {
        buildGkGraph()
        let userState = userStateType.init()
        guard let name = startingAt ?? userState.initialScreenState,
            let startingScreenState = namedScenes[name] as? ScreenStateNode else {
                xcTest.recordFailure(withDescription: "The app's initial state couldn't be established.",
                                     inFile: file, atLine: line, expected: false)
                fatalError("The app's initial state couldn't be established.")
        }

        userState.initialScreenState = startingScreenState.name

        return Navigator(self, xcTest: xcTest, startingScreenState: startingScreenState, userState: userState)
    }

    fileprivate func buildGkGraph() {
        if isReady {
            return
        }

        isReady = true

        // We have a collection of named nodes – mostly screen states.
        // Each of those have builders, so use them to build the edges.
        // However, they may also contribute some actions, which are also nodes,
        // so namedScenes here is not the same as namedScenes after this block.
        namedScenes.values.forEach { graphNode in
            if let screenStateNode = graphNode as? ScreenStateNode {
                screenStateNode.builder(screenStateNode)
            }
        }

        // Construct all the GKGraphNodes, and add them to the GKGraph.
        let graphNodes = namedScenes.values
        gkGraph.add(graphNodes.map { $0.gkNode })

        graphNodes.forEach { graphNode in
            nodedScenes[graphNode.gkNode] = graphNode
        }

        // Now, we should have a good idea what the edges of the nodes look like,
        // so we need to construct the GKGraph edges from it.
        graphNodes.forEach { graphNode in
            if let screenStateNode = graphNode as? ScreenStateNode {
                let gkNodes = screenStateNode.edges.keys.flatMap { self.namedScenes[$0]?.gkNode } as [GKGraphNode]
                screenStateNode.gkNode.addConnections(to: gkNodes, bidirectional: false)
            } else if let screenActionNode = graphNode as? ScreenActionNode {
                if let destName = screenActionNode.nextNodeName,
                    let destGkNode = namedScenes[destName]?.gkNode {
                    screenActionNode.gkNode.addConnections(to: [destGkNode], bidirectional: false)
                }
            }
        }

        self.conditionalEdges = calculateConditionalEdges()
    }

    fileprivate func calculateConditionalEdges() -> [ConditionalEdge<T>] {
        buildGkGraph()
        let screenStateNodes = namedScenes.values.flatMap { $0 as? ScreenStateNode }

        return screenStateNodes.map { node -> [ConditionalEdge<T>] in
            let src = node.gkNode
            return node.edges.values.flatMap { edge -> ConditionalEdge<T>? in
                guard let predicate = edge.predicate,
                    let dest = self.namedScenes[edge.destinationName]?.gkNode else { return nil }

                return ConditionalEdge<T>(src: src, dest: dest, predicate: predicate)
            } as [ConditionalEdge<T>]
        }.flatMap { $0 }
    }
}

class ScreenActionNode<T: UserState>: GraphNode<T> {
    typealias UserStateChange = (T) -> ()
    let recorder: UserStateChange?

    var nextNodeName: String?

    init(_ map: ScreenGraph<T>, name: String, then nextNodeName: String?, file: String, line: UInt, recorder: UserStateChange?) {
        self.recorder = recorder
        self.nextNodeName = nextNodeName
        super.init(map, name: name, file: file, line: line)
    }
}

typealias Gesture = () -> Void

class WaitCondition {
    let userStatePredicate: NSPredicate?
    let predicate: NSPredicate
    let object: Any
    let file: String
    let line: UInt

    init(_ predicate: String, object: Any, if userStatePredicate: String? = nil, file: String, line: UInt) {
        self.predicate = NSPredicate(format: predicate)
        if let p = userStatePredicate {
            self.userStatePredicate = NSPredicate(format: p)
        } else {
            self.userStatePredicate = nil
        }
        self.object = object
        self.file = file
        self.line = line
    }

    func wait(timeoutHandler: () -> ()) {
        waitOrTimeout(predicate, object: object, timeoutHandler: timeoutHandler)
    }
}

class GraphNode<T: UserState> {
    let name: String
    fileprivate let gkNode: GKGraphNode

    fileprivate weak var map: ScreenGraph<T>?

    fileprivate var file: String
    fileprivate var line: UInt

    fileprivate init(_ map: ScreenGraph<T>, name: String, file: String, line: UInt) {
        self.map = map
        self.name = name
        self.file = file
        self.line = line

        self.gkNode = GKGraphNode()
    }
}

/**
 * The ScreenGraph is made up of nodes. It is not possible to init these directly, only by creating 
 * screen nodes from the ScreenGraph object.
 * 
 * The ScreenGraphNode has all the methods needed to define edges from this node to another node, using the usual
 * XCUIElement method of moving about.
 */
class ScreenStateNode<T: UserState>: GraphNode<T> {
    fileprivate let builder: SceneBuilder<T>
    fileprivate var edges: [String: Edge] = [:]

    typealias UserStateChange = (T) -> ()
    fileprivate let noopUserStateChange: UserStateChange = { _ in }

    // Iff this node has a backAction, this store temporarily stores 
    // the node we were at before we got to this one. This becomes the node we return to when the backAction is 
    // invoked.
    fileprivate weak var returnNode: ScreenStateNode<T>?

    fileprivate var hasBack: Bool {
        return backAction != nil
    }

    /**
     * This is an action that will cause us to go back from where we came from.
     * This is most useful when the same screen is accessible from multiple places, 
     * and we have a back button to return to where we came from.
     */
    var backAction: Gesture?

    /**
     * This flag indicates that once we've moved on from this node, we can't come back to 
     * it via `backAction`. This is especially useful for Menus, and dialogs.
     */
    var dismissOnUse: Bool = false

    fileprivate var onEnterStateRecorder: UserStateChange? = nil

    fileprivate var onExitStateRecorder: UserStateChange? = nil

    fileprivate var onEnterWaitCondition: WaitCondition? = nil

    fileprivate init(map: ScreenGraph<T>, name: String, file: String, line: UInt, builder: @escaping SceneBuilder<T>) {
        self.builder = builder
        super.init(map, name: name, file: file, line: line)
    }

    fileprivate func addEdge(_ dest: String, by edge: Edge) {
        edges[dest] = edge
        // by this time, we should've added all nodes in to the gkGraph.

        assert(map?.namedScenes[dest] != nil, "Destination scene '\(dest)' has not been created anywhere")
    }
}

private let existsPredicate = NSPredicate(format: "exists == true")
private let enabledPredicate = NSPredicate(format: "enabled == true")
private let hittablePredicate = NSPredicate(format: "hittable == true")
private let noopNodeVisitor: NodeVisitor = { _ in }

// This is a function for waiting for a condition of an object to come true.
func waitOrTimeout(_ predicate: NSPredicate = existsPredicate, object: Any, timeout: TimeInterval = 5, timeoutHandler: () -> ()) {
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: object)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    if result != .completed {
        timeoutHandler()
    }
}

// Public methods for defining edges out of this node.
extension ScreenStateNode {
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
                waitOrTimeout(existsPredicate, object: el) { _ in
                    xcTest.recordFailure(withDescription: "Cannot get from \(self.name) to \(nodeName). See \(declFile):\(declLine)", inFile: file, atLine: line, expected: false)
                    xcTest.recordFailure(withDescription: "Cannot find \(el)", inFile: declFile, atLine: declLine, expected: false)
                }
            }
            g()
        })

        guard let _ = map?.namedScenes[nodeName] else {
            map?.xcTest.recordFailure(withDescription: "Node \(nodeName) has not been declared anywhere", inFile: file, atLine: line, expected: false)
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

extension ScreenStateNode {
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

extension ScreenStateNode {
    /// This allows us to record state changes in the app as the navigator moves into a given screen state.
    func onEnter(recorder: @escaping UserStateChange) {
        onEnterStateRecorder = recorder
    }

    /// When entering the screenState, the navigator should wait for element.
    /// The waiting can be made to be optional by specifying a predicate against the userState.
    func onEnterWaitFor(_ predicate: String = "exists == true", element: Any, if userStatePredicate: String? = nil, file: String = #file, line: UInt = #line) {
        onEnterWaitCondition = WaitCondition(predicate, object: element, if: userStatePredicate, file: file, line: line)
    }


    /// This allows us to record state changes in the app as the navigator leaves a given screen state.
    func onExit(recorder: @escaping UserStateChange) {
        onExitStateRecorder = recorder
    }
}

fileprivate class ConditionalEdge<T> {
    let predicate: NSPredicate
    let src: GKGraphNode
    let dest: GKGraphNode

    var isOpen: Bool = true

    init(src: GKGraphNode, dest: GKGraphNode, predicate: NSPredicate) {
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

/**
 * The Navigator provides a set of methods to navigate around the app. You can `goto` nodes, `visit` multiple nodes,
 * or visit all nodes, but mostly you just goto. If you take actions that move around the app outside of the
 * navigator, you can re-sync app with navigator my telling it which node it is now at, using the `nowAt` method.
 */
class Navigator<T: UserState> {
    fileprivate let map: ScreenGraph<T>
    fileprivate var currentScene: GraphNode<T>
    fileprivate var returnToRecentScene: ScreenStateNode<T>
    fileprivate let xcTest: XCTestCase

    var userState: T

    var screenState: String {
        return currentScene.name
    }

    fileprivate init(_ map: ScreenGraph<T>,
                     xcTest: XCTestCase,
                     startingScreenState: ScreenStateNode<T>,
                     userState: T) {
        self.map = map
        self.xcTest = xcTest
        self.currentScene = startingScreenState
        self.returnToRecentScene = startingScreenState
        self.userState = userState

        // We should let the initial state update the user state.
        if let node = currentScene as? ScreenStateNode<T> {
            node.onEnterStateRecorder?(userState)
        } else if let node = currentScene as? ScreenActionNode<T> {
            node.recorder?(userState)
        }

        // Then, we should update the routable graph with respect
        // to the user state.
        _ = userStateShouldChangeGraph(userState)
    }

    func synchronizeWithUserState() {
        _ = userStateShouldChangeGraph(self.userState)
    }

    /**
     * Move the application to the named node.
     */
    func goto(_ nodeName: String, file: String = #file, line: UInt = #line) {
        goto(nodeName, file: file, line: line, visitWith: noopNodeVisitor)
    }

    /**
     * Returns true if this node (action or screen state) is directly reachable from the current point.
     * This is relatively naive: it doesn't take into account conditional edges (those with `if:` predicates),
     * so is not useful in the general case, but it is if you know the specific graph.
     */
    func can(goto nodeName: String) -> Bool {
        let gkSrc = currentScene.gkNode
        guard let gkDest = map.namedScenes[nodeName]?.gkNode else {
            return false
        }
        let gkPath = map.gkGraph.findPath(from: gkSrc, to: gkDest)
        return gkPath.count > 0
    }

    func plan(startAt startNode: String? = nil, goto nodeName: String) -> [String] {
        let gkSrc: GKGraphNode
        if let startNode = startNode,
            let node = map.namedScenes[startNode] {
            gkSrc = node.gkNode
        } else {
            gkSrc = currentScene.gkNode
        }

        guard let destNode = map.namedScenes[nodeName] else {
            return []
        }

        let gkDest = destNode.gkNode
        let gkPath = map.gkGraph.findPath(from: gkSrc, to: gkDest)

        let path = gkPath.flatMap { gkNode in
            return self.map.nodedScenes[gkNode]?.name
        }

        if path.isEmpty {
            return path
        }

        let extras = followUpActions(destNode).flatMap { $0.name }

        return path + extras
    }

    /**
     * Move the application to the named node, wth an optional node visitor closure, which is called each time the
     * node changes.
     */
    func goto(_ nodeName: String, file: String = #file, line: UInt = #line, visitWith nodeVisitor: @escaping NodeVisitor) {
        let gkSrc = currentScene.gkNode
        guard let gkDest = map.namedScenes[nodeName]?.gkNode else {
            xcTest.recordFailure(withDescription: "Cannot route to \(nodeName), because it doesn't exist", inFile: file, atLine: line, expected: false)
            return
        }

        var gkPath = map.gkGraph.findPath(from: gkSrc, to: gkDest)
        guard gkPath.count > 0 else {
            xcTest.recordFailure(withDescription: "Cannot route from \(currentScene.name) to \(nodeName)", inFile: file, atLine: line, expected: false)
            return
        }

        // moveDirectlyTo lets us move from the current scene to the next.
        // We'll use it to follow the path we've calculated,
        // and to move back to the final screen state once we're done.
        // It takes care of exiting the current node, and moving to the next.
        @discardableResult func moveDirectlyTo(_ nextScene: GraphNode<T>) -> Bool {
            var maybeStateChanged = false
            if let node = currentScene as? ScreenStateNode<T> {
                leave(node, to: nextScene, file: file, line: line)
                maybeStateChanged = node.onExitStateRecorder != nil
            } else if let node = currentScene as? ScreenActionNode<T> {
                leave(node, to: nextScene, file: file, line: line)
            }

            if let node = nextScene as? ScreenStateNode<T> {
                enter(node, withVisitor: nodeVisitor)
                maybeStateChanged = maybeStateChanged || node.onEnterStateRecorder != nil
            } else if let node = nextScene as? ScreenActionNode<T> {
                enter(node)
                maybeStateChanged = maybeStateChanged || node.recorder != nil
            }
            currentScene = nextScene

            return maybeStateChanged && self.userStateShouldChangeGraph(userState)
        }

        gkPath.removeFirst()
        let graphNodes = gkPath.flatMap { map.nodedScenes[$0] }

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

        let extras = followUpActions(currentScene)
        if !extras.isEmpty {
            extras.forEach { nextScene in
                moveDirectlyTo(nextScene)
            }
        }

        if let _ = currentScene as? ScreenStateNode<T> {
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
    func performAction(_ screenActionName: String, file: String = #file, line: UInt = #line) {
        guard let _ = map.namedScenes[screenActionName] as? ScreenActionNode else {
            xcTest.recordFailure(withDescription: "\(screenActionName) is not an action", inFile: file, atLine: line, expected: false)
            return
        }
        goto(screenActionName, file: file, line: line)
    }

    func back(file: String = #file, line: UInt = #line) {
        guard let currentScene = currentScene as? ScreenStateNode else {
            return
        }

        guard let returnNode = currentScene.returnNode,
            let _ = currentScene.backAction else {
                xcTest.recordFailure(withDescription: "No valid back action", inFile: currentScene.file, atLine: currentScene.line, expected: false)
                xcTest.recordFailure(withDescription: "No valid back action", inFile: file, atLine: line, expected: false)
                return
        }

        goto(returnNode.name)
    }


    func toggleOn(_ flag: Bool, withAction action: String, file: String = #file, line: UInt = #line) {
        if !flag {
            performAction(action, file: file, line: line)
        }
    }

    func toggleOff(_ flag: Bool, withAction action: String, file: String = #file, line: UInt = #line) {
        toggleOn(!flag, withAction: action, file: file, line: line)
    }

    /**
     * Helper method when the navigator gets out of sync with the actual app.
     * This should not be used too often, as it indicates you should probably have another node in your graph,
     * or you should be using `scene.dismissOnUse = true`.
     * Also useful if you're using XCUIElement taps directly to navigate from one node to another.
     */
    func nowAt(_ nodeName: String, file: String = #file, line: UInt = #line) {
        guard let newScene = map.namedScenes[nodeName] else {
            xcTest.recordFailure(withDescription: "Cannot force to unknown \(nodeName). Currently at \(currentScene.name)", inFile: file, atLine: line, expected: false)
            return
        }
        currentScene = newScene
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
fileprivate extension Navigator {
    fileprivate func leave(_ currentScene: ScreenStateNode<T>, to nextScene: GraphNode<T>, file: String, line: UInt) {
        if !currentScene.dismissOnUse {
            returnToRecentScene = currentScene
        }

        // Before moving to the next node, we may like to record the
        // state of the app.
        currentScene.onExitStateRecorder?(userState)

        if let edge = currentScene.edges[nextScene.name] {
            // We definitely have an action, so it's save to unbox.
            edge.transition(xcTest, file, line)
        }

        if currentScene.hasBack {
            // we've had a backAction, and we're going to go back the previous
            // state. Here we check if the transition above has taken us
            // back to the previous screen.
            if nextScene.name == currentScene.returnNode?.name {
                // currentScene is the state we're returning from.
                // nextScene is the state we're returning to.
                currentScene.returnNode = nil
                currentScene.gkNode.removeConnections(to: [ nextScene.gkNode ], bidirectional: false)
            }
        }
    }

    fileprivate func enter(_ nextScene: ScreenStateNode<T>, withVisitor nodeVisitor: NodeVisitor) {
        if let condition = nextScene.onEnterWaitCondition {
            let shouldWait: Bool
            if let predicate = condition.userStatePredicate {
                shouldWait = predicate.evaluate(with: userState)
            } else {
                shouldWait = true
            }

            if shouldWait {
                condition.wait { _ in
                    self.xcTest.recordFailure(withDescription: "Unsuccessfully entered \(nextScene.name)",
                        inFile: condition.file,
                        atLine: condition.line,
                        expected: false)
                }
            }
        }

        // Now we've transitioned to the next node, we might want to note some state.
        nextScene.onEnterStateRecorder?(userState)

        if let backAction = nextScene.backAction {
            if nextScene.returnNode == nil {
                nextScene.returnNode = returnToRecentScene
                nextScene.gkNode.addConnections(to: [ returnToRecentScene.gkNode ], bidirectional: false)
                nextScene.gesture(to: returnToRecentScene.name, g: backAction)
            }
        } else {
            // We don't have a back here, but we might've had a back stack in the last scene.
            // If that's the case, we should clear it down to make routing easier.
            // This is important in more complex graph structures that possibly have backActions and cycles.
            var screen: ScreenStateNode? = returnToRecentScene
            while screen != nil {
                guard let thisScene = screen,
                    let prevScene = thisScene.returnNode else {
                    break
                }

                thisScene.returnNode = nil
                thisScene.edges.removeValue(forKey: prevScene.name)
                thisScene.gkNode.removeConnections(to: [ prevScene.gkNode ], bidirectional: false)

                screen = prevScene
            }
        }

        nodeVisitor(currentScene.name)
    }

    fileprivate func leave(_ currentScene: ScreenActionNode<T>, to nextScene: GraphNode<T>, file: String, line: UInt) {
        // NOOP
    }

    fileprivate func enter(_ nextScene: ScreenActionNode<T>) {
        nextScene.recorder?(userState)
    }

    func followUpActions(_ lastStep: GraphNode<T>) -> [GraphNode<T>] {
        guard let lastAction = lastStep as? ScreenActionNode else {
            return []
        }
        var action = lastAction
        var extras = [GraphNode<T>]()
        while true {
            if let nextNodeName = action.nextNodeName,
                let next = map.namedScenes[nextNodeName] {
                extras.append(next)
                if let nextAction = next as? ScreenActionNode<T> {
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
fileprivate extension Navigator {
    func userStateShouldChangeGraph(_ userState: T) -> Bool {
        var graphChanged = false
        map.conditionalEdges.forEach { edge in
            if !edge.userStateShouldChangeEdge(userState) {
                return
            }
            graphChanged = true
            if edge.isOpen {
                edge.src.addConnections(to: [edge.dest], bidirectional: false)
            } else {
                edge.src.removeConnections(to: [edge.dest], bidirectional: false)
            }
        }
        return graphChanged
    }
}
