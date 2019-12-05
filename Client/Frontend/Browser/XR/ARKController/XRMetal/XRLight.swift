
import Foundation
import UIKit

open class Light {
    public enum LightType {
        case ambient
        case omni
        case directional
        case spot
    }
    
    var name: String?

    var type: LightType = .omni
    
    var color: CGColor = UIColor.white.cgColor
    
    var attenuationStartDistance: Float = 0
    
    var attenuationEndDistance: Float = 0
    
    var attenuationFalloffExponent: Float = 2
    
    var spotInnerAngle: Float = 0
    
    var spotOuterAngle: Float = .pi / 4
}
