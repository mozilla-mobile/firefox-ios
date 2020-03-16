//
//  AStarTests.swift
//  AStarTests
//
//  Created by Damiaan Dufaux on 19/08/16.
//  Copyright © 2016 Damiaan Dufaux. All rights reserved.
//

import XCTest
@testable import AStar

struct Point: Hashable {
	var x, y: Float
}

final class Simple2DNode: GraphNode {
	var position: Point
	var connectedNodes: Set<Simple2DNode>

	init(x: Float, y: Float, conncetions: Set<Simple2DNode> = []) {
		self.position = Point(x: x, y: y)
		connectedNodes = conncetions
	}
    
    func cost(to node: Simple2DNode) -> Float {
        return hypot((position.x - node.position.x), (position.y - node.position.y))
    }
    
    func estimatedCost(to node: Simple2DNode) -> Float {
        return cost(to: node)
    }

	static func == (lhs: Simple2DNode, rhs: Simple2DNode) -> Bool {
		return lhs === rhs
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(position)
	}
}


class AStarTests: XCTestCase {
    var c1, c2, c3, c4, c5: Simple2DNode!
    
    func createConnection(from source: Simple2DNode, to target: Simple2DNode) {
        source.connectedNodes.insert(target)
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        c1 = Simple2DNode(x: 50, y: 0)
        c2 = Simple2DNode(x: 50, y: 65)
        c3 = Simple2DNode(x: 30, y: 80)
        c4 = Simple2DNode(x: 65, y: 70)
        c5 = Simple2DNode(x: 65, y: 50)
        
        createConnection(from: c1, to: c3)
        createConnection(from: c3, to: c4)
        createConnection(from: c4, to: c2)
        
        createConnection(from: c1, to: c5)
        createConnection(from: c5, to: c2)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStraightPath() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let path = c1.findPath(to: c3)
        XCTAssertEqual(path[0], c1)
        XCTAssertEqual(path[1], c3)
    }

    func testTwoSegmentPath() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let path = c1.findPath(to: c4)
        XCTAssertEqual(path[0], c1)
        XCTAssertEqual(path[1], c3)
        XCTAssertEqual(path[2], c4)
    }
    
    func testOptimalPath() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let path = c1.findPath(to: c2)
        print(path)
        XCTAssertEqual(path[0], c1)
        XCTAssertEqual(path[1], c5)
        XCTAssertEqual(path[2], c2)
        
        (c3.position.x, c3.position.y) = (50, 20)
        (c4.position.x, c4.position.y) = (60, 50)
        let otherPath = c1.findPath(to: c2)
        print(otherPath)
        XCTAssertEqual(otherPath[0], c1)
        XCTAssertEqual(otherPath[1], c3)
        XCTAssertEqual(otherPath[2], c4)
        XCTAssertEqual(otherPath[3], c2)
    }
    
    func testEmptyPath() {
        let path = c3.findPath(to: c5)
        XCTAssertEqual(path.count, 0)
    }
}
