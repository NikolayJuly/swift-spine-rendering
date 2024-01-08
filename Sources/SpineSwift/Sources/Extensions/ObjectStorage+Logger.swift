import Foundation
import FoundationExtension
import Logging

public extension ObjectStorage {
    var logger: Logger {
        get {
            if let existedOne = self[LoggerObjectStorageKey.self] {
                return existedOne
            }

            let newOne = Logger(label: "default.app.logger")
            self[LoggerObjectStorageKey.self] = newOne
            return newOne
        }
        set {
            self[LoggerObjectStorageKey.self] = newValue
        }
    }
}

private struct LoggerObjectStorageKey: ObjectStorageKey {
    typealias Value = Logger
}

