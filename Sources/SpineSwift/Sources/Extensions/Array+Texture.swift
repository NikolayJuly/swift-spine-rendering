import Foundation
import Metal

public extension Array where Element == MTLTexture {
    mutating func insertIfNotPresented(_ texture: MTLTexture) -> Int {
        let textureIndex: Int
        if let index = firstIndex(where: { $0 === texture }) {
            textureIndex = index
        } else {
            append(texture)
            textureIndex = count - 1
        }
        return textureIndex
    }
}
