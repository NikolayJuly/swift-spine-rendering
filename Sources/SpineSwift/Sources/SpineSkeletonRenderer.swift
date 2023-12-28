import Foundation
import Metal
import MetalExtension
import SpineSharedStructs
import SpineC

/// When we rendering skeleton, we might want render only lines, for example. Or exclude some black only elements(eye or mouth) for gray scale only image.
public protocol SpineSkeletonBonesFilter {
    func shouldRender(attachment: String) -> Bool
}

public protocol SpineSkeletonRenderer {
    /// Should be called by Skeleton
    func render(attachment: String, mesh: SpineMesh, texture: MTLTexture)
}

public enum AllocationSource<Element> {
    /// No need to deallocate, it should be done by spine later
    case managed(UnsafeMutableBufferPointer<Element>)

    /// Should be deallocated, after usage
    case manual(UnsafeMutableBufferPointer<Element>)

    @inlinable
    var buffer: UnsafeMutableBufferPointer<Element> {
        switch self {
        case let .manual(buffer),
            let .managed(buffer):
            return buffer
        }
    }
}

public struct RenderAllBonesFilter: SpineSkeletonBonesFilter {

    public init() {}

    public func shouldRender(attachment: String) -> Bool {
        return true
    }
}

/// Return true if any of underlaying filters return true
public struct BonesFiltersUnion: SpineSkeletonBonesFilter {

    public init(filters: [SpineSkeletonBonesFilter]) {
        self.filters = filters
    }

    public func shouldRender(attachment: String) -> Bool {
        let index = filters.firstIndex(where: { $0.shouldRender(attachment: attachment) })
        return index != nil
    }

    private let filters: [SpineSkeletonBonesFilter]
}

/// Presentation of mesh data from Skeleton, it might be result of just bone attachment, or clipping or actual mesh deformation
/// Creator of mesh responsible for calling `free()` after it was passed to renderer
public struct SpineMesh {
    public enum AllocationSource<Element> {
        /// No need to deallocate, it should be done by spine later
        case managed(UnsafeMutableBufferPointer<Element>)

        /// Should be deallocated, after usage
        case manual(UnsafeMutableBufferPointer<Element>)

        @inlinable
        var buffer: UnsafeMutableBufferPointer<Element> {
            switch self {
            case let .manual(buffer),
                let .managed(buffer):
                return buffer
            }
        }
    }

    @inlinable
    public var vertices: UnsafeMutableBufferPointer<Float> { verticesStorage.buffer }
    @inlinable
    public var triangles: UnsafeMutableBufferPointer<UInt16> { trianglesStorage.buffer }
    @inlinable
    public var uvs: UnsafeMutableBufferPointer<Float> { uvsStorage.buffer }

    public let verticesStorage: AllocationSource<Float>
    public let trianglesStorage: AllocationSource<UInt16>
    public let uvsStorage: AllocationSource<Float>

    public let zPosition: Float
    public let tintColor: spColor

    public let bounds: FloatRect

    @inlinable
    public var numberOfVerticies: Int { vertices.count / 2 }

    @inlinable
    public var numberOfTriangles: Int { triangles.count / 3 }

    /// - complexity: O(N), we will calculate bounds on a fly, based on `verticesStorage`
    init(verticesStorage: AllocationSource<Float>,
         trianglesStorage: AllocationSource<UInt16>,
         uvsStorage: AllocationSource<Float>,
         zPosition: Float,
         tintColor: spColor) {
        self.verticesStorage = verticesStorage
        self.trianglesStorage = trianglesStorage
        self.uvsStorage = uvsStorage
        self.zPosition = zPosition
        self.tintColor = tintColor

        precondition(Float.stride(of: 2) == FloatPoint.stride(of: 1), "This function works on assumption that 2 floats from Spine make 1 vertex as FloatPoint")
        precondition(verticesStorage.buffer.count >= 6, "We need 6 float, to make 3 vertices for at least 1 triangle")

        precondition(verticesStorage.buffer.count % 2 == 0, "We must have even amount of floats, to form 2d points")
        precondition(trianglesStorage.buffer.count % 3 == 0, "Each triangle have 3 vertex")

        self.bounds = verticesStorage.buffer.withMemoryRebound(to: FloatPoint.self) { pointsBuffer in
            let pVertices = pointsBuffer.baseAddress!
            var currentRect = FloatRect(x: pVertices.pointee.x,
                                        y: pVertices.pointee.y,
                                        width: 0,
                                        height: 0)

            for i in 0..<pointsBuffer.count {
                let floatPoint = pVertices.advanced(by: i).pointee
                currentRect = currentRect.expanded(toInclude: floatPoint)
            }
            return currentRect
        }
    }

    func free() {
        switch verticesStorage {
        case let .manual(buffer): buffer.deallocate()
        case .managed: break
        }

        switch trianglesStorage {
        case let .manual(buffer): buffer.deallocate()
        case .managed: break
        }

        switch uvsStorage {
        case let .manual(buffer): buffer.deallocate()
        case .managed: break
        }
    }
}
