import Foundation
import UIKit

class Utils: NSObject {
    /**
     Gets the interface orientation taking the device orientation as input
     
     @return the UIInterfaceOrientation of the app
     */

    class func getInterfaceOrientationFromDeviceOrientation() -> UIInterfaceOrientation {
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        var interfaceOrientation: UIInterfaceOrientation = .landscapeLeft
        switch deviceOrientation {
            case .portrait:
                interfaceOrientation = .portrait
            case .portraitUpsideDown:
                interfaceOrientation = .portraitUpsideDown
            case .landscapeLeft:
                interfaceOrientation = .landscapeRight
            case .landscapeRight:
                interfaceOrientation = .landscapeLeft
            case .faceUp:
                // Without more context, we don't know the interface orientation when the device is oriented flat, so take it from the statusBarOrientation
                interfaceOrientation = UIApplication.shared.statusBarOrientation
            case .faceDown:
                // Without more context, we don't know the interface orientation when the device is oriented flat, so take it from the statusBarOrientation
                interfaceOrientation = UIApplication.shared.statusBarOrientation
            default:
                break
        }

        return interfaceOrientation
    }
}

extension vector_float2 {
    func dictionary() -> NSDictionary {
        return [
            WEB_AR_X_POSITION_OPTION: self.x,
            WEB_AR_Y_POSITION_OPTION: self.y
        ]
    }
}

extension vector_float3 {
    func dictionary() -> NSDictionary {
        return [
            WEB_AR_X_POSITION_OPTION: self.x,
            WEB_AR_Y_POSITION_OPTION: self.y,
            WEB_AR_Z_POSITION_OPTION: self.z
        ]
    }
}

extension matrix_float3x3 {
    func array() -> [Float] {
        return [
            self.columns.0.x,
            self.columns.0.y,
            self.columns.0.z,
            self.columns.1.x,
            self.columns.1.y,
            self.columns.1.z,
            self.columns.2.x,
            self.columns.2.y,
            self.columns.2.z,
        ]
    }
}

func dictFromVector3(_ vector: vector_float3) -> NSDictionary {
    return [
        "x": vector.x,
        "y": vector.y,
        "z": vector.z
    ]
}

public extension float3x3 {
    func decomposeToEulerAngles() -> float3 {
        let rotX = atan2( self[1][2], self[2][2])
        let rotY = atan2(-self[0][2], hypot(self[1][2], self[2][2]))
        let rotZ = atan2( self[0][1], self[0][0])
        return float3(rotX, rotY, rotZ)
    }
}

public struct packed_float3 {
    var x, y, z: Float
    
    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ v: float3) {
        self.x = v.x
        self.y = v.y
        self.z = v.z
    }
}

extension matrix_float4x4 {
    func array() -> [Float] {
        return [
            self.columns.0.x,
            self.columns.0.y,
            self.columns.0.z,
            self.columns.0.w,
            self.columns.1.x,
            self.columns.1.y,
            self.columns.1.z,
            self.columns.1.w,
            self.columns.2.x,
            self.columns.2.y,
            self.columns.2.z,
            self.columns.2.w,
            self.columns.3.x,
            self.columns.3.y,
            self.columns.3.z,
            self.columns.3.w
        ]
    }
}

public extension float4 {
    var xyz: float3 {
        return float3(x, y, z)
    }
    
    init(_ v: float3, _ w: Float) {
        self.init(v.x, v.y, v.z, w)
    }
}

extension Array {
    func matrix() -> matrix_float4x4 {
        var matrix = matrix_float4x4()
        matrix.columns.0.x = (self[0] as? NSNumber)?.floatValue ?? 0
        matrix.columns.0.y = (self[1] as? NSNumber)?.floatValue ?? 0
        matrix.columns.0.z = (self[2] as? NSNumber)?.floatValue ?? 0
        matrix.columns.0.w = (self[3] as? NSNumber)?.floatValue ?? 0
        matrix.columns.1.x = (self[4] as? NSNumber)?.floatValue ?? 0
        matrix.columns.1.y = (self[5] as? NSNumber)?.floatValue ?? 0
        matrix.columns.1.z = (self[6] as? NSNumber)?.floatValue ?? 0
        matrix.columns.1.w = (self[7] as? NSNumber)?.floatValue ?? 0
        matrix.columns.2.x = (self[8] as? NSNumber)?.floatValue ?? 0
        matrix.columns.2.y = (self[9] as? NSNumber)?.floatValue ?? 0
        matrix.columns.2.z = (self[10] as? NSNumber)?.floatValue ?? 0
        matrix.columns.2.w = (self[11] as? NSNumber)?.floatValue ?? 0
        matrix.columns.3.x = (self[12] as? NSNumber)?.floatValue ?? 0
        matrix.columns.3.y = (self[13] as? NSNumber)?.floatValue ?? 0
        matrix.columns.3.z = (self[14] as? NSNumber)?.floatValue ?? 0
        matrix.columns.3.w = (self[15] as? NSNumber)?.floatValue ?? 0
        
        return matrix
    }
}

public extension float4x4 {
    init(translationBy t: float3) {
        self.init(float4(1, 0, 0, 0),
                  float4(0, 1, 0, 0),
                  float4(0, 0, 1, 0),
                  float4(t.x, t.y, t.z, 1))
    }
    
    init(rotationFromEulerAngles v: float3) {
        let sx = sin(v.x)
        let cx = cos(v.x)
        let sy = sin(v.y)
        let cy = cos(v.y)
        let sz = sin(v.z)
        let cz = cos(v.z)
        let columns = [ float4(           cy*cz,             cy*sz,   -sy, 0),
                        float4(cz*sx*sy - cx*sz,  cx*cz + sx*sy*sz, cy*sx, 0),
                        float4(cx*cz*sy + sx*sz, -cz*sx + cx*sy*sz, cx*cy, 0),
                        float4(               0,                 0,     0, 1) ]
        self.init(columns)
    }

    init(scaleBy s: float3) {
        self.init([float4(s.x, 0, 0, 0), float4(0, s.y, 0, 0), float4(0, 0, s.z, 0), float4(0, 0, 0, 1)])
    }
    
    var upperLeft: float3x3 {
        return float3x3(self[0].xyz, self[1].xyz, self[2].xyz)
    }
}

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}

class ClosureSleeve {
    let closure: ()->()
    
    init (_ closure: @escaping ()->()) {
        self.closure = closure
    }
    
    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func addAction(for controlEvents: UIControl.Event, _ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
