// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import MetalKit
import Common

enum MilkyWayRendererError: Error {
    case failedToCreateCommandQueue
    case missingShaderFunction(name: String)
}

class MilkyWayRenderer: NSObject, MTKViewDelegate {
    // MARK: – Logger
    private var logger: Logger = DefaultLogger.shared

    // MARK: – Properties
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState

    private var time: Float = 0.0
    private let timeIncrement: Float = 0.0045

    private var previousFrameTexture: MTLTexture?

    // MARK: – Init
    init(device: MTLDevice = MTLCreateSystemDefaultDevice()!) throws {
        self.device = device

        // Command queue
        guard let queue = device.makeCommandQueue() else {
            logger.log(
                "Failed to create Metal command queue",
                level: .fatal,
                category: .onboarding
            )
            throw MilkyWayRendererError.failedToCreateCommandQueue
        }
        self.commandQueue = queue

        // Shader functions
        let library = try device.makeDefaultLibrary(bundle: .module)
        guard
            let vfn = library.makeFunction(name: "milky_way_vertex"),
            let ffn = library.makeFunction(name: "milky_way_fragment")
        else {
            let msg = "Missing shader functions milky_way_vertex / milky_way_fragment"
            logger.log(msg, level: .fatal, category: .onboarding)
            throw MilkyWayRendererError.missingShaderFunction(name: msg)
        }

        // Pipeline
        let pd = MTLRenderPipelineDescriptor()
        pd.vertexFunction   = vfn
        pd.fragmentFunction = ffn
        pd.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.pipelineState = try device.makeRenderPipelineState(descriptor: pd)

        super.init()

        logger.log(
            "MilkyWayRenderer initialized successfully",
            level: .info,
            category: .onboarding
        )
    }

    // MARK: – MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        createPreviousFrameTexture(size: size)
    }

    func draw(in view: MTKView) {
        // Acquire drawable
        guard let drawable = view.currentDrawable else {
            logger.log(
                "No currentDrawable available",
                level: .warning,
                category: .onboarding
            )
            return
        }

        // Acquire render pass descriptor
        guard let rpd = view.currentRenderPassDescriptor else {
            logger.log(
                "No currentRenderPassDescriptor",
                level: .warning,
                category: .onboarding
            )
            return
        }

        // Make command buffer
        guard let cmdBuf = commandQueue.makeCommandBuffer() else {
            logger.log(
                "Failed to create commandBuffer",
                level: .warning,
                category: .onboarding
            )
            return
        }

        // Resize history texture if needed
        if previousFrameTexture?.width  != Int(view.drawableSize.width) ||
           previousFrameTexture?.height != Int(view.drawableSize.height) {
            createPreviousFrameTexture(size: view.drawableSize)
        }

        // Encode draw commands
        guard let encoder = cmdBuf.makeRenderCommandEncoder(descriptor: rpd) else {
            logger.log(
                "Failed to create renderCommandEncoder",
                level: .warning,
                category: .onboarding
            )
            return
        }
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&time,
                                 length: MemoryLayout<Float>.size,
                                 index: 0)
        encoder.setFragmentTexture(previousFrameTexture,
                                   index: 0)
        encoder.drawPrimitives(type: .triangleStrip,
                               vertexStart: 0,
                               vertexCount: 4)
        encoder.endEncoding()

        // Blit into history
        copyCurrentFrameToPrevious(drawable: drawable,
                                   commandBuffer: cmdBuf)

        // Present & commit
        cmdBuf.present(drawable)
        cmdBuf.commit()

        // Advance time
        time += timeIncrement
    }

    // MARK: – Helpers
    private func createPreviousFrameTexture(size: CGSize) {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        desc.usage = [.shaderRead, .renderTarget]
        previousFrameTexture = device.makeTexture(descriptor: desc)
    }

    private func copyCurrentFrameToPrevious(drawable: CAMetalDrawable,
                                            commandBuffer: MTLCommandBuffer) {
        guard let history = previousFrameTexture else { return }
        let blit = commandBuffer.makeBlitCommandEncoder()
        blit?.copy(
            from: drawable.texture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSize(
                width: history.width,
                height: history.height,
                depth: 1
            ),
            to: history,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0)
        )
        blit?.endEncoding()
    }
}

// MARK: – SwiftUI Bridge
struct MilkyWayMetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) { }

    func makeCoordinator() -> MilkyWayRenderer {
        do {
            return try MilkyWayRenderer()
        } catch {
            // If init fails here, it’s truly unrecoverable
            DefaultLogger.shared.log(
                "Fatal: could not instantiate MilkyWayRenderer – \(error)",
                level: .fatal,
                category: .onboarding
            )
            fatalError("MilkyWayRenderer init failed: \(error)")
        }
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        MilkyWayMetalView()
            .edgesIgnoringSafeArea(.all)
    }
}
