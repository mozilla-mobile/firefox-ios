
import Foundation

public class Node: Equatable {
    
    public private(set) var identifier: UUID = UUID()
    
    public var name: String?

    /// The light, if any, associated with this node
    public var light: Light?

    /// The camera, if any, assocated with this node. Drawing the scene using this node as the
    /// point of view will use this node's inverse global transformation, along with the camera's
    /// properties, to build the view and projection matrices.
    public var camera: Camera?

    /// The geometry, if any, that visually represents this node
    public var geometry: Geometry?
    
    public var transform: Transform = Transform()
    
    /// The composed transformation of this node with respect to the world's coordinate frame
    public var worldTransform: Transform {
        return (parent?.worldTransform ?? Transform()) * transform
    }

    /// The parent of this node, if it currently belongs to a scene graph
    public private(set) weak var parent: Node?

    /// The child nodes of this node
    public private(set) var childNodes: [Node] = []
    
    public init() {
    }

    public init(geometry: Geometry?) {
        self.geometry = geometry
    }
    
    public func addChildNode(_ child: Node) {
        child.parent = self
        childNodes.append(child)
    }

    public func insertChildNode(_ child: Node, at index: Int) {
        child.parent = self
        childNodes.insert(child, at: index)
    }

    public func removeFromParentNode() {
        parent?.removeChildNode(self)
    }
    
    private func removeChildNode(_ child: Node) {
        childNodes = childNodes.filter { $0 != child }
    }

    public func childNode(withName name: String, recursively: Bool) -> Node? {
        var candidates = childNodes
        while candidates.count > 0 {
            let candidate = candidates.removeFirst()
            if candidate.name == name {
                return candidate
            }
            if recursively {
                candidates.append(contentsOf: candidate.childNodes)
            }
        }
        return nil
    }
    
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

