import Foundation
import Metal
import MetalExtension
import SpineC
import SpineC_SwiftImpl
import SpineSharedStructs

public extension UnsafeMutablePointer where Pointee == spSkeletonData {
    @inlinable
    var animations: UnsafeMutablePointer<UnsafeMutablePointer<spAnimation>?> {
        return pointee.animations!
    }

    @inlinable
    func animation(at index: Int) -> UnsafeMutablePointer<spAnimation> {
        return animations.advanced(by: index).pointee!
    }
}

public extension UnsafeMutablePointer where Pointee == spSkeleton {
    @inlinable
    var slotsCount: Int {
        Int(pointee.slotsCount)
    }

    @inlinable
    var color: spColor {
        pointee.color
    }

    @inlinable
    func drawSlot(at index: Int) -> UnsafeMutablePointer<spSlot> {
        let start = pointee.drawOrder!
        let position = start.advanced(by: index)
        return position.pointee!
    }
}

public extension UnsafeMutablePointer where Pointee == spSlot {
    @inlinable
    var attachment: UnsafeMutablePointer<spAttachment>? {
        pointee.attachment
    }

    @inlinable
    var bone: UnsafeMutablePointer<spBone> {
        pointee.bone
    }

    @inlinable
    var slotData: UnsafeMutablePointer<spSlotData> {
        pointee.data
    }

    @inlinable
    func slotName() -> String {
        return slotData.slotName()
    }

    @inlinable
    var color: spColor {
        pointee.color
    }
}

public extension UnsafeMutablePointer where Pointee == spSlotData {

    @inlinable
    var blendMode: spBlendMode {
        pointee.blendMode
    }

    @inlinable
    func slotName() -> String {
        return String(cString: pointee.name, encoding: .utf8)!
    }
}

public enum AttachmentType {
    case region
    case mesh
    case clipping
}

public extension UnsafeMutablePointer where Pointee == spAttachment {
    @inlinable
    var spAttachmentType: spAttachmentType {
        pointee.type
    }

    @inlinable
    var attachmentType: AttachmentType {
        switch pointee.type {
        case SP_ATTACHMENT_REGION:
            return .region
        case SP_ATTACHMENT_MESH:
            return .mesh
        case SP_ATTACHMENT_CLIPPING:
            return .clipping
        default:
            fatalError("Implement me")
        }
    }

    @inlinable
    var regionAttachment: UnsafeMutablePointer<spRegionAttachment> {
        let opaquePointer = OpaquePointer(self)
        return UnsafeMutablePointer<spRegionAttachment>(opaquePointer)
    }

    @inlinable
    var meshAttachment: UnsafeMutablePointer<spMeshAttachment> {
        let opaquePointer = OpaquePointer(self)
        return UnsafeMutablePointer<spMeshAttachment>(opaquePointer)
    }

    @inlinable
    var clippinAttachment: UnsafeMutablePointer<spClippingAttachment> {
        let opaquePointer = OpaquePointer(self)
        return UnsafeMutablePointer<spClippingAttachment>(opaquePointer)
    }

    @inlinable
    func attachmentName() -> String {
        String(cString: pointee.name)
    }

    @inlinable
    func atlasRegionName() -> String {
        switch attachmentType {
        case .region:
            return regionAttachment.rendererObject.atlasRegionName()
        case .mesh:
            return meshAttachment.rendererObject.atlasRegionName()
        case .clipping:
            return ""
        }
    }
}

public typealias UVQuad = (Float, Float, Float, Float, Float, Float, Float, Float)

public extension UnsafeMutablePointer where Pointee == spRegionAttachment {
    @inlinable
    var rendererObject: UnsafeMutablePointer<spAtlasRegion> {
        pointee.rendererObject.assumingMemoryBound(to: spAtlasRegion.self)
    }

    @inlinable
    var uvs: UVQuad {
        pointee.uvs
    }

    @inlinable
    var color: spColor {
        pointee.color
    }
}

public extension UnsafeMutablePointer where Pointee == spMeshAttachment {
    @inlinable
    var rendererObject: UnsafeMutablePointer<spAtlasRegion> {
        pointee.rendererObject.assumingMemoryBound(to: spAtlasRegion.self)
    }

    @inlinable
    var `super`: spVertexAttachment {
        pointee.super
    }

    @inlinable
    var superPointer: UnsafeMutablePointer<spVertexAttachment> {
        // I assume that `super` declared as first property, and basically, I know that pointer to self is pointer to `super`
        let opaquePointer = OpaquePointer(self)
        return UnsafeMutablePointer<spVertexAttachment>(opaquePointer)
    }

    @inlinable
    var worldVerticesLength: Int {
        Int(pointee.super.worldVerticesLength)
    }

    @inlinable
    var worldVerticesLengthInt32: Int32 {
        pointee.super.worldVerticesLength
    }

    @inlinable
    var trianglesCount: Int {
        Int(pointee.trianglesCount)
    }

    @inlinable
    var triangles: UnsafeMutablePointer<UInt16> {
        pointee.triangles
    }

    /// map trigles vertex index to worldVertices index
    @inlinable
    func triagleVertexIndex(at index: Int) -> Int {
        let shiftedPointer = triangles.advanced(by: index)
        // all vertices are (x, y) and we getting index of couple
        // so *2 to make sure we getting position of x for vertex at index
        return Int(shiftedPointer.pointee << 1)
    }

    @inlinable
    var trinaglesBuffer: UnsafeMutableBufferPointer<UInt16> {
        UnsafeMutableBufferPointer<UInt16>(start: triangles, count: trianglesCount)
    }

    @inlinable
    var uvs: UnsafeMutablePointer<Float> {
        pointee.uvs
    }

    @inlinable
    func vertexUV(at index: Int) -> (Float, Float) {
        let uPosition = uvs.advanced(by: index)
        let vPosition = uvs.advanced(by: index+1)
        return (uPosition.pointee, vPosition.pointee)
    }

    @inlinable
    var uvsBuffer: UnsafeMutableBufferPointer<Float> {
        UnsafeMutableBufferPointer<Float>(start: uvs, count: 2 * trianglesCount)
    }

    @inlinable
    var color: spColor {
        pointee.color
    }
}

public extension UnsafeMutablePointer where Pointee == spClippingAttachment {
    @inlinable
    var `super`: spVertexAttachment {
        pointee.super
    }

    @inlinable
    var superPointer: UnsafeMutablePointer<spVertexAttachment> {
        // I assume that `super` declared as first property, and basically, I know that pointer to self is pointer to `super`
        let opaquePointer = OpaquePointer(self)
        return UnsafeMutablePointer<spVertexAttachment>(opaquePointer)
    }

    @inlinable
    var worldVerticesLength: Int {
        Int(pointee.super.worldVerticesLength)
    }

    @inlinable
    var worldVerticesLengthInt32: Int32 {
        pointee.super.worldVerticesLength
    }
}

public extension UnsafeMutablePointer where Pointee == spAnimationState {
    @inlinable
    var userData: UnsafeMutableRawPointer? {
        get { pointee.userData }
        nonmutating set { pointee.userData = newValue }
    }

    @inlinable
    var listener: spAnimationStateListener {
        get { pointee.listener }
        nonmutating set { pointee.listener = newValue }
    }

    /// On set `t` will be retained
    @inlinable
    func setUserData<T: AnyObject>(_ t: T) {
        let unmanaged = Unmanaged.passRetained(t)
        userData = unmanaged.toOpaque()
    }

    @inlinable
    func readUserData<T: AnyObject>() -> Unmanaged<T>? {
        guard let existedUserData = userData else {
            return nil
        }
        return Unmanaged<T>.fromOpaque(existedUserData)
    }
}


public extension UnsafeMutablePointer where Pointee == spTrackEntry {

    @inlinable
    var listener: spAnimationStateListener {
        get { pointee.listener }
        nonmutating set { pointee.listener = newValue }
    }

    @inlinable
    var userData: UnsafeMutableRawPointer? {
        get { pointee.userData }
        nonmutating set { pointee.userData = newValue }
    }

    @inlinable
    var animation: UnsafeMutablePointer<spAnimation> {
        pointee.animation
    }

    /// On set `t` will be retained
    @inlinable
    func setUserData<T: AnyObject>(_ t: T) {
        let unmanaged = Unmanaged.passRetained(t)
        userData = unmanaged.toOpaque()
    }

    @inlinable
    func readUserData<T: AnyObject>() -> Unmanaged<T>? {
        guard let existedUserData = userData else {
            return nil
        }
        return Unmanaged<T>.fromOpaque(existedUserData)
    }
}

public extension UnsafeMutablePointer where Pointee == spAnimation {

    @inlinable
    func animationName() -> String {
        return String(cString: pointee.name, encoding: .utf8)!
    }
}


public extension spAttachmentType {
    var stringRawValue: String {
        switch self {
        case SP_ATTACHMENT_REGION:
            return "spAttachmentType.Region"
        case SP_ATTACHMENT_BOUNDING_BOX:
            return "spAttachmentType.boundingBox"
        case SP_ATTACHMENT_MESH:
            return "spAttachmentType.mesh"
        case SP_ATTACHMENT_LINKED_MESH:
            return "spAttachmentType.linkedList"
        case SP_ATTACHMENT_PATH:
            return "spAttachmentType.path"
        case SP_ATTACHMENT_POINT:
            return "spAttachmentType.point"
        case SP_ATTACHMENT_CLIPPING:
            return "spAttachmentType.clipping"
        default:
            fatalError("Unknown spAttachmentType: raw value is \(rawValue)")
        }
    }
}

public extension UnsafeMutablePointer where Pointee == spAtlasPage {
    @inlinable
    func rendererTexture<T: AnyObject>() -> T {
        typealias RenderedObject = SpineImplementations<T>.RenderedObject
        let unamanged = Unmanaged<RenderedObject>.fromOpaque(pointee.rendererObject)
        return unamanged.takeUnretainedValue().texture
    }

    @inlinable
    func atlasPageName() -> String {
        String(cString: pointee.name, encoding: .utf8)!
    }

    @inlinable
    var width: Int {
        Int(pointee.width)
    }

    @inlinable
    var heigth: Int {
        Int(pointee.height)
    }

    @inlinable
    var next: UnsafeMutablePointer<spAtlasPage>? {
        pointee.next
    }
}

public extension UnsafeMutablePointer where Pointee == spAtlasRegion {

    @inlinable
    func atlasRegionName() -> String {
        String(cString: pointee.name, encoding: .utf8)!
    }

    @inlinable
    var x: Int {
        Int(pointee.x)
    }

    @inlinable
    var y: Int {
        Int(pointee.y)
    }

    // Here is a special case: if degree is 90, we need to rotate width and height
    // Spine code doing it to calculae max UV
    @inlinable
    var width: Int {
        Int(pointee.super.degrees == 90 ? pointee.super.height : pointee.super.width)
    }

    // Here is a special case: if degree is 90, we need to rotate width and height
    // Spine code doing it to calculae max UV
    @inlinable
    var heigth: Int {
        Int(pointee.super.degrees == 90 ? pointee.super.width : pointee.super.height)
    }

    @inlinable
    var degrees: Int {
        Int(pointee.super.degrees)
    }

    @inlinable
    var textureRect: TextureRect {
        return TextureRect(x: x, y: y, width: width, height: heigth)
    }

    @inlinable
    var index: Int {
        Int(pointee.index)
    }

    @inlinable
    var atlasPage: UnsafeMutablePointer<spAtlasPage> {
        pointee.page
    }

    @inlinable
    var next: UnsafeMutablePointer<spAtlasRegion>? {
        pointee.next
    }
}

public extension UnsafeMutablePointer where Pointee == spAtlas {
    @inlinable
    var pages: UnsafeMutablePointer<spAtlasPage>? {
        pointee.pages
    }

    @inlinable
    var regions: UnsafeMutablePointer<spAtlasRegion>? {
        pointee.regions
    }
}

public extension UnsafeMutablePointer where Pointee == spSkeletonClipping {
    @inlinable
    var clippedVerticesBuffer: UnsafeMutableBufferPointer<Float> {
        let count = Int(pointee.clippedVertices.pointee.size)
        return UnsafeMutableBufferPointer<Float>(start: pointee.clippedVertices.pointee.items,
                                                 count: count)
    }

    @inlinable
    var clippedTrianglesBuffer: UnsafeMutableBufferPointer<UInt16> {
        let count = Int(pointee.clippedTriangles.pointee.size)
        return UnsafeMutableBufferPointer<UInt16>(start: pointee.clippedTriangles.pointee.items,
                                                 count: count)
    }

    @inlinable
    var clippedUvsBuffer: UnsafeMutableBufferPointer<Float> {
        let count = Int(pointee.clippedTriangles.pointee.size)
        return UnsafeMutableBufferPointer<Float>(start: pointee.clippedUVs.pointee.items,
                                                  count: 2 * count)
    }
}

public extension UnsafeMutablePointer where Pointee == spSkeletonJson {
    @inlinable
    var error: String? {
        pointee.error.map { String(cString: $0, encoding: .utf8)! }
    }
}

