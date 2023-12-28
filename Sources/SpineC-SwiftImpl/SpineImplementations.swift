import Foundation
import Metal

public struct SpineImplementations<Texture: AnyObject> {

    public final class RenderedObject {
        public let texture: Texture
        public let width: Int
        public let height: Int

        public init(texture: Texture,
                    width: Int,
                    height: Int) {
            self.texture = texture
            self.width = width
            self.height = height
        }
    }

    public typealias ReadFile = (_ url: URL) -> Data
    public typealias CreateTexture = (_ url: URL) -> RenderedObject

    let readFile: ReadFile
    let createTexture: CreateTexture

    public init(readFile: @escaping ReadFile,
                createTexture: @escaping CreateTexture) {
        self.readFile = readFile
        self.createTexture = createTexture
    }
}

typealias SharedSpineImplementations = SpineImplementations<AnyObject>
var spineImplementations: SharedSpineImplementations?

public func setupSpineImplementations<T: AnyObject>(_ impl: SpineImplementations<T>) {
    typealias OriginalRendered = SpineImplementations<T>.RenderedObject
    typealias AnyRendered = SpineImplementations<AnyObject>.RenderedObject
    let createTexture: (_ url: URL) -> AnyRendered = { url in
        let originalRendred = impl.createTexture(url)
        return AnyRendered(texture: originalRendred.texture,
                           width: originalRendred.width,
                           height: originalRendred.height)
    }
    spineImplementations = SpineImplementations(readFile: impl.readFile,
                                                createTexture: createTexture)
}
