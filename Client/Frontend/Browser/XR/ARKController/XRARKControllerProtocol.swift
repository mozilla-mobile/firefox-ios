import ARKit

protocol ARKControllerProtocol: NSObjectProtocol {
    init(sesion session: ARSession, size: CGSize)
    func update(_ session: ARSession)
    func clean()
    func getRenderView() -> UIView
    func hitTest(_ point: CGPoint, with type: ARHitTestResult.ResultType) -> [ARHitTestResult]
    // Commented during conversion of ARKSceneKitController to Swift, appears unused
    //- (id)currentHitTest;
    func setHitTestFocus(_ point: CGPoint)
    func setShowMode(_ mode: ShowMode)
    func setShowOptions(_ options: ShowOptions)
    var previewingSinglePlane: Bool { get set }
    var readyToRenderFrame: Bool { get set }
    var initializingRender: Bool { get set }
    var renderer: Renderer! { get set }
}
