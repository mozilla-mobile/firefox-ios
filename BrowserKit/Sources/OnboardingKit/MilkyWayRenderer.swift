// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import MetalKit

class MilkyWayRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var time: Float = 0.0

    var previousFrameTexture: MTLTexture?

    init(device: MTLDevice = MTLCreateSystemDefaultDevice()!) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        do {
            let library = try device.makeDefaultLibrary(bundle: .module)

            let vertexFunction = library.makeFunction(name: "milky_way_vertex")
            let fragmentFunction = library.makeFunction(name: "milky_way_fragment")

            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

        if previousFrameTexture == nil ||
           previousFrameTexture?.width != Int(view.drawableSize.width) ||
           previousFrameTexture?.height != Int(view.drawableSize.height) {
            createPreviousFrameTexture(size: view.drawableSize)
        }

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        commandEncoder.setFragmentTexture(previousFrameTexture, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        copyCurrentFrameToPrevious(drawable: drawable, commandBuffer: commandBuffer)

        commandBuffer.present(drawable)
        commandBuffer.commit()

        time += 0.0045
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        createPreviousFrameTexture(size: size)
    }

    private func createPreviousFrameTexture(size: CGSize) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .renderTarget]
        previousFrameTexture = device.makeTexture(descriptor: textureDescriptor)
    }

    private func copyCurrentFrameToPrevious(drawable: CAMetalDrawable, commandBuffer: MTLCommandBuffer) {
        guard let previousFrameTexture = previousFrameTexture else { return }

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: drawable.texture,
                          sourceSlice: 0,
                          sourceLevel: 0,
                          sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                          sourceSize: MTLSize(width: previousFrameTexture.width,
                                              height: previousFrameTexture.height,
                                              depth: 1),
                          to: previousFrameTexture,
                          destinationSlice: 0,
                          destinationLevel: 0,
                          destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder?.endEncoding()
    }
}

// MARK: - Metal View
struct MilkyWayMetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = context.coordinator
        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> MilkyWayRenderer {
        return MilkyWayRenderer()
    }
}

struct MetalView_Previews: PreviewProvider {
    static var previews: some View {
        MilkyWayMetalView()
            .edgesIgnoringSafeArea(.all)
    }
}
