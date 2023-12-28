import Foundation

public extension UnsafeMutableBufferPointer {
    /// Allocated new memory and copy existed content in it.
    /// Caller responsible for calling `deallocate()` on returned value
    func copy() -> UnsafeMutableBufferPointer<Element> {
        let newOne = UnsafeMutableBufferPointer<Element>.allocate(capacity: self.count)
        memcpy(newOne.baseAddress!, baseAddress!, MemoryLayout<Element>.stride * count)
        return newOne
    }
}
