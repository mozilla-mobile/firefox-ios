
import Foundation
import simd

public class Transform : CustomDebugStringConvertible {

    public static let identity = Transform()
    
    private var matrixIsDirty = false
    
    private var _matrix = matrix_identity_float4x4
    
    /// The composed transformation of this node with respect to its local coordinate frame
    public var matrix: float4x4 {
        get {
            if matrixIsDirty {
                composeTransformComponents()
            }
            return _matrix
        }
        set {
            _matrix = newValue
            decomposeTransformComponents()
            matrixIsDirty = false
        }
    }

    /// The position of this node with respect to the origin of its local coordinate frame
    public var translation: float3 = float3(0, 0, 0) {
        didSet {
            matrixIsDirty = true
        }
    }
    
    /// The orientation of this node, expressed as a unit quaternion. Setting this property
    /// also updates the `eulerAngles` property.
//    public var orientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1) {
//        didSet {
//            matrixIsDirty = true
//        }
//    }
    
    /// The orientation of this node, expressed as Euler angles (rotation about each of the principle axes).
    /// The order of components is (pitch, yaw, roll), each expressed in radians, and they are applied
    /// in the opposite order (roll, yaw, pitch) to determine the final rotation. Setting this property
    /// also updates the `orientation` property.
    public var eulerAngles: float3 = float3(0, 0, 0) {
        didSet {
            matrixIsDirty = true
        }
    }
    
    /// The scale of the node, expressed as a scale factor along each of the primary axes
    public var scale: float3 = float3(1, 1, 1) {
        didSet {
            matrixIsDirty = true
        }
    }
    
    public init() {
    }
    
    public init(from matrix: float4x4) {
        self.matrix = matrix
        decomposeTransformComponents()
    }
    
    private func composeTransformComponents() {
        let T = float4x4(translationBy: translation)
        let R = float4x4(rotationFromEulerAngles: eulerAngles)
        let S = float4x4(scaleBy: scale)
        
        _matrix = T * R * S
        
        matrixIsDirty = false
    }
    
    private func decomposeTransformComponents() {
        let trans = _matrix[3].xyz
        
        let scaleX = simd_length(_matrix[0])
        let scaleY = simd_length(_matrix[1])
        let scaleZ = simd_length(_matrix[2])
        
        let rotX = (_matrix[0] / scaleX).xyz
        let rotY = (_matrix[1] / scaleY).xyz
        let rotZ = (_matrix[2] / scaleZ).xyz
        
        translation = trans
        scale = float3(scaleX, scaleY, scaleZ)
        eulerAngles = float3x3([rotX, rotY, rotZ]).decomposeToEulerAngles()
    }
    
    public var debugDescription: String {
        return """
        translation: \(translation.x), \(translation.y), \(translation.z);
        rotation: \(eulerAngles.x * 180 / .pi), \(eulerAngles.y * 180 / .pi), \(eulerAngles.z * 180 / .pi);
        scale: \(scale.x), \(scale.y), \(scale.z)
        """
    }
}

public func *(lhs: Transform, rhs: Transform) -> Transform {
    let LT = float4x4(translationBy: lhs.translation)
    let LR = float4x4(rotationFromEulerAngles: lhs.eulerAngles)
    let LS = float4x4(scaleBy: lhs.scale)
    let RT = float4x4(translationBy: rhs.translation)
    let RR = float4x4(rotationFromEulerAngles: rhs.eulerAngles)
    let RS = float4x4(scaleBy: rhs.scale)

    let composed = LT * LR * LS * RT * RR * RS
    
    return Transform(from: composed)
}
