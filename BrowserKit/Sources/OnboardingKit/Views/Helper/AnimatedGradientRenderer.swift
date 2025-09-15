// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import MetalKit
import Common

struct GradientPalette {
    var gradientOnboardingStop1: SIMD3<Float>
    var gradientOnboardingStop2: SIMD3<Float>
    var gradientOnboardingStop3: SIMD3<Float>
    var gradientOnboardingStop4: SIMD3<Float>

    static let defaultColors = GradientPalette(
        gradientOnboardingStop1: SIMD3<Float>(0.996, 0.514, 0.000),
        gradientOnboardingStop2: SIMD3<Float>(0.180, 0.506, 0.996),
        gradientOnboardingStop3: SIMD3<Float>(0.949, 0.020, 0.004),
        gradientOnboardingStop4: SIMD3<Float>(0.996, 0.396, 0.000)
    )
}

private enum AnimatedGradientUX {
    static let timeIncrementPerFrame: Float = 0.0045
    static let vertexShaderFunctionName = "animatedGradientVertex"
    static let fragmentShaderFunctionName = "animatedGradientFragment"
    static let fullScreenQuadVertexCount = 4
    static let timeBufferIndex = 0
}

extension SIMD3 where Scalar == Float {
    init(_ color: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(Float(r), Float(g), Float(b))
    }
}

@MainActor
class AnimatedGradientRenderer: NSObject, MTKViewDelegate {
    private let logger: Logger
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private var currentTime: Float = 0.0
    let metalDevice: MTLDevice

    // Add a weak reference to the MTKView to trigger redraws
    private weak var metalView: MTKView?

    private var palette = GradientPalette.defaultColors

    // Configurable animation speed multiplier (1.0 = normal, 2.0 = 2x faster, etc.)
    var animationSpeedMultiplier: Float = 1.0 {
        didSet {
            triggerRedraw()
        }
    }

    init?(logger: Logger = DefaultLogger.shared, device: MTLDevice?, speed: Float = 1.0) {
        self.logger = logger

        if let device {
            metalDevice = device
        } else {
            logger.log("No Metal device available", level: .fatal, category: .onboarding)
            return nil
        }

        guard let queue = metalDevice.makeCommandQueue() else {
            logger.log(
                "Failed to create Metal command queue",
                level: .fatal,
                category: .onboarding
            )
            return nil
        }
        commandQueue = queue

        let shaderLibrary: MTLLibrary
        do {
            shaderLibrary = try metalDevice.makeDefaultLibrary(bundle: .module)
        } catch {
            logger.log(
                "Failed to create Metal default library: \(error)",
                level: .fatal,
                category: .onboarding
            )
            return nil
        }

        guard let vertexFunction = shaderLibrary.makeFunction(name: AnimatedGradientUX.vertexShaderFunctionName) else {
            let errorMessage = "Missing vertex shader function: \(AnimatedGradientUX.vertexShaderFunctionName)"
            logger.log(errorMessage, level: .fatal, category: .onboarding)
            return nil
        }

        guard let fragmentFunction = shaderLibrary.makeFunction(name: AnimatedGradientUX.fragmentShaderFunctionName) else {
            let errorMessage = "Missing fragment shader function: \(AnimatedGradientUX.fragmentShaderFunctionName)"
            logger.log(errorMessage, level: .fatal, category: .onboarding)
            return nil
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            renderPipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            logger.log(
                "Failed to create render pipeline state: \(error)",
                level: .fatal,
                category: .onboarding
            )
            return nil
        }

        super.init()

        // Set the initial speed
        self.animationSpeedMultiplier = speed

        updatePaletteForCurrentTheme(palette: palette)

        logger.log(
            "AnimatedGradientRenderer initialized successfully with speed \(speed)x",
            level: .info,
            category: .onboarding
        )
    }

    // Method to set the MTKView reference
    func setMetalView(_ view: MTKView) {
        metalView = view
    }

    func updatePaletteForCurrentTheme(palette: GradientPalette) {
        self.palette = palette
        triggerRedraw()
    }

    private func triggerRedraw() {
        metalView?.setNeedsDisplay()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Simple implementation - no complex texture management
    }

    func draw(in view: MTKView) {
        // Store reference to view if not already set
        if metalView == nil {
            metalView = view
        }

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

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()

        advanceAnimationTime()
    }

    private func encodeRenderCommands(with encoder: MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(renderPipelineState)

        var timeValue = currentTime
        encoder.setFragmentBytes(
            &timeValue,
            length: MemoryLayout<Float>.size,
            index: AnimatedGradientUX.timeBufferIndex
        )

        var currentPalette = palette
        encoder.setFragmentBytes(&currentPalette,
                                 length: MemoryLayout<GradientPalette>.stride,
                                 index: 1)

        // Pass the speed multiplier to the shader
        var speedMultiplier = animationSpeedMultiplier
        encoder.setFragmentBytes(
            &speedMultiplier,
            length: MemoryLayout<Float>.size,
            index: 2
        )

        encoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: AnimatedGradientUX.fullScreenQuadVertexCount
        )
    }

    private func advanceAnimationTime() {
        currentTime += AnimatedGradientUX.timeIncrementPerFrame * animationSpeedMultiplier
    }
}

struct AnimatedGradientMetalViewRepresentable: UIViewRepresentable {
    private weak var delegate: AnimatedGradientRenderer?

    init(delegate: AnimatedGradientRenderer) {
        self.delegate = delegate
    }

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = delegate?.metalDevice
        metalView.framebufferOnly = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.delegate = delegate

        // Set the view reference in the delegate so it can trigger redraws
        delegate?.setMetalView(metalView)

        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Ensure the delegate still has the view reference
        delegate?.setMetalView(uiView)
    }
}

struct AnimatedGradientMetalView: View {
    @State private var gradientColors: [Color] = []
    @StateObject private var rendererStore: RendererStore
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(
        metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice(),
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        _rendererStore = StateObject(wrappedValue: RendererStore(device: metalDevice, speed: 3.0))
    }

    var body: some View {
        if let delegate = rendererStore.renderer {
            AnimatedGradientMetalViewRepresentable(delegate: delegate)
                .onAppear {
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
                .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                    guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
        } else {
            LinearGradient(
                gradient: Gradient(
                    colors: gradientColors
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .onAppear {
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
        }
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        gradientColors = [
            Color(color.gradientOnboardingStop1),
            Color(color.gradientOnboardingStop2),
            Color(color.gradientOnboardingStop3),
            Color(color.gradientOnboardingStop4)
        ]

        rendererStore.renderer?.updatePaletteForCurrentTheme(
            palette: GradientPalette(
                gradientOnboardingStop1: SIMD3<Float>(color.gradientOnboardingStop1),
                gradientOnboardingStop2: SIMD3<Float>(color.gradientOnboardingStop2),
                gradientOnboardingStop3: SIMD3<Float>(color.gradientOnboardingStop3),
                gradientOnboardingStop4: SIMD3<Float>(color.gradientOnboardingStop4)
            )
        )
    }
}

// Wrapper class to manage the optional renderer
@MainActor
class RendererStore: ObservableObject {
    let renderer: AnimatedGradientRenderer?

    init(device: MTLDevice?, speed: Float) {
        self.renderer = AnimatedGradientRenderer(device: device, speed: speed)
    }
}
