import Foundation
import FoundationExtension
import MetalKit
import MetalExtension
import SpineC
import SpineC_SwiftImpl

public typealias TextureSpineImplementation = SpineImplementations<MTLTexture>
public typealias SpineRenderedTexture = TextureSpineImplementation.RenderedObject

public extension SpineImplementations {
    static func setup(with generalMetalStack: GeneralMetalStack,
                      using fileSystemService: FileSystemService = FileManager.default) {
        let readFile: (_ url: URL) -> Data = {
            try! fileSystemService.fileContent(at: $0)
        }

        let createTexture: (_ url: URL) -> TextureSpineImplementation.RenderedObject = { url in
            let texture = try! generalMetalStack.createTexture(from: url)
            return TextureSpineImplementation.RenderedObject(texture: texture,
                                                             width: texture.width,
                                                             height: texture.height)
        }

        let spineImplementations = TextureSpineImplementation(readFile: readFile,
                                                              createTexture: createTexture)

        setupSpineImplementations(spineImplementations)
    }
}
