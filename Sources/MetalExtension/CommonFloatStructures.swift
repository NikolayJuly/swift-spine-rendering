import CoreGraphics
import Foundation

public typealias FloatPoint = SIMD2<Float>
public typealias FloatVector = FloatPoint
public extension FloatPoint {
    init(_ cgPoint: CGPoint) {
        self.init(x: Float(cgPoint.x), y: Float(cgPoint.y))
    }

    /// Return normalized vertor and length of self
    func normalize() -> (FloatVector, Float) {
        let length = sqrtf(lengthSq)
        return ((1/length) * self, length)
    }

    var lengthSq: Float {
        x * x + y * y
    }
}

public typealias FloatSize = SIMD2<Float>

public extension FloatSize {
    var width: Float { x }
    var height: Float { y }

    init(width: Float, height: Float) {
        self.init(x: width, y: height)
    }
}

public struct FloatRect: CustomStringConvertible {

    public static let zero = FloatRect(x: 0, y: 0, width: 0, height: 0)
    public static let normalizedSpace = FloatRect(x: 0, y: 0, width: 1, height: 1)

    @inlinable
    public var x: Float { storage[0] }

    @inlinable
    public var y: Float { storage[1] }

    @inlinable
    public var width: Float { storage[2] }

    @inlinable
    public var height: Float { storage[3] }

    @inlinable
    public var maxX: Float { x + width }

    @inlinable
    public var maxY: Float { y + height }

    @inlinable
    public var center: FloatPoint { FloatPoint(x: x + 0.5 * width, y: y + 0.5 * height) }

    @inlinable
    public var textureRect: TextureRect {
        let origin = TexturePosition(x: Int(x.rounded(.down)), y: Int(y.rounded(.down)))
        let imageSize = TextureSize(width: Int(width.rounded(.up)), height: Int(height.rounded(.up)))
        return TextureRect(origin: origin,
                           size: imageSize)
    }

    public init(x: Float, y: Float, width: Float, height: Float) {
        storage = .init(x, y, width, height)
    }

    public init(x: Int, y: Int, width: Int, height: Int) {
        storage = .init(Float(x), Float(y), Float(width), Float(height))
    }

    public init(textureRect: TextureRect) {
        storage = .init(Float(textureRect.origin.x),
                        Float(textureRect.origin.y),
                        Float(textureRect.size.width),
                        Float(textureRect.size.height))
    }

    public init(rect: CGRect) {
        storage = .init(Float(rect.origin.x),
                        Float(rect.origin.y),
                        Float(rect.size.width),
                        Float(rect.size.height))
    }

    @inlinable
    public func intersection(_ other: FloatRect) -> FloatRect? {
        let x = max(x, other.x)
        let y = max(y, other.y)
        let maxX = min(self.maxX, other.maxX)
        let maxY = min(self.maxY, other.maxY)

        guard maxX > x && maxY > y else {
            return nil
        }

        return .init(x: x, y: y, width: maxX - x, height: maxY - y)
    }

    @inlinable
    public func union(_ other: FloatRect) -> FloatRect {
        let min = FloatPoint(x: other.x, y: other.y)
        let max = FloatPoint(x: other.maxX, y: other.maxY)

        return self.expanded(toInclude: min).expanded(toInclude: max)
    }

    @inlinable
    public func expanded(toInclude point: FloatPoint) -> FloatRect {
        let newX = min(x, point.x)
        let newY = min(y, point.y)
        let farRight = max(x + width, point.x)
        let farBottom = max(y + height, point.y)
        let newWidth = farRight - newX
        let newHeight = farBottom - newY

        return FloatRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }

    @inlinable
    public func shift(_ shift: FloatPoint) -> FloatRect {
        .init(x: x + shift.x, y: y + shift.y, width: width, height: height)
    }

    @inlinable
    public func scale(_ scale: Float) -> FloatRect {
        .init(x: scale * x,
              y: scale * y,
              width: scale * width,
              height: scale * height)
    }

    @inlinable
    public func scale(_ scale: SIMD2<Float>) -> FloatRect {
        .init(x: scale.x * x,
              y: scale.y * y,
              width: scale.x * width,
              height: scale.y * height)
    }

    @inlinable
    public var cgRect: CGRect {
        CGRect(x: Double(x),
               y: Double(y),
               width: Double(width),
               height: Double(height))
    }

    // MARK: CustomStringConvertible

    public var description: String {
        "{x: \(x), y: \(y), width: \(width), height: \(height)}"
    }

    // MARK: Internal

    @usableFromInline
    let storage: SIMD4<Float>
}
