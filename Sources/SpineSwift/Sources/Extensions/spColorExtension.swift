import Foundation
import SpineC

func * (lhs: spColor, rhs: spColor) -> spColor {
    spColor(r: lhs.r * rhs.r,
            g: lhs.g * rhs.g,
            b: lhs.b * rhs.b,
            a: lhs.a * rhs.a)
}

public extension spColor {
    var simd4: SIMD4<UInt8> {
        SIMD4<UInt8>(color: self)
    }
}

private extension SIMD4 where Scalar == UInt8 {
    init(color: spColor) {
        self = .init(UInt8(color.r * 255),
                     UInt8(color.g * 255),
                     UInt8(color.b * 255),
                     UInt8(color.a * 255))
    }
}
