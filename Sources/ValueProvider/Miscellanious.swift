import Foundation


/// A type that implements a default constructor
public protocol Default {
    /// Creates a new default instance of `Self`
    init()
}


/// A mapped value/dictionary ID
public protocol ID {
    /// The ID bytes
    var bytes: Data { get }
}
extension Data: ID {
    public var bytes: Data { self }
}
extension String: ID {
    public var bytes: Data { self.data(using: .utf8)! }
}


/// A type that defines methods for encoding
public protocol ValueEncoder {
    /// Encodes an instance of the indicated type
    ///
    /// - Parameter value: The instance to encode
    func encode<T: Encodable>(_ value: T) throws -> Data
}
extension JSONEncoder: ValueEncoder {}


/// A type that defines methods for decoding
public protocol ValueDecoder {
    /// Decodes an instance of the indicated type
    ///
    ///  - Parameters:
    ///     - type: The target type
    ///     - data: The data to decode
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
extension JSONDecoder: ValueDecoder {}
