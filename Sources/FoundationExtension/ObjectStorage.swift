import Foundation

public protocol ObjectStorageKey {
    associatedtype Value
}

public protocol ObjectStorageLockKey {}

@MainActor
public final class ObjectStorage {

    public init() {}

    @inlinable
    public subscript<Key: ObjectStorageKey>(_ key: Key.Type) -> Key.Value? {
        get {
            assert(Thread.isMainThread)
            guard let existed = storage[ObjectIdentifier(Key.self)] else {
                return nil
            }
            assert(existed is Key.Value, "Unexpected type. Expected \(Key.Value.self), but got \(type(of: existed))")
            return existed as? Key.Value
        }
        set {
            assert(Thread.isMainThread)
            storage[ObjectIdentifier(Key.self)] = newValue
        }
    }

    @inlinable
    public func contains<Key: ObjectStorageKey>(_ key: Key.Type) -> Bool {
        assert(Thread.isMainThread)
        return storage.keys.contains(ObjectIdentifier(Key.self))
    }

    // MARK: Private

    @usableFromInline
    internal var storage = [ObjectIdentifier: Any]()
}
