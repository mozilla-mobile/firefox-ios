import ARKit

class HitTestResult: NSObject {
    var position: SCNVector3?
    var anchor: ARPlaneAnchor?
    var hightQuality = false
    var infinitePlane = false
}
