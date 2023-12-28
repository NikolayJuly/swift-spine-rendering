import CoreGraphics
import Foundation

public struct TextureSize: Codable, Equatable, Hashable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: width, height: height)
    }

    public var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }

    public static let one = TextureSize(width: 1, height: 1)
}

public struct TexturePosition: Codable, Equatable, Hashable {

    public static let zero = TexturePosition(x: 0, y: 0)

    public static func + (lhr: TexturePosition, rhs: (Int, Int)) -> TexturePosition {
        TexturePosition(x: lhr.x + rhs.0, y: lhr.y + rhs.1)
    }

    public static func + (lhr: TexturePosition, rhs: TexturePosition) -> TexturePosition {
        TexturePosition(x: lhr.x + rhs.x, y: lhr.y + rhs.y)
    }

    public static func - (lhr: TexturePosition, rhs: TexturePosition) -> TexturePosition {
        TexturePosition(x: lhr.x - rhs.x, y: lhr.y - rhs.y)
    }

    public static prefix func - (lhr: TexturePosition) -> TexturePosition {
        TexturePosition(x: -lhr.x, y: -lhr.y)
    }

    public var i: Int // Column N
    public var j: Int // Row N

    @inlinable
    public var x: Int {
        get { i }
        set { i = newValue }
    }

    @inlinable
    public var y: Int {
        get { j }
        set { j = newValue }
    }

    public init(i: Int, j: Int) {
        self.i = i
        self.j = j
    }

    public init(x: Int, y: Int) {
        self.i = x
        self.j = y
    }

    @inlinable
    public var lengthSq: Int {
        x * x + y * y
    }

    @inlinable
    public var floatVector: SIMD2<Float> {
        SIMD2<Float>(x: Float(x), y: Float(y))
    }
}

public struct TextureRect: Codable, Equatable, CustomStringConvertible {

    public let origin: TexturePosition
    public let size: TextureSize

    @inlinable public var x: Int { origin.x }
    @inlinable public var y: Int { origin.y }
    @inlinable public var width: Int { size.width }
    @inlinable public var height: Int { size.height }

    @inlinable public var maxX: Int { origin.x + size.width }
    @inlinable public var maxY: Int { origin.y + size.height }

    @inlinable public var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }

    public init(origin: TexturePosition, size: TextureSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.origin = TexturePosition(x: x, y: y)
        self.size = TextureSize(width: width, height: height)
    }

    @inlinable
    public func contains(_ imagePosition: TexturePosition) -> Bool {
        origin.x <= imagePosition.x
        && origin.y <= imagePosition.y
        && (origin.x + size.width) > imagePosition.x
        && (origin.y + size.height) > imagePosition.y
    }

//    @inlinable
//    public func expanded(toInclude point: TexturePosition) -> TextureRect {
//        let newX = min(origin.x, point.x)
//        let newY = min(origin.y, point.y)
//        let farRight = max(origin.x + size.width, point.x + 1)
//        let farTop = max(origin.y + size.height, point.y + 1)
//        let newWidth = farRight - newX
//        let newHeight = farTop - newY
//
//        return ImageRect(origin: ImagePosition(x: newX, y: newY),
//                         size: ImageSize(width: newWidth, height: newHeight))
//    }

//    @inlinable
//    public func union(_ other: ImageRect) -> ImageRect {
//        let min = ImagePosition(x: other.x, y: other.y)
//        let max = ImagePosition(x: other.maxX, y: other.maxY)
//
//        return self.expanded(toInclude: min).expanded(toInclude: max)
//    }

//    @inlinable
//    public func intersection(_ other: ImageRect) -> ImageRect? {
//        let x = max(x, other.x)
//        let y = max(y, other.y)
//        let maxX = min(maxX, other.maxX)
//        let maxY = min(maxY, other.maxY)
//
//        guard maxX >= x || maxY >= y else {
//            return nil
//        }
//
//        return .init(x: x, y: y, width: maxX - x, height: maxY - y)
//    }

//    @inlinable
//    public func shift(_ diff: ImagePosition) -> ImageRect {
//        ImageRect(origin: origin + diff, size: size)
//    }

    // MARK: CustomStringConvertible

    public var description: String {
        "ImageRect({\(x), \(y)}, {\(width), \(height)})"
    }

}
