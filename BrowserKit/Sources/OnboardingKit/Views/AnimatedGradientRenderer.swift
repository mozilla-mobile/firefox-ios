// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

#if false
import MetalKit
#endif

private enum AnimatedGradientUX {
    static let timeIncrementPerFrame: Float = 0.0045
    static let vertexShaderFunctionName = "animatedGradientVertex"
    static let fragmentShaderFunctionName = "animatedGradientFragment"
    static let fullScreenQuadVertexCount = 4
    static let timeBufferIndex = 0
    static let previousFrameTextureIndex = 0
}

#if false
class AnimatedGradientRenderer: NSObject, MTKViewDelegate {
    private let logger: Logger
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private var currentTime: Float = 0.0
    private var previousFrameTexture: MTLTexture?
    let metalDevice: MTLDevice

    init?(logger: Logger = DefaultLogger.shared, device: MTLDevice?) {
        self.logger = logger

        guard let device else {
            logger.log("No Metal device available", level: .fatal, category: .onboarding)
            return nil
        }
        metalDevice = device

        guard let queue = metalDevice.makeCommandQueue() else {
            logger.log("Failed to create Metal command queue", level: .fatal, category: .onboarding)
            return nil
        }
        commandQueue = queue

        let shaderLibrary: MTLLibrary
        do {
            shaderLibrary = try metalDevice.makeDefaultLibrary(bundle: .module)
        } catch {
            logger.log("Failed to create Metal default library: \(error)", level: .fatal, category: .onboarding)
            return nil
        }

        guard let vertexFunction = shaderLibrary.makeFunction(name: AnimatedGradientUX.vertexShaderFunctionName),
              let fragmentFunction = shaderLibrary.makeFunction(name: AnimatedGradientUX.fragmentShaderFunctionName)
        else {
            logger.log("Missing shader function(s)", level: .fatal, category: .onboarding)
            return nil
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            renderPipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            logger.log("Failed to create render pipeline state: \(error)", level: .fatal, category: .onboarding)
            return nil
        }

        super.init()

        logger.log("AnimatedGradientRenderer initialized successfully", level: .info, category: .onboarding)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        createPreviousFrameTexture(size: size)
    }

    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }

        if shouldRecreateFrameTexture(for: view.drawableSize) {
            createPreviousFrameTexture(size: view.drawableSize)
        }

        encodeRenderCommands(with: renderEncoder)
        renderEncoder.endEncoding()
        copyCurrentFrameToPreviousFrame(from: currentDrawable, using: commandBuffer)
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

        advanceAnimationTime()
    }

    private func createPreviousFrameTexture(size: CGSize) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .renderTarget]
        previousFrameTexture = metalDevice.makeTexture(descriptor: textureDescriptor)
    }

    private func shouldRecreateFrameTexture(for size: CGSize) -> Bool {
        guard let existingTexture = previousFrameTexture else { return true }
        return existingTexture.width != Int(size.width) || existingTexture.height != Int(size.height)
    }

    private func encodeRenderCommands(with encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(renderPipelineState)

        var timeValue = currentTime
        encoder.setFragmentBytes(&timeValue, length: MemoryLayout<Float>.size, index: AnimatedGradientUX.timeBufferIndex)
        encoder.setFragmentTexture(previousFrameTexture, index: AnimatedGradientUX.previousFrameTextureIndex)
        encoder
            .drawPrimitives(
                type: .triangleStrip,
                vertexStart: 0,
                vertexCount: AnimatedGradientUX.fullScreenQuadVertexCount
            )
    }

    private func copyCurrentFrameToPreviousFrame(from drawable: CAMetalDrawable, using commandBuffer: MTLCommandBuffer) {
        guard let destinationTexture = previousFrameTexture,
              let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        else { return }

        blitEncoder.copy(
            from: drawable.texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(width: destinationTexture.width, height: destinationTexture.height, depth: 1),
            to: destinationTexture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
        blitEncoder.endEncoding()
    }

    private func advanceAnimationTime() {
        currentTime += AnimatedGradientUX.timeIncrementPerFrame
    }
}
#else
/// Stub fallback when MetalKit is not available
class AnimatedGradientRenderer {
    let metalDevice: Any? = nil
    init?(logger: Logger = DefaultLogger.shared, device: Any? = nil) {
        logger.log("Metal not supported on this platform. Using fallback renderer.", level: .warning, category: .onboarding)
        return nil
    }
}
#endif

#if false
struct AnimatedGradientMetalViewRepresentable: UIViewRepresentable {
    private weak var delegate: AnimatedGradientRenderer?

    init(delegate: AnimatedGradientRenderer) {
        self.delegate = delegate
    }

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = delegate?.metalDevice as? MTLDevice
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = delegate as? MTKViewDelegate
        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) { }
}
#endif

struct AnimatedGradientMetalView: View {
    @State private var delegate: AnimatedGradientRenderer?

    init(
        metalDevice: Any? = {
            #if false
            return MTLCreateSystemDefaultDevice()
            #else
            return nil
            #endif
        }()
    ) {
        delegate = AnimatedGradientRenderer(device: metalDevice)
    }

    var body: some View {
        if let delegate {
            #if false
            AnimatedGradientMetalViewRepresentable(delegate: delegate)
            #else
            fallbackGradient
            #endif
        } else {
            fallbackGradient
        }
    }

    private var fallbackGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    UX.CardView.vividOrange,
                    UX.CardView.electricBlue,
                    UX.CardView.crimsonRed,
                    UX.CardView.burntOrange
                ]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct AnimatedGradientMetalView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedGradientMetalView()
            .ignoresSafeArea(.all)
    }
}
