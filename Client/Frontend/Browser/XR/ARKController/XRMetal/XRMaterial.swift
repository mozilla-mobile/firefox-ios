
import Foundation
import Metal

public class MaterialProperty {
    internal var cachedTexture: MTLTexture?

    public var contents: Any? {
        didSet {
            cachedTexture = nil
        }
    }
    
    public init() {
    }
    
    public init(constant: Float) {
        contents = constant
    }
}

public extension Material {
    struct AttributeIndex {
        static let position  = 0
        static let normal    = 1
        static let color     = 2
        static let texCoords = 3
    }
    
    struct BufferIndex {
        static let instanceUniforms = 8
        static let frameUniforms    = 9
    }
    
    struct TextureIndex {
        static let diffuse = 0
        static let normal = 1
        static let emissive = 2
        static let metalness = 3
        static let roughness = 4
        static let occlusion = 5
    }
}

public class Material {
    public enum FillMode {
        case wireframe
        case solid
    }
    
    public enum BlendMode {
        case add
        case sourceOver
    }
    
    public enum CullMode {
        case none
        case front
        case back
    }

    public var name: String?

    public private(set) var diffuse: MaterialProperty = MaterialProperty(constant: 0)

    public private(set) var ambient: MaterialProperty = MaterialProperty(constant: 0)

    public private(set) var specular: MaterialProperty = MaterialProperty(constant: 0)

    public private(set) var emissive: MaterialProperty = MaterialProperty(constant: 0)

    public private(set) var normal: MaterialProperty = MaterialProperty()

    public var shininess: Float = 1

    public var opacity: Float = 0

    public var fillMode: FillMode = .solid

    public var cullMode: CullMode = .none

    public var blendMode: BlendMode = .add

    public var writesToDepthBuffer: Bool = true

    public var readsFromDepthBuffer: Bool = true
}


public class BlinnPhongMaterial {
}
