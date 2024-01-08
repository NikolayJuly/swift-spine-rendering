import Foundation
import FoundationExtension
import Metal
import MetalExtension
import MetalKit
import SpineSharedStructs

#if canImport(UIKit)
import UIKit
#endif

extension ScreenFrame: Sizable { }

public extension ScreenFrame {
    static let zero = ScreenFrame(origin: .zero, size: .zero)

    @inlinable
    var isZero: Bool {
        return size.width * size.height < 1e-3
    }

    @inlinable
    var cgRect: CGRect {
        CGRect(x: CGFloat(origin.x),
               y: CGFloat(origin.y),
               width: CGFloat(size.width),
               height: CGFloat(size.height))
    }

    init(rect: CGRect) {
        let floatOrigin = simd_float2(x: Float(rect.origin.x),
                                      y: Float(rect.origin.y))
        let floatSize = simd_float2(width: Float(rect.size.width),
                                    height: Float(rect.size.height))
        self.init(origin: floatOrigin, size: floatSize)
    }

    init(x: CGFloat,
         y: CGFloat,
         width: CGFloat,
         height: CGFloat) {
        let floatOrigin = simd_float2(x: Float(x),
                                      y: Float(y))
        let floatSize = simd_float2(width: Float(width),
                                    height: Float(height))
        self.init(origin: floatOrigin, size: floatSize)
    }
}

public final class SpineMetalStack {

    public let generalMetalStack: GeneralMetalStack

    public let renderAreaSize: TextureSize

    public let textureLoader: MTKTextureLoader

    public let depthState: MTLDepthStencilState

    private(set)
    public var screenFrame: ScreenFrame = .zero

    public let screenFrameBuffers: [MTLBuffer]

    public let captureScope: MTLCaptureScope

#if canImport(UIKit) && !targetEnvironment(macCatalyst)
    public convenience init() throws {
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.nativeScale
        let scaledSize = scale * screenSize
        try self.init(renderAreaSize: scaledSize.containingTextureSize)
    }
#endif // canImport(UIKit)

    /// Create ``SpineMetalStack`` with default `mainRenderPipelineState`, based on metal functions in `SpineSwift`
    /// - Parameters:
    ///   - renderAreaSize: Should be in pixels, so if screen has scale - multiply on it
    public convenience init(renderAreaSize: TextureSize) throws {
        let generalMetalStack = try GeneralMetalStack(pixelFormat: .spineTexture)
        try self.init(generalMetalStack: generalMetalStack,
                      renderAreaSize: renderAreaSize)
    }

    /// - parameter renderAreaSize: Should be in pixels, so if screen has scale - multiply on it
    public init(generalMetalStack: GeneralMetalStack,
                renderAreaSize: TextureSize) throws {
        precondition(generalMetalStack.pixelFormat == .spineTexture, "Incorrect pixel format, we expect `MTLPixelFormat.spineTexture`")
        self.renderAreaSize = renderAreaSize
        self.generalMetalStack = generalMetalStack

        let device = generalMetalStack.device
        self.textureLoader = MTKTextureLoader(device: device)

        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true

        self.depthState = try device.makeDepthStencilState(descriptor: depthDescriptor).unwrapped()

        var screenFrameBuffers = [MTLBuffer]()
        for _ in 0..<Int.numberOfBuffers {
            let buffer = device.makeBuffer(length: ScreenFrame.size, options: .cpuCacheModeWriteCombined)!
            memset(buffer.contents(), 0, ScreenFrame.size)
            screenFrameBuffers.append(buffer)
        }

        self.screenFrameBuffers = screenFrameBuffers

        let sharedCapturer = MTLCaptureManager.shared()
        let captureScope = sharedCapturer.makeCaptureScope(device: generalMetalStack.device)
        captureScope.label = "Capture spine animation shader"
        self.captureScope = captureScope
        sharedCapturer.defaultCaptureScope = captureScope
    }

    /// - parameter index: index of buffer to write to. We using buffereing for 3 frames. Check `SpineView.update()` for more details
    public func set(_ screenFrame: CGRect, for index: Int) {
        assert(!screenFrame.isEmpty)
        assert(index < Int.numberOfBuffers)

        let contentSize = renderAreaSize.cgSize
        let xScale = screenFrame.width/contentSize.width
        let yScale = screenFrame.height/contentSize.height
        let scale = min(xScale, yScale)
        let scaledSize = scale * contentSize

        let screenFrame = ScreenFrame(x: screenFrame.origin.x - 0.5 * (scaledSize.width - screenFrame.size.width),
                                      y: screenFrame.origin.y - 0.5 * (scaledSize.height - screenFrame.size.height),
                                      width: scaledSize.width,
                                      height: scaledSize.height)

        self.screenFrame = screenFrame

        let mtlBuffer = screenFrameBuffers[index]

        withUnsafeBytes(of: screenFrame) { buffer in
            _ = memcpy(mtlBuffer.contents(), buffer.baseAddress, buffer.count)
        }
    }
}

