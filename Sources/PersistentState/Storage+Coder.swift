import Foundation


/// A storage related error
public enum StorageError: Error {
    /// A write error indicating that there is not enough free space to write the new entry
    case outOfSpace(String, StaticString = #file, Int = #line)
}


/// A callback that gets called if a storage-related write error occurs. The argument is a textual representation of the
/// error. If the error handler returns `true` the object will retry to write the state, calling the error handler again
/// if necessary. If the error handler returns `false` or is `nil`, the object should raise a fatal error.
///
///  - Parameter desc: A textual representation/description of the error
///  - Returns: `true` if the write action should be retried or `false` if a fatal error should be raised
public typealias ErrorHandler = (_ desc: String) -> Bool


/// A reliable persistent key-value storage
public protocol Storage {
    /// Lists all entries
    ///
    ///  - Returns: All existing keys
    func list() -> [String]
    /// Reads an entry if it exists
    ///
    ///  - Parameter key: The associated key
    ///  - Returns: The entry or `nil` if the entry does not exist
    func read<S: StringProtocol>(_ key: S) -> Data?
    /// Creates/replaces an entry
    ///
    ///  - Parameters:
    ///     - key: The associated key
    ///     - value: The value to write
    ///  - Throws: `StorageError.outOfSpace` if there is not enough free space to write the entry
    func write<S: StringProtocol, D: DataProtocol>(_ key: S, value: D) throws
    /// Deletes an entry if it exists
    ///
    ///  - Parameter key: The associated key
    func delete<S: StringProtocol>(_ key: S)
}
public extension Storage {
    /// Tries to create/replace an entry and calls `onError` if `self.write` throws
    ///
    ///  - Parameters:
    ///     - key: The associated key
    ///     - value: The value to write
    ///     - onError: The error handler
    ///
    ///  - Warning: If `onError` is `nil` or returns `false` this function raises a fatal error
    func tryWrite<S: StringProtocol, D: DataProtocol>(_ key: S, value: D, onError: ErrorHandler?) {
        while true {
            do {
                return try self.write(key, value: value)
            } catch let err {
                guard let onError = onError else {
                    fatalError("Failed to write/replace entry and there is no error handler (\(err)")
                }
                guard onError(err.localizedDescription) else {
                    fatalError("Failed to write/replace entry and the error handler returned `false` (\(err)")
                }
            }
        }
    }
}


/// A coder that can en-/decode `Codable` elements
public protocol Coder {
    /// Gets a new default coder instance
    static var `default`: Coder { get }
    
    /// Encodes a value
    ///
    ///  - Parameter value: The value to encode
    ///  - Returns: The encoded value
    ///  - Throws: If the value cannot be encoded
    func encode<T: Encodable>(_ value: T) throws -> Data
    
    /// Decodes a value
    ///
    ///  - Parameters:
    ///     - type: The type to decode to
    ///     - data: The data to decode
    ///  - Returns: The decoded value
    ///  - Throws: If the encoded data cannot be decoded
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}


/// A JSON encoder that combines `JSONEncoder` and `JSONDecoder`
public struct JSONCoder: Coder {
    public static var `default`: Coder { JSONCoder() }
    
    public func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }
    
    public func decode<T: Decodable>(_ type: T.Type = T.self, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}
