import Foundation

public extension CGSize {
    var containingTextureSize: TextureSize {
        return TextureSize(width: width.rounded(.up).asInt, height: height.rounded(.up).asInt)
    }
}
