import Foundation
import FoundationExtension
import QuartzCore

public protocol CurrentMediaTimeProvider {
    /// - returns: time at the begining of a current frame, so all skeletons can update relative to the same time
    func now() -> CFTimeInterval
}

public extension ObjectStorage {
    var currentMediaTimeProvider: CurrentMediaTimeProvider {
        if let existed = self[CurrentMediaTimeProviderKey.self] {
            return existed
        }

        let newOne = CurrentMediaTimeProviderImpl()
        self[CurrentMediaTimeProviderKey.self] = newOne
        return newOne
    }
}

final class CurrentMediaTimeProviderImpl: CurrentMediaTimeProvider {

    // MARK: CurrentMediaTimeProvider

    func now() -> CFTimeInterval {
        CACurrentMediaTime()
    }
}

private struct CurrentMediaTimeProviderKey: ObjectStorageKey {
    typealias Value = CurrentMediaTimeProvider
}
