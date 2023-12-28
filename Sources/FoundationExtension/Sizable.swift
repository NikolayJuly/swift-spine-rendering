import Foundation

public protocol Sizable {}

public extension Sizable {
    @inlinable
    static var size: Int {
        return MemoryLayout<Self>.size
    }

    @inlinable
    static var stride: Int {
        return MemoryLayout<Self>.stride
    }

    @inlinable
    static func stride(of count: Int) -> Int {
        return MemoryLayout<Self>.stride * count
    }
}

extension UInt8: Sizable {}
extension UInt16: Sizable {}
extension UInt: Sizable {}
extension UInt32: Sizable {}
extension Int32: Sizable {}

extension Float: Sizable {}

extension SIMD2: Sizable {}
extension SIMD3: Sizable {}
extension SIMD4: Sizable {}
