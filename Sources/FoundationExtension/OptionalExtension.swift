import Swift

public extension Optional {
    /// - note: throws if self is .none
    @inlinable
    func unwrapped(otherwise: Error) throws -> Wrapped {
        guard case let .some(value) = self else {
            throw otherwise
        }

        return value
    }

    @inlinable
    func unwrapped(_ message: String = "", file: String = #file, function: String = #function, line: Int = #line) throws -> Wrapped {
        guard case let .some(value) = self else {
            throw OptionalExtensionError.optionIsNil(message: message, file: file, function: function, line: line)
        }

        return value
    }
}

public enum OptionalExtensionError: Error {
    case optionIsNil(message: String = "", file: String = #file, function: String = #function, line: Int = #line)
}
