import Foundation
import SpineC

@_cdecl("_spUtil_readFile")
func _spUtil_readFile(_ path: UnsafePointer<CChar>!, _ length: UnsafeMutablePointer<Int32>!) -> UnsafeMutablePointer<CChar>! {
    guard let impl = spineImplementations else {
        fatalError("Call `setupSpineImplementations` before using Spine")
    }

    let path = String(cString: path, encoding: .utf8)!
    let url = URL(fileURLWithPath: path, isDirectory: false)
    let data = impl.readFile(url)

    let memoryPtr = malloc(data.count)
    _ = data.withUnsafeBytes { buffer in
        memcpy(memoryPtr, buffer.baseAddress!, buffer.count)
    }

    length.pointee = Int32(data.count)
    return memoryPtr!.assumingMemoryBound(to: CChar.self)
}

@_cdecl("_spAtlasPage_createTexture")
func _spAtlasPage_createTexture(_ self: UnsafeMutablePointer<spAtlasPage>!, _ path: UnsafePointer<CChar>!) {
    guard let impl = spineImplementations else {
        fatalError("Call `setupSpineImplementations` before using Spine")
    }

    guard let self = self else {
        fatalError("self can't be nil")
    }

    let path = String(cString: path, encoding: .utf8)!
    let url = URL(fileURLWithPath: path, isDirectory: false)
    let texture = impl.createTexture(url)

    let unmanged = Unmanaged.passUnretained(texture).retain()
    self.pointee.rendererObject = unmanged.toOpaque()
    self.pointee.width = Int32(texture.width)
    self.pointee.height = Int32(texture.height)
}

@_cdecl("_spAtlasPage_disposeTexture")
func _spAtlasPage_disposeTexture(_ self: UnsafeMutablePointer<spAtlasPage>!) {

    guard let self = self else {
        fatalError("self can't be nil")
    }

    guard let opague = self.pointee.rendererObject else {
        fatalError("unexpected nil in rendererObject")
    }

    let unamanged = Unmanaged<SharedSpineImplementations.RenderedObject>.fromOpaque(opague)
    unamanged.release()

    self.pointee.rendererObject = nil
    self.pointee.width = 0
    self.pointee.height = 0
}

