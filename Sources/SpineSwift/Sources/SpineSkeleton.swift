import Foundation
import FoundationExtension
import Logging
import Metal
import MetalExtension
import MetalKit
import simd
import SpineC
import SpineSharedStructs

public struct SpineSkeletonAnimation {
    public let name: String
    public let duration: TimeInterval
}

// FIXME: We have in-efficiency here. For every frame we allocate a lot of memory for meshes and do not reuse it
//        Ideally we should create big memory pool and write mesh data to it, and reuse it in every frame
public final class SpineSkeleton {

    public typealias Animation = SpineSkeletonAnimation

    /// Control animation speed, default value is 1.0
    public var speed: Float = 1.0

    public let name: String
    public let animations: [Animation]

    public let atlas: SpineAtlas
    public let pSkeletonData: UnsafeMutablePointer<spSkeletonData>
    public let pSkeleton: UnsafeMutablePointer<spSkeleton>

    /// - parameter name: name of skeleton to load in this folder
    /// - parameter animationFolderUrl: URL to folder with atlas.txt, skeleton and atlas png
    ///                                 We expect one  file of each time
    public init(name: String,
                animationFolderUrl: URL,
                logger: Logger) throws {
        self.logger = logger

        let atlas = try SpineAtlas(name: name, animationFolderUrl: animationFolderUrl)
        let fileSystemService: FileSystemService = FileManager.default

        // UnsafeMutablePointer<spSkeletonJson>
        let pSkeletonJson = spSkeletonJson_create(atlas.pAtlas)
        guard let pSkeletonJson else {
            throw SpineSkeletonError.failedToLoadSkeletonJson(name, animationFolderUrl)
        }
        defer {
            spSkeletonJson_dispose(pSkeletonJson)
        }

        // TODO: This looks strange - we compare name with only 1 possible match
        //       We should just try to read 1 file
        let matchingJson: (URL) -> Bool = { url in
            let filename = url.lastPathComponent
            return filename == name + ".json"
        }

        let files = try fileSystemService.findAllFiles(in: animationFolderUrl,
                                                       recusrsively: false,
                                                       validate: matchingJson)

        guard files.count == 1 else {
            throw SpineSkeletonError.failedToFindSkeletonJson(name, animationFolderUrl)
        }

        let skeletonJsonUrl = try files.first.unwrapped()

        let jsonPathCString = skeletonJsonUrl.path.cString(using: .utf8)

        // UnsafeMutablePointer<spSkeletonData>
        let pSkeletonData = spSkeletonJson_readSkeletonDataFile(pSkeletonJson, jsonPathCString)
        guard let pSkeletonDataUnwrapped = pSkeletonData else {
            throw SpineSkeletonError.failedToCreateSkeletonData(name, skeletonJsonUrl, pSkeletonJson.error)
        }

        let pSkeleton = spSkeleton_create(pSkeletonDataUnwrapped)
        guard let pSkeletonUnwrapped = pSkeleton else {
            throw SpineSkeletonError.failedToCreateSkeleton(name, skeletonJsonUrl)
        }

        spSkeleton_updateWorldTransform(pSkeleton)

        // UnsafeMutablePointer<spAnimationStateData>
        let pAnimationStateData = spAnimationStateData_create(pSkeletonDataUnwrapped)

        // UnsafeMutablePointer<spAnimationState>!
        let pAnimationState = spAnimationState_create(pAnimationStateData)
        guard let pAnimationStateUnwrapped = pAnimationState else {
            throw SpineSkeletonError.failedToCreateAnimationState(name, animationFolderUrl)
        }

        guard let pSkeletonClipping = spSkeletonClipping_create() else {
            throw SpineSkeletonError.failedToCreateClipping
        }

        self.name = name
        self.atlas = atlas
        self.pSkeleton = pSkeletonUnwrapped
        self.pAnimationState = pAnimationStateUnwrapped
        self.pSkeletonData = pSkeletonDataUnwrapped
        self.pSkeletonClipping = pSkeletonClipping

        self.animations = try Self.parseAnimationNames(from: pSkeletonDataUnwrapped)
    }

    deinit {
        spSkeletonClipping_dispose(pSkeletonClipping);
        spSkeleton_dispose(pSkeleton)
        spSkeletonData_dispose(pSkeletonData)
        spAnimationState_dispose(pAnimationState)
    }

    public func currentAnimation() -> String? {
        let pTrackEntryOrNil = spAnimationState_getCurrent(pAnimationState, 0)
        guard let pTrackEntry = pTrackEntryOrNil else {
            return nil
        }

        return pTrackEntry.animation.animationName()
    }

    /// - parameter completion: can be called mutiple times,  if animation is in the loop
    public func setAnimation(named animationName: String,
                             loop: Bool,
                             completion: (() -> Void)?) throws {

        // TODO: implement tracking of index
        // FIXME: implement check that animation exists

        // TODO: Consider here recreate watch or force reset delta, otherwise, we might get delta from prev animation

        let trackIndex: Int32 = 0
        let loop: Int32 = loop ? 1 : 0 // repeat non stop
        let animationNameCString = animationName.cString(using: .utf8)

        // UnsafeMutablePointer<spTrackEntry>
        let pTrackEntryOrNil = spAnimationState_setAnimationByName(pAnimationState, trackIndex, animationNameCString, loop)
        guard let pTrackEntry = pTrackEntryOrNil else {
            throw SpineSkeletonError.failedToSetAnimation(name, animationName)
        }

        if let completion = completion {
            let weakWrapper = TrackEventListenerCaptureWrapper(completion: completion)

            pTrackEntry.setUserData(weakWrapper)

            pTrackEntry.listener = { (pAnimationState, eventType, pTrackEntry, pEvent) in
                SpineSkeleton.handleTrackEvent(pAnimationState, eventType, pTrackEntry, pEvent)
            }
        }
    }

    public func clearAnimationTracks() {
        spAnimationState_clearTracks(pAnimationState);
    }

    public func resetAnimationState() {
        clearAnimationTracks()
        spSkeleton_setToSetupPose(pSkeleton)
    }

    // MARK: Rendering API

    public func updateState(_ elapsedSinceLastUpdate: Float) {
        dropMeshes()
        let adjustedDelta = speed * elapsedSinceLastUpdate
        spAnimationState_update(pAnimationState, adjustedDelta)

        spAnimationState_apply(pAnimationState, pSkeleton)
        spSkeleton_updateWorldTransform(pSkeleton)
    }

    public func render(in renderer: SpineSkeletonRenderer, bonesFilter: SpineSkeletonBonesFilter) {
        generateMeshes()

        for attachment in renderingOrder {
            // We might generated mesh with other filter, while calculated bounds, for example
            guard bonesFilter.shouldRender(attachment: attachment) else {
                continue
            }

            guard let touple = generatedMeshes[attachment] else {
                continue
            }

            renderer.render(attachment: attachment, mesh: touple.mesh, texture: touple.texture)
        }
    }

    public func bounds(bonesFilter: SpineSkeletonBonesFilter) -> FloatRect {
        generateMeshes()

        let meshes = generatedMeshes.filter { bonesFilter.shouldRender(attachment: $0.key) }.values.map { $0.mesh }

        guard let first = meshes.first else {
            return .zero
        }

        var resRect: FloatRect = first.bounds

        for mesh in meshes {
            resRect = resRect.union(mesh.bounds)
        }

        return resRect
    }

    public func attachmentsBounds(bonesFilter: SpineSkeletonBonesFilter) -> [String: FloatRect] {
        generateMeshes()

        let filteredGeneratedMeshes = generatedMeshes.filter { bonesFilter.shouldRender(attachment: $0.key) }

        var res = [String: FloatRect]()
        for keyValue in filteredGeneratedMeshes {
            let generatedMesh = keyValue.value
            res[keyValue.key] = generatedMesh.mesh.bounds
        }

        return res
    }

    // MARK: Private

    private let logger: Logger
    private var pAnimationState: UnsafeMutablePointer<spAnimationState>
    private let pSkeletonClipping: UnsafeMutablePointer<spSkeletonClipping>

    private typealias GeneratedMesh = (mesh: SpineMesh, texture: MTLTexture)

    /// Key is name of bone/slot/attachment
    private var generatedMeshes = [String: GeneratedMesh]()
    private var renderingOrder = [String]()

    private func dropMeshes() {
        generatedMeshes.values.forEach { $0.mesh.free() }
        generatedMeshes.removeAll(keepingCapacity: true)
        renderingOrder.removeAll(keepingCapacity: true)
    }

    private static func parseAnimationNames(from pSkeletonData: UnsafeMutablePointer<spSkeletonData>) throws -> [Animation] {
        let animationsCount = Int(pSkeletonData.pointee.animationsCount)
        guard animationsCount > 0 else {
            return []
        }

        var res = Array<Animation>()
        res.reserveCapacity(animationsCount)

        for i in 0..<animationsCount {
            let currentPointer = pSkeletonData.animation(at: i)
            let animation = Animation(pAnimation: currentPointer)
            res.append(animation)
        }

        return res
    }

    /// During this process we might increase size of buffer
    private func generateMeshes() {
        let zStep: Float = 1.0/Float(pSkeleton.slotsCount)

        guard renderingOrder.isEmpty else {
            // we already did it for this update, so no reason to repeat it
            return
        }

        for i in 0..<pSkeleton.slotsCount {

            let zPosition: Float = 1 - Float(i) * zStep

            // UnsafeMutablePointer<spSlot>
            let pSlot = pSkeleton.drawSlot(at: i)

            // UnsafeMutablePointer<spAttachment>
            guard let pAttachment = pSlot.attachment else {
                continue
            }

            let attachmentName = pAttachment.atlasRegionName()

            renderingOrder.append(attachmentName)

            let generatedMesh: GeneratedMesh?

            // We actually do not properly support blend modes. Looks like we not even properly support nomral mode,
            // because our rendering pipeline do not discart pixel, but uses some values for `SBF` and `DBF`(check documentation here: https://developer.apple.com/documentation/metal/mtlblendoperation)
            // Check how we setup rendering pipeline here: `SpineViewSkeletonRenderer.createMainRenderPipelineState`, specifically color attachment blend mode and settings
            // Also approach of thislibe is one draw call per whole skeleton. We do not render bone by bone
            //precondition(pSlot.slotData.blendMode == SP_BLEND_MODE_NORMAL, "We do not support other blend modes yet")

            // Here you can read about tintColor [Implementing-Rendering](http://en.esotericsoftware.com/spine-c#Implementing-Rendering)
            // we need mutiply skeleton color * slot color * attachment color
            let slotTintColor = pSkeleton.color * pSlot.color

            switch pAttachment.attachmentType {
            case .region:
                // UnsafeMutablePointer<spRegionAttachment>
                let pRegionAttachment = pAttachment.regionAttachment
                generatedMesh = generateMesh(for: pRegionAttachment,
                                             pSlot: pSlot,
                                             zPosition: zPosition,
                                             tintColor: slotTintColor * pRegionAttachment.color)

            case .mesh:
                // UnsafeMutablePointer<spMeshAttachment>
                let pMeshAttachment = pAttachment.meshAttachment

                generatedMesh = generateMesh(for: pMeshAttachment,
                                             pSlot: pSlot,
                                             zPosition: zPosition,
                                             tintColor: slotTintColor * pMeshAttachment.color)
            case .clipping:
                // UnsafeMutablePointer<spClippingAttachment>
                let pClippinAttachment = pAttachment.clippinAttachment
                spSkeletonClipping_clipStart(pSkeletonClipping,
                                             pSlot,
                                             pClippinAttachment)
                continue
            }

            // We need en clipping in the end of loop, for every clipped slop, Spince clear internal state
            spSkeletonClipping_clipEnd(pSkeletonClipping, pSlot)

            generatedMeshes[attachmentName] = generatedMesh
        }

        spSkeletonClipping_clipEnd2(pSkeletonClipping)
    }

    private static func handleTrackEvent(_ pAnimationState: UnsafeMutablePointer<spAnimationState>?,
                                         _ eventType: spEventType,
                                         _ pTrackEntryOrNil: UnsafeMutablePointer<spTrackEntry>?,
                                         _ pEvent: UnsafeMutablePointer<spEvent>?) {
        guard let unmanaged: Unmanaged<TrackEventListenerCaptureWrapper> = pTrackEntryOrNil?.readUserData() else {
            return
        }

        let wrapper = unmanaged.takeUnretainedValue()

        switch eventType {
        case SP_ANIMATION_START, SP_ANIMATION_END:
            // SP_ANIMATION_START - do not getting start on first animation
            // SP_ANIMATION_END - received when next animation start playing
            return
        case SP_ANIMATION_COMPLETE, SP_ANIMATION_INTERRUPT:
            wrapper.completion()
            // We might get `SP_ANIMATION_COMPLETE` and right after that `SP_ANIMATION_INTERRUPT`, when we start next animation
            // So we will nil completion wrapper after first call
            pTrackEntryOrNil?.userData = nil
            return
        case SP_ANIMATION_DISPOSE:
            unmanaged.release()
            return
        case SP_ANIMATION_EVENT:
            assert(false, "We got custom event")
            return
        default:
            assert(false, "We got unexpected value from animation")
            return
        }
    }

    /// - returns: nil, if after clipping we got nothing inside the area
    private func generateMesh(for pRegionAttachment: UnsafeMutablePointer<spRegionAttachment>,
                              pSlot: UnsafeMutablePointer<spSlot>,
                              zPosition: Float,
                              tintColor: spColor) -> GeneratedMesh? {
        // UnsafeMutablePointer<spAtlasRegion>
        let pAtlasRegion = pRegionAttachment.rendererObject
        let texture: MTLTexture = pAtlasRegion.atlasPage.rendererTexture()

        let verticesBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: 8)

        spRegionAttachment_computeWorldVertices(pRegionAttachment,
                                                pSlot,
                                                verticesBuffer.baseAddress!,
                                                0,
                                                2)

        return withUnsafeBytes(of: pRegionAttachment.uvs) { uvsRawBufferPointer in
            let uvsFloatPointer = uvsRawBufferPointer.bindMemory(to: Float.self)
            let uvsFloatMutablePointer = UnsafeMutableBufferPointer(mutating: uvsFloatPointer)

            var spineMesh: SpineMesh? = SpineMesh(verticesStorage: .manual(verticesBuffer),
                                                  trianglesStorage: .managed(quadTriangles),
                                                  uvsStorage: .manual(uvsFloatMutablePointer.copy()),
                                                  zPosition: zPosition,
                                                  tintColor: tintColor)

            clipMeshIfNeeded(&spineMesh)

            guard let spineMesh else {
                return nil
            }

            return (spineMesh, texture)
        }
    }

    /// - returns: nil, if after clipping we got nothing inside the area
    private func generateMesh(for pMeshAttachment: UnsafeMutablePointer<spMeshAttachment>,
                              pSlot: UnsafeMutablePointer<spSlot>,
                              zPosition: Float,
                              tintColor: spColor) -> GeneratedMesh? {
        // UnsafeMutablePointer<spAtlasRegion>
        let pAtlasRegion = pMeshAttachment.rendererObject
        let texture: MTLTexture = pAtlasRegion.atlasPage.rendererTexture()

        let verticesNumber = pMeshAttachment.worldVerticesLength
        let verticesBuffer = UnsafeMutableBufferPointer<Float>.allocate(capacity: verticesNumber)

        spVertexAttachment_computeWorldVertices(pMeshAttachment.superPointer,
                                                pSlot,
                                                0,
                                                pMeshAttachment.worldVerticesLengthInt32,
                                                verticesBuffer.baseAddress!,
                                                0,
                                                2)

        var spineMesh: SpineMesh? = SpineMesh(verticesStorage: .manual(verticesBuffer),
                                              trianglesStorage: .manual(pMeshAttachment.trinaglesBuffer.copy()),
                                              uvsStorage: .manual(pMeshAttachment.uvsBuffer.copy()),
                                              zPosition: zPosition,
                                              tintColor: tintColor)

        clipMeshIfNeeded(&spineMesh)

        guard let spineMesh else {
            return nil
        }

        return (spineMesh, texture)
    }

    private func clipMeshIfNeeded(_ mesh: inout SpineMesh?) {
        guard let unwrappedMesh = mesh else {
            return
        }

        let isClipping = spSkeletonClipping_isClipping(pSkeletonClipping) != 0

        guard isClipping else {
            return
        }

        spSkeletonClipping_clipTriangles(pSkeletonClipping,
                                         unwrappedMesh.vertices.baseAddress!,
                                         Int32(unwrappedMesh.vertices.count),
                                         unwrappedMesh.triangles.baseAddress!,
                                         Int32(unwrappedMesh.triangles.count),
                                         unwrappedMesh.uvs.baseAddress!,
                                         2);

        mesh?.free()

        let isEmpty = pSkeletonClipping.clippedVerticesBuffer.count == 0

        guard !isEmpty else {
            mesh = nil
            return
        }

        // Since we will store meshes, wchil we continu clipping, we need to copy all 3 storages
        mesh = SpineMesh(verticesStorage: .manual(pSkeletonClipping.clippedVerticesBuffer.copy()),
                         trianglesStorage: .manual(pSkeletonClipping.clippedTrianglesBuffer.copy()),
                         uvsStorage: .manual(pSkeletonClipping.clippedUvsBuffer.copy()),
                         zPosition: unwrappedMesh.zPosition,
                         tintColor: unwrappedMesh.tintColor)
    }


}

public enum SpineSkeletonError: Error {
    case failedToFindSkeletonJson(String, URL)
    case failedToLoadSkeletonJson(String, URL)
    case failedToCreateSkeletonData(String, URL, String?)
    case failedToCreateSkeleton(String, URL)
    case failedToCreateAnimationState(String, URL)
    case failedToLoadAnimations
    case failedToAddAnimation(String, String)
    case failedToSetAnimation(String, String)
    case failedToCreateClipping
}

private extension SpineSkeleton.Animation {
    init(pAnimation: UnsafeMutablePointer<spAnimation>) {
        let name = String(cString: pAnimation.pointee.name, encoding: .utf8)!
        let duration = pAnimation.pointee.duration

        self.name = name
        self.duration = TimeInterval(duration)
    }
}

final class TrackEventListenerCaptureWrapper {
    let completion: () -> Void

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }
}

private let quadTriangles: UnsafeMutableBufferPointer<UInt16> = {
    let buffer = UnsafeMutableBufferPointer<UInt16>.allocate(capacity: 6)
    let vertices: [UInt16] = [0, 1, 2, 2, 3, 0]
    vertices.withUnsafeBytes { bufferPointer in
        _ = memcpy(buffer.baseAddress!, bufferPointer.baseAddress!, UInt16.stride(of: 6))
    }
    return buffer
}()







