// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import MetalKit
import Common
import UIKit

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

    init(colors: [UIColor]) {
        precondition(colors.count >= 4, "Exactly 4 colors required")

        self.gradientOnboardingStop1 = SIMD3<Float>(colors[0])
        self.gradientOnboardingStop2 = SIMD3<Float>(colors[1])
        self.gradientOnboardingStop3 = SIMD3<Float>(colors[2])
        self.gradientOnboardingStop4 = SIMD3<Float>(colors[3])
    }

    init(swiftUIColors: [Color]) {
        let uiColors = swiftUIColors.map { UIColor($0) }
        self.init(colors: uiColors)
    }

    init(
        gradientOnboardingStop1: SIMD3<Float>,
        gradientOnboardingStop2: SIMD3<Float>,
        gradientOnboardingStop3: SIMD3<Float>,
        gradientOnboardingStop4: SIMD3<Float>
    ) {
        self.gradientOnboardingStop1 = gradientOnboardingStop1
        self.gradientOnboardingStop2 = gradientOnboardingStop2
        self.gradientOnboardingStop3 = gradientOnboardingStop3
        self.gradientOnboardingStop4 = gradientOnboardingStop4
    }
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

    private weak var metalView: MTKView?
    private var palette = GradientPalette.defaultColors
    private var previousFrameTexture: MTLTexture?
    private var didClearPreviousFrameTexture: Bool = false

    var animationSpeedMultiplier: Float = 1.0 {
        didSet {
            triggerRedraw()
        }
    }

    init?(
        logger: Logger = DefaultLogger.shared,
        device: MTLDevice?,
        speed: Float = 1.0
    ) {
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

        logger
            .log(
                "AnimatedGradientRenderer initialized successfully with speed \(speed)x",
                level: .info,
                category: .onboarding
            )
    }

    // MARK: - Color Injection Methods

    /// Update colors using UIColor array
    func updateColors(_ colors: [UIColor]) {
        let newPalette = GradientPalette(colors: colors)
        updatePaletteForCurrentTheme(palette: newPalette)
    }

    /// Update colors using SwiftUI Color array
    func updateColors(_ colors: [Color]) {
        let newPalette = GradientPalette(swiftUIColors: colors)
        updatePaletteForCurrentTheme(palette: newPalette)
    }

    /// Update individual color by index
    func updateColor(at index: Int, with color: UIColor) {
        var newPalette = palette
        let simdColor = SIMD3<Float>(color)

        switch index {
        case 0: newPalette.gradientOnboardingStop1 = simdColor
        case 1: newPalette.gradientOnboardingStop2 = simdColor
        case 2: newPalette.gradientOnboardingStop3 = simdColor
        case 3: newPalette.gradientOnboardingStop4 = simdColor
        default: break
        }

        updatePaletteForCurrentTheme(palette: newPalette)
    }

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
        previousFrameTexture = makePreviousFrameTexture(for: view)
        didClearPreviousFrameTexture = false
    }

    func draw(in view: MTKView) {
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

        if previousFrameTexture == nil ||
            previousFrameTexture?.width != currentDrawable.texture.width ||
            previousFrameTexture?.height != currentDrawable.texture.height {
            previousFrameTexture = makePreviousFrameTexture(for: view)
            didClearPreviousFrameTexture = false
        }

        if let prevTex = previousFrameTexture, didClearPreviousFrameTexture == false {
            if let clearPassDesc = makeClearPassDescriptor(for: prevTex) {
                if let clearEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: clearPassDesc) {
                    clearEncoder.endEncoding()
                    didClearPreviousFrameTexture = true
                }
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

        if let prevTex = previousFrameTexture {
            renderEncoder.setFragmentTexture(prevTex, index: 0)
        }

        encodeRenderCommands(with: renderEncoder)
        renderEncoder.endEncoding()

        if let prevTex = previousFrameTexture,
           let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
            let src = currentDrawable.texture
            let srcSize = MTLSize(width: src.width, height: src.height, depth: 1)
            blitEncoder.copy(from: src,
                             sourceSlice: 0,
                             sourceLevel: 0,
                             sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                             sourceSize: srcSize,
                             to: prevTex,
                             destinationSlice: 0,
                             destinationLevel: 0,
                             destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blitEncoder.endEncoding()
        }

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
            index: 0
        )

        var currentPalette = palette
        encoder.setFragmentBytes(&currentPalette,
                                 length: MemoryLayout<GradientPalette>.stride,
                                 index: 1)

        var speedMultiplier = animationSpeedMultiplier
        encoder.setFragmentBytes(
            &speedMultiplier,
            length: MemoryLayout<Float>.size,
            index: 2
        )

        encoder.drawPrimitives(
            type: .triangleStrip,
            vertexStart: 0,
            vertexCount: 4
        )
    }

    private func advanceAnimationTime() {
        guard animationSpeedMultiplier != 0 else { return }
        currentTime += 0.0045 * animationSpeedMultiplier
    }

    // MARK: - Helpers

    private func makePreviousFrameTexture(for view: MTKView) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.colorPixelFormat,
            width: max(Int(view.drawableSize.width), 1),
            height: max(Int(view.drawableSize.height), 1),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        return metalDevice.makeTexture(descriptor: descriptor)
    }

    private func makeClearPassDescriptor(for texture: MTLTexture) -> MTLRenderPassDescriptor? {
        let desc = MTLRenderPassDescriptor()
        guard let colorAttachment = desc.colorAttachments[0] else { return nil }
        colorAttachment.texture = texture
        colorAttachment.loadAction = .clear
        colorAttachment.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        colorAttachment.storeAction = .store
        return desc
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Custom colors that can be injected
    private let customColors: [Color]?

    init(
        metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice(),
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        customColors: [Color]? = nil
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.customColors = customColors
        let initialSpeed: Float = UIAccessibility.isReduceMotionEnabled ? 0 : UX.Onboarding.Animation.gradientSpeed
        _rendererStore = StateObject(
            wrappedValue: RendererStore(
                device: metalDevice,
                speed: initialSpeed
            )
        )
    }

    var body: some View {
        if let delegate = rendererStore.renderer {
            AnimatedGradientMetalViewRepresentable(delegate: delegate)
                .onAppear {
                    if let customColors = customColors {
                        // Use custom colors if provided
                        delegate.updateColors(customColors)
                        gradientColors = customColors
                    } else {
                        // Use theme colors
                        applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                    }
                    delegate.animationSpeedMultiplier = reduceMotion ? 0 : UX.Onboarding.Animation.gradientSpeed
                }
                .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                    guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                    if customColors == nil {
                        applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                    }
                }
                .onChange(of: reduceMotion) { newValue in
                    delegate.animationSpeedMultiplier = newValue ? 0 : UX.Onboarding.Animation.gradientSpeed
                }
        } else {
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .onAppear {
                if let customColors = customColors {
                    gradientColors = customColors
                } else {
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                if customColors == nil {
                    applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
                }
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

    // Method to update colors dynamically
    func updateColors(_ colors: [Color]) {
        rendererStore.renderer?.updateColors(colors)
        gradientColors = colors
    }
}

@MainActor
class RendererStore: ObservableObject {
    let renderer: AnimatedGradientRenderer?

    init(device: MTLDevice?, speed: Float) {
        self.renderer = AnimatedGradientRenderer(device: device, speed: speed)
    }
}
