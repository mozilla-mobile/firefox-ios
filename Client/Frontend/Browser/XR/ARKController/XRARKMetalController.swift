import ARKit
import Metal
import MetalKit

extension MTKView: RenderDestinationProvider {
}

class ARKMetalController: NSObject, ARKControllerProtocol, MTKViewDelegate {
    
    private var session: ARSession
    var renderer: Renderer!
    var bufferAllocator: BufferAllocator!
    var device: MTLDevice!
    var renderView = MTKView()
//    private var anchorsNodes: [AnchorNode] = []
    
    var showMode: ShowMode? {
        didSet {
            updateModes()
        }
    }
    private var showOptions: ShowOptions? {
        didSet {
            updateModes()
        }
    }
    var planes: [UUID : Node] = [:]
    private var planeHitTestResults: [ARHitTestResult] = []
    private var currentHitTest: HitTestResult?
    private var hitTestFocusPoint = CGPoint.zero
    var previewingSinglePlane: Bool = false
    var focusedPlane: Node? {
        didSet {
            oldValue?.geometry?.elements.first?.material.diffuse.contents = UIColor.yellow
        }
    }
    var readyToRenderFrame: Bool = true
    var initializingRender: Bool = true
    
    deinit {
        for view in renderView.subviews {
            view.removeFromSuperview()
        }
        renderView.delegate = nil
        print("ARKMetalController dealloc")
    }
    
    required init(sesion session: ARSession, size: CGSize) {
        self.session = session
        super.init()
        
        if setupAR(with: session) == false {
            print("Error setting up AR Session with Metal")
        }
    }
    
    func update(_ session: ARSession) {
        self.session = session
        if setupAR(with: session) == false {
            print("Error updating AR Session with Metal")
        }
    }
    
    func clean() {
        for (_, plane) in planes {
            plane.removeFromParentNode()
        }
        planes.removeAll()
        
//        for anchor in anchorsNodes {
//            anchor.removeFromParentNode()
//        }
//        anchorsNodes.removeAll()
        
        planeHitTestResults = []
    }
    
    func hitTest(_ point: CGPoint, with type: ARHitTestResult.ResultType) -> [ARHitTestResult] {
        if focusedPlane != nil {
            guard let results = session.currentFrame?.hitTest(point, types: type) else { return [] }
            guard let chosenPlane = focusedPlane else { return [] }
            if let anchorIdentifier = planes.someKey(forValue: chosenPlane) {
                let anchor = results.filter { $0.anchor?.identifier == anchorIdentifier }.first
                if let anchor = anchor {
                    return [anchor]
                }
            }
            return []
        } else {
            return session.currentFrame?.hitTest(point, types: type) ?? []
        }
    }

    func updateModes() {
        guard let showMode = showMode else { return }
        if showMode == ShowMode.urlDebug || showMode == ShowMode.debug {
            renderer.showDebugPlanes = true
        } else {
            renderer.showDebugPlanes = false
        }
    }
    
    func didChangeTrackingState(_ camera: ARCamera?) {
    }
    
//    func currentHitTest() -> Any? {
//        return nil
//    }
    
    func setupAR(with session: ARSession) -> Bool {
        renderView = MTKView()
        renderView = MTKView(frame: UIScreen.main.bounds, device: MTLCreateSystemDefaultDevice())
        renderView.backgroundColor = UIColor.clear
        renderView.delegate = self
        
        guard let device = renderView.device else {
            print("Metal is not supported on this device")
            return false
        }

        renderer = Renderer(session: session, metalDevice: device, renderDestination: renderView)
        renderer.drawRectResized(size: renderView.bounds.size)
        let scene = Scene()
        let cameraNode = Node()
        cameraNode.camera = Camera()
        renderer.scene = scene
        renderer.pointOfView = cameraNode
        bufferAllocator = BufferAllocator(device: device)
        
        return true
    }
    
    // MARK: - ARKControllerProtocol
    
    func getRenderView() -> UIView {
        return renderView
    }
    
    func setHitTestFocus(_ point: CGPoint) {
        hitTestFocusPoint = point
    }
    
    func setShowMode(_ mode: ShowMode) {
        showMode = mode
    }
    
    func setShowOptions(_ options: ShowOptions) {
        showOptions = options
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }
    
    func draw(in view: MTKView) {
        guard readyToRenderFrame || initializingRender else {
            return
        }
        renderer.update(view: view)
    }
    
    // MARK: - Plane Rendering
    
    func renderer(didAddNode node: Node, forAnchor anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let planeGeometry = planeAnchor.geometry
        let nodeGeometry = Plane(vertices: planeGeometry.vertices,
                                 texCoords: planeGeometry.textureCoordinates,
                                 indices: planeGeometry.triangleIndices, bufferAllocator: bufferAllocator)
        node.geometry = nodeGeometry
        let material = node.geometry?.elements.first?.material
        material?.diffuse.contents = UIColor.yellow
//        material?.fillMode = .solid
        material?.fillMode = .wireframe
    }
    
    func renderer(didUpdateNode node: Node, forAnchor anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeGeometry = planeAnchor.geometry
            
            // check the count, sometimes there is no triangleIndicies array provided, presumably because it hasn't changed even if the verticies move?
            // probably should update the vertices and texCoords without rebuilding Plane at this point, but for now just ignore it!
            if (planeGeometry.triangleIndices.count > 2) {
                node.geometry = Plane(vertices: planeGeometry.vertices,
                                      texCoords: planeGeometry.textureCoordinates,
                                      indices: planeGeometry.triangleIndices,
                                      bufferAllocator: bufferAllocator)
                let material = node.geometry?.elements.first?.material
                material?.diffuse.contents = UIColor.yellow
    //            material?.fillMode = .solid
                material?.fillMode = .wireframe
            }
        }
    }
}
