//: Playground - noun: a place where people can play

import AStar
import SpriteKit
import PlaygroundSupport

final class Simple2DNode: SKShapeNode, GraphNode {
	var connectedNodes = Set<Simple2DNode>()
	
	func cost(to node: Simple2DNode) -> Float {
		return Float(hypot(
			(position.x - node.position.x),
			(position.y - node.position.y)
		))
	}
	
	func estimatedCost(to node: Simple2DNode) -> Float {
		return cost(to: node)
	}
}

let view = SKView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
PlaygroundPage.current.liveView = view

let scene = SKScene(size: CGSize(width: 200, height: 200))
scene.scaleMode = SKSceneScaleMode.aspectFit
view.presentScene(scene)

scene.backgroundColor = NSColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)

func makeCircle(x: CGFloat, y: CGFloat, label: String) -> Simple2DNode {
	return Simple2DNode(circleOfRadius: 3)
		.setup(x: x, y: y, label: label) as! Simple2DNode
}

func createConnection(from source: Simple2DNode, to target: Simple2DNode) {
	source.connectedNodes.insert(target)
	let ends = EndPoints((source, target))
	connections[ends] = directedLineBetween(endPoints: ends)
}
rootNode.position = CGPoint(x: 3, y: 3)

let c1 = makeCircle(x: 100, y: 5,  label: "1")
let c2 = makeCircle(x: 100, y: 130, label: "2")
let c3 = makeCircle(x: 60, y: 160, label: "3")
let c4 = makeCircle(x: 130, y: 140, label: "4")
let c5 = makeCircle(x: 180, y: 100, label: "5")

createConnection(from: c1, to: c3)
createConnection(from: c3, to: c4)
createConnection(from: c4, to: c2)

createConnection(from: c1, to: c5)
createConnection(from: c5, to: c2)

let path = c1.findPath(to: c2)
for index in 1..<path.count {
	connections[EndPoints((path[index-1], path[index]))]?.strokeColor = .red
}

scene.addChild(rootNode)
