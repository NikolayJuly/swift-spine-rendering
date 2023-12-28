import CoreGraphics
import Foundation

typealias FloatPoint = SIMD2<Float>
typealias FloatVector = FloatPoint
extension FloatPoint {
    init(_ cgPoint: CGPoint) {
        self.init(x: Float(cgPoint.x), y: Float(cgPoint.y))
    }

    /// - returns: normalized vertor and length of self
    func normalize() -> (FloatVector, Float) {
        let length = sqrtf(lengthSq)
        return ((1/length) * self, length)
    }

    var lengthSq: Float {
        x * x + y * y
    }
}
