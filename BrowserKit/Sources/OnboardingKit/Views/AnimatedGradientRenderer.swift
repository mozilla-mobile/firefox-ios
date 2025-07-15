// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import MetalKit
import Common

enum AnimatedGradientRendererError: Error {
    case failedToCreateCommandQueue
    case failedToCreateDefaultLibrary
    case missingShaderFunction(functionName: String)
    case failedToCreateRenderPipelineState(Error)
    case failedToCreateTexture(size: CGSize)

    var localizedDescription: String {
        switch self {
        case .failedToCreateCommandQueue:
            return "Failed to create Metal command queue"
        case .failedToCreateDefaultLibrary:
            return "Failed to create Metal default library"
        case .missingShaderFunction(let functionName):
            return "Missing shader function: \(functionName)"
        case .failedToCreateRenderPipelineState(let error):
            return "Failed to create render pipeline state: \(error.localizedDescription)"
        case .failedToCreateTexture(let size):
            return "Failed to create texture with size: \(size)"
        }
    }
}

private enum AnimatedGradientUX {
    static let timeIncrementPerFrame: Float = 0.0045
    static let vertexShaderFunctionName = "animatedGradientVertex"
    static let fragmentShaderFunctionName = "animatedGradientFragment"
    static let fullScreenQuadVertexCount = 4
    static let timeBufferIndex = 0
    static let previousFrameTextureIndex = 0
}

class AnimatedGradientRenderer: NSObject, MTKViewDelegate {
    private let logger: Logger = DefaultLogger.shared
    private let metalDevice: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private var currentTime: Float = 0.0
    private var previousFrameTexture: MTLTexture?

    init(device: MTLDevice) throws {
        self.metalDevice = device

        guard let queue = device.makeCommandQueue() else {
            logger.log(
                "Failed to create Metal command queue",
                level: .fatal,
                category: .onboarding
            )
            throw AnimatedGradientRendererError.failedToCreateCommandQueue
        }
        self.commandQueue = queue

        let shaderLibrary: MTLLibrary
        do {
            shaderLibrary = try device.makeDefaultLibrary(bundle: .module)
        } catch {
            logger.log(
                "Failed to create Metal default library: \(error)",
                level: .fatal,
                category: .onboarding
            )
            throw AnimatedGradientRendererError.failedToCreateDefaultLibrary
        }

        guard let vertexFunction = shaderLibrary.makeFunction(name: AnimatedGradientUX.vertexShaderFunctionName) else {
            let errorMessage = "Missing vertex shader function: \(AnimatedGradientUX.vertexShaderFunctionName)"
            logger.log(errorMessage, level: .fatal, category: .onboarding)
            throw AnimatedGradientRendererError.missingShaderFunction(
                functionName: AnimatedGradientUX.vertexShaderFunctionName
            )
        }

        guard let fragmentFunction = shaderLibrary.makeFunction(name: AnimatedGradientUX.fragmentShaderFunctionName) else {
            let errorMessage = "Missing fragment shader function: \(AnimatedGradientUX.fragmentShaderFunctionName)"
            logger.log(errorMessage, level: .fatal, category: .onboarding)
            throw AnimatedGradientRendererError.missingShaderFunction(
                functionName: AnimatedGradientUX.fragmentShaderFunctionName
            )
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            logger.log(
                "Failed to create render pipeline state: \(error)",
                level: .fatal,
                category: .onboarding
            )
            throw AnimatedGradientRendererError.failedToCreateRenderPipelineState(error)
        }

        super.init()

        logger.log(
            "AnimatedGradientRenderer initialized successfully",
            level: .info,
            category: .onboarding
        )
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        do {
            try createPreviousFrameTexture(size: size)
        } catch {
            logger.log(
                "Failed to create previous frame texture: \(error)",
                level: .warning,
                category: .onboarding
            )
        }
    }

    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable else {
            logger.log(
                "No current drawable available",
                level: .warning,
                category: .onboarding
            )
            return
        }

        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            logger.log(
                "No current render pass descriptor available",
                level: .warning,
                category: .onboarding
            )
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            logger.log(
                "Failed to create command buffer",
                level: .warning,
                category: .onboarding
            )
            return
        }

        let currentDrawableSize = view.drawableSize
        if shouldRecreateFrameTexture(for: currentDrawableSize) {
            do {
                try createPreviousFrameTexture(size: currentDrawableSize)
            } catch {
                logger.log(
                    "Failed to recreate previous frame texture: \(error)",
                    level: .warning,
                    category: .onboarding
                )
                return
            }
        }

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            logger.log(
                "Failed to create render command encoder",
                level: .warning,
                category: .onboarding
            )
            return
        }

        encodeRenderCommands(with: renderEncoder)
        renderEncoder.endEncoding()

        copyCurrentFrameToPreviousFrame(
            from: currentDrawable,
            using: commandBuffer
        )

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

        advanceAnimationTime()
    }

    private func createPreviousFrameTexture(size: CGSize) throws {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .renderTarget]

        guard let texture = metalDevice.makeTexture(descriptor: textureDescriptor) else {
            throw AnimatedGradientRendererError.failedToCreateTexture(size: size)
        }

        previousFrameTexture = texture
    }

    private func shouldRecreateFrameTexture(for size: CGSize) -> Bool {
        guard let existingTexture = previousFrameTexture else { return true }

        return existingTexture.width != Int(size.width) ||
               existingTexture.height != Int(size.height)
    }

    private func encodeRenderCommands(with encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(renderPipelineState)

        var timeValue = currentTime
        encoder.setFragmentBytes(
            &timeValue,
            length: MemoryLayout<Float>.size,
            index: AnimatedGradientUX.timeBufferIndex
        )

        encoder.setFragmentTexture(
            previousFrameTexture,
            index: AnimatedGradientUX.previousFrameTextureIndex
        )

        encoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: AnimatedGradientUX.fullScreenQuadVertexCount
        )
    }

    /// Copy current drawable to previousFrameTexture for motion blur
    private func copyCurrentFrameToPreviousFrame(
        from drawable: CAMetalDrawable,
        using commandBuffer: MTLCommandBuffer
    ) {
        guard let destinationTexture = previousFrameTexture else { return }

        guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            logger.log(
                "Failed to create blit command encoder",
                level: .warning,
                category: .onboarding
            )
            return
        }

        blitEncoder.copy(
            from: drawable.texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(
                width: destinationTexture.width,
                height: destinationTexture.height,
                depth: 1
            ),
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

struct AnimatedGradientMetalView: UIViewRepresentable {
    class Coordinator: NSObject, MTKViewDelegate {
        private let logger = DefaultLogger.shared
        private let renderer: AnimatedGradientRenderer?

        init(device: MTLDevice?) {
            if let device = device {
                do {
                    renderer = try AnimatedGradientRenderer(device: device)
                } catch {
                    logger.log("Renderer init failed: \(error)", level: .fatal, category: .onboarding)
                    renderer = nil
                }
            } else {
                logger.log("No Metal device available", level: .fatal, category: .onboarding)
                renderer = nil
            }
            super.init()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer?.mtkView(view, drawableSizeWillChange: size)
        }

        func draw(in view: MTKView) {
            renderer?.draw(in: view)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(device: MTLCreateSystemDefaultDevice())
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) { }
}


struct AnimatedGradientMetalView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedGradientMetalView()
            .ignoresSafeArea(.all)
    }
}
