import CoreGraphics
import Foundation
import FoundationExtension
import Metal
import MetalKit

public final class GeneralMetalStack {
    public let device: MTLDevice

    public let commandQueue: MTLCommandQueue
    public let pixelFormat: MTLPixelFormat

    public let textureLoader: MTKTextureLoader

    // MARK: Init

    public convenience init(pixelFormat: MTLPixelFormat) throws {
        let device = try MTLCreateSystemDefaultDevice().unwrapped(.noMetalDevice)
        let commandQueue = try device.makeCommandQueue().unwrapped(.failedToMakeCommandQueue)

        self.init(device: device/*, library: library*/, commandQueue: commandQueue, pixelFormat: pixelFormat)
    }


    public init(device: MTLDevice,
                commandQueue: MTLCommandQueue,
                pixelFormat: MTLPixelFormat) {
        self.device = device
        self.commandQueue = commandQueue
        self.pixelFormat = pixelFormat
        self.textureLoader = MTKTextureLoader(device: device)
    }

    // MARK: Textures

    @inlinable
    public func createTexture(from imageUrl: URL) throws -> MTLTexture {
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: false,
        ]
        let texture = try textureLoader.newTexture(URL: imageUrl, options: options)
        precondition(texture.pixelFormat == pixelFormat, "We need consistancy. Change `pixelFormat` in init or change loading implementation")
        return texture
    }

    @inlinable
    public func createTexture(from cgImage: CGImage) throws -> MTLTexture {
        let options: [MTKTextureLoader.Option: Any] = [
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .SRGB: false,
        ]
        return try textureLoader.newTexture(cgImage: cgImage, options: options)
    }

    @inlinable
    public func createTexture(of imageSize: TextureSize,
                              usage: MTLTextureUsage = [.shaderRead, .shaderWrite, .renderTarget],
                              storageMode: MTLStorageMode = .shared) throws -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                         width: imageSize.width,
                                                                         height: imageSize.height,
                                                                         mipmapped: false)
        textureDescriptor.storageMode = storageMode
        textureDescriptor.usage = usage
        return try device.makeTexture(descriptor: textureDescriptor).unwrapped()
    }

    // MARK: Buffers

    /// Here T should be a shared struct with Metal, not gonna work with classes, but no way to require it in compile time
    /// Also not gonna work with array, we will copy array and not its content
    @inlinable
    public func createBuffer<T>(from t: T,
                                resourceOption: MTLResourceOptions = .cpuCacheModeWriteCombined) throws -> MTLBuffer {
        precondition((T.self as? AnyClass) == nil)
        return try withUnsafeBytes(of: t) { [resourceOption] buffer in
            let baseAddress = buffer.baseAddress!
            let buffer = device.makeBuffer(bytes: baseAddress,
                                           length: MemoryLayout<T>.stride,
                                           options: resourceOption)
            return try buffer.unwrapped()
        }
    }

    /// - returns: buffer and offset for it
//    @inlinable
//    public func createBuffer(from imageContext: ImageCreationContext) throws -> (MTLBuffer, Int) {
//        let preallocatedMemory = try imageContext.fullDataBuffer.baseAddress.unwrapped()
//        let keeaAliveWrapper = KeepAliveWrapper(imageContext)
//        let inBufferOrNil = device.makeBuffer(bytesNoCopy: preallocatedMemory,
//                                              length: imageContext.fullDataBuffer.count,
//                                              options: .storageModeShared,
//                                              deallocator: { _, _ in keeaAliveWrapper.dispose() })
//        return (try inBufferOrNil.unwrapped(), imageContext.imageOffset)
//    }

}

private enum GeneralMetalStackError: Error {
    case noMetalDevice
    case failedToMakeCommandQueue
    case noDefaultMetalLibrary
}

private extension Optional {
    func unwrapped(_ error: GeneralMetalStackError) throws -> Wrapped {
        try unwrapped(otherwise: error)
    }
}

