import Foundation
import Logging
import Metal
import MetalExtension
import SpineC
import SpineSharedStructs

public extension Int {
    static let numberOfBuffers: Int = 3
    static let defaultVerticesBufferSize = 64 * 1024 // 64KB
}

public final class SpineViewSkeletonRenderer: SpineSkeletonRenderer, SpineViewRenderer {
    public var currentBufferIndex: Int = 0 {
        didSet {
            precondition(0 <= currentBufferIndex && currentBufferIndex < .numberOfBuffers)
        }
    }

    public var bonesFilter: SpineSkeletonBonesFilter = RenderAllBonesFilter()

    public init(spineSkeleton: SpineSkeleton,
                spineMetalStack: SpineMetalStack,
                logger: Logger) {
        self.spineSkeleton = spineSkeleton
        self.spineMetalStack = spineMetalStack
        self.logger = logger

        self.mainRenderPipelineState = Self.createMainRenderPipelineState(using: spineMetalStack.generalMetalStack)

        increaseBuffersSize(to: .defaultVerticesBufferSize)
    }

    /// Render skeleton using `renderPassDescriptor`. `spineMetalStack` should have updated `screenFrame` before calling this method
    /// - Parameters:
    ///   - renderPassDescriptor: pass descriptor, which already has `colorAttachments[0]` and `depthAttachment`. colorAttachments[0] is texture with output
    ///   - commandBuffer: command buffer, which should be used to group rendering of all needed  skeletons
    public func render(renderPassDescriptor: MTLRenderPassDescriptor,
                       using commandBuffer: MTLCommandBuffer) {

        assert(spineMetalStack.screenFrame.isZero == false)

        self.currentBufferOccupancySize = 0
        self.currentNumberOfVerticies = 0
        self.textures = []
        spineSkeleton.render(in: self, bonesFilter: bonesFilter)

        encodeMainRender(in: commandBuffer,
                         renderPassDescriptor: renderPassDescriptor)
    }

    // MARK: SpineSkeletonRenderer

    public func render(attachment: String, mesh: SpineMesh, texture: MTLTexture) {
        precondition(Float.stride(of: 2) == FloatPoint.stride(of: 1), "This function works on assumption that 2 floats from Spine make 1 vertex as FloatPoint")
        precondition(spineMetalStack.screenFrame.isZero == false)

        // we assume that attachment was filtered and we should render it, if method was called

        var buffer = buffers[currentBufferIndex]
        var initialBufferStart = buffer.contents()
        let bufferSize = buffer.length

        let currentSize = currentBufferOccupancySize

        let textureIndex = textures.insertIfNotPresented(texture)

        let verticesArray = mesh.generateVerticies(textureIndex: CChar(textureIndex))

        let verticesSize = TexturedVertex2D.stride(of: verticesArray.count)

        if currentSize + verticesSize >= bufferSize {

            let minNewSize = currentSize + verticesSize

            // we need more space than buffer has now
            let newBufferSize = max(2 * bufferSize, minNewSize)
            logger.warning("We need increase buffer size for `\(skeletonName)` to \(newBufferSize/1024)KB")
            increaseBuffersSize(to: newBufferSize)

            let newBuffer = buffers[currentBufferIndex]
            let newInitialBufferStart = newBuffer.contents()

            memcpy(newInitialBufferStart, initialBufferStart, currentSize)

            buffer = newBuffer
            initialBufferStart = newInitialBufferStart
        }

        let newVertecesStartPointer = initialBufferStart.advanced(by: currentBufferOccupancySize)

        verticesArray.withUnsafeBytes { verticesBuffer in
            _ = memcpy(newVertecesStartPointer, verticesBuffer.baseAddress, verticesSize)
        }

        currentNumberOfVerticies += verticesArray.count
        currentBufferOccupancySize += verticesSize
    }

    // MARK: Private

    private let spineMetalStack: SpineMetalStack
    private var generalMetalStack: GeneralMetalStack { spineMetalStack.generalMetalStack }

    private let mainRenderPipelineState: MTLRenderPipelineState

    private let spineSkeleton: SpineSkeleton

    private let logger: Logger

    private var buffers = [MTLBuffer]()

    // Below value for current rendering
    // Shows us amount of bytes written to buffer so far
    private var currentBufferOccupancySize = 0
    private var currentNumberOfVerticies = 0
    private var textures = [MTLTexture]()

    private var skeletonName: String { spineSkeleton.name }

    private func increaseBuffersSize(to size: Int) {
        let device = generalMetalStack.device
        buffers = (0 ..< .numberOfBuffers).map { _ in
            device.makeBuffer(length: size, options: .storageModeShared)!
        }
    }

    private func encodeMainRender(in commandBuffer: MTLCommandBuffer,
                                  renderPassDescriptor: MTLRenderPassDescriptor) {
        let commandEncoder = try! commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).unwrapped()
        commandEncoder.label = "Skeleton Rendering: \(skeletonName)"
        commandEncoder.setRenderPipelineState(mainRenderPipelineState)

        let verticesNumber = currentNumberOfVerticies

        commandEncoder.setVertexBuffer(spineMetalStack.screenFrameBuffers[currentBufferIndex], offset: 0, index: 1)

        commandEncoder.setFragmentTextures(textures, range: 0..<textures.count)

        commandEncoder.setVertexBuffer(buffers[currentBufferIndex], offset: 0, index: 0)

        commandEncoder.setDepthStencilState(spineMetalStack.depthState)

        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verticesNumber)
        commandEncoder.endEncoding()
    }

    // MARK: Private

    private static func createMainRenderPipelineState(using generalMetalStack: GeneralMetalStack) -> MTLRenderPipelineState {
        let library = try! generalMetalStack.device.makeDefaultLibrary(bundle: Bundle.module)
        let device = generalMetalStack.device

        #if !targetEnvironment(simulator)
        precondition(device.supportsFamily(.apple3), "We use array of textures in fragment function, so we need some apple3+ GPU family")
        #endif

        let vertexFunction = library.makeFunction(name: "draw_triangles_vertex")!
        let fragmentFunction = library.makeFunction(name: "draw_triangles_fragment")!

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        let colorAttachment = renderPipelineDescriptor.colorAttachments[0]!
        colorAttachment.pixelFormat = generalMetalStack.pixelFormat
        colorAttachment.isBlendingEnabled = true
        colorAttachment.rgbBlendOperation = .add
        colorAttachment.alphaBlendOperation = .add
        colorAttachment.sourceRGBBlendFactor = .sourceAlpha
        colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
        colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        renderPipelineDescriptor.sampleCount = 1
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.depthAttachmentPixelFormat = .spineDepthTexture

        return try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }
}

private extension SpineMesh {
    func generateVerticies(textureIndex: CChar) -> ContiguousArray<TexturedVertex2D> {
        var mutableVertices = ContiguousArray<TexturedVertex2D>()
        mutableVertices.reserveCapacity(triangles.count)

        // we will change order of verteces
        // so first triagle uses vertices 0, 1, 2, second - 3, 4, 5 etc
        // instead of map "triangle vertex index to vertex" map provided by Spine
        for i in 0..<triangles.count {
            let vertexIndexUInt16 = triangles[i]
            let vertexIndex = Int(vertexIndexUInt16)

            let uv: (Float, Float) = (uvs[2 * vertexIndex], uvs[2 * vertexIndex + 1])

            let vertex = TexturedVertex2D(xyz: (vertices[2 * vertexIndex], vertices[2 * vertexIndex + 1], zPosition),
                                          uv: uv,
                                          textureIndex: textureIndex,
                                          tintColor: tintColor)
            mutableVertices.append(vertex)
        }
        return mutableVertices
    }
}

private extension TexturedVertex2D {
    init(xyz: (Float, Float, Float),
         uv: (Float, Float),
         textureIndex: CChar,
         tintColor: spColor) {
        let ucharTintColor = tintColor.simd4
        self = TexturedVertex2D(position: .init(xyz.0, xyz.1, xyz.2),
                                uv: .init(uv.0, uv.1),
                                textureIndex: textureIndex,
                                tintColor: ucharTintColor)
    }
}
