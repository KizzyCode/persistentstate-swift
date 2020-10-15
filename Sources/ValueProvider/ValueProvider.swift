import Foundation


/// A value encoder
public protocol ValueEncoder {
    /// Encodes an instance of the indicated type
    ///
    /// - Parameter value: The instance to encode
    func encode<T: Encodable>(_ value: T) throws -> Data
}
extension JSONEncoder: ValueEncoder {}


/// A value decoder
public protocol ValueDecoder {
    /// Decodes an instance of the indicated type
    ///
    ///  - Parameters:
    ///     - type: The target type
    ///     - data: The data to decode
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}
extension JSONDecoder: ValueDecoder {}


/// A mapped value (i.e. a value provided by a value provider)
public protocol MappedValue {
    /// The value type
    associatedtype Value: Codable
    
    /// Loads the value
    ///
    ///  - Returns: The loaded value
    func load() throws -> Value
    /// Stores a value
    ///
    ///  - Parameter newValue: The value to store
    mutating func store(_ newValue: Value) throws
    /// Deletes the value
    mutating func delete() throws
}
public extension MappedValue {
    /// A `get`/`set`-wrapper around the `load` and `store` functions
    var value: Value {
        get { try! self.load() }
        set { try! self.store(newValue) }
    }
}


/// A mapped dictionary
///
///  - Discussion: This type exists because it allows a better management of individual entries than a `MappedValue`
///    with a dictionary as associated type.
public protocol MappedDictionary {
    /// The key type
    associatedtype Key: Codable & Hashable
    /// The value type
    associatedtype Value: Codable
    
    /// Lists all existing keys
    ///
    ///  - Returns: A set of all existing keys
    func list() throws -> Set<Key>
    /// Loads all existing key-value pairs
    ///
    ///  - Returns: A dictionary containing all keys and values
    func load() throws -> [Key: Value]
    /// Loads an existing value
    ///
    ///  - Parameter key: The associated key
    ///  - Returns: The loaded value if it exists or `nil`
    func load(key: Key) throws -> Value?
    /// Loads an existing value or inserts a default value
    ///
    ///  - Parameters:
    ///     - key: The associated key
    ///     - default: The default value to store if there is no value for the given key yet
    ///  - Returns: The loaded value
    mutating func load(key: Key, default: Value) throws -> Value
    /// Stores a value
    ///
    ///  - Parameters:
    ///     - key: The associated key
    ///     - value: The value to store or `nil` if the entry for the given key should be removed
    mutating func store(key: Key, value: Value?) throws
    /// Deletes the dictionary
    mutating func delete() throws
}
public extension MappedDictionary {
    /// All existing keys
    var keys: Set<Key> {
        try! self.list()
    }
    /// All existing key-value pairs
    var all: [Key: Value] {
        try! self.load()
    }
    
    
    /// A `subscript`-wrapper around the `load` and `store` functions
    subscript(_ key: Key) -> Value? {
        get { try! self.load(key: key) }
        set { try! self.store(key: key, value: newValue) }
    }
}


/// A value provider
public protocol ValueProvider {
    /// Maps an existing value
    ///
    ///  - Parameter id: The ID of the value to map
    ///  - Returns: The mapped value if exists or `nil`
    func value<T: Codable>(id: Data) throws -> AnyMappedValue<T>?
    /// Maps an existing value or inserts a default value
    ///
    ///  - Parameters:
    ///     - id: The ID of the value to map
    ///     - default: A default value to insert if there is no mapped value yet
    ///  - Returns: The mapped value
    func value<T: Codable>(id: Data, default: T) throws -> AnyMappedValue<T>
    
    /// Maps an existing dictionary
    ///
    ///  - Parameters:
    ///     - id: The ID of the dictionary to map
    ///     - default: A default value to insert if there is no mapped dictionary yet
    ///  - Returns: The mapped dictionary if it exists or `nil`
    func dictionary<K: Hashable & Codable, V: Codable>(id: Data) throws -> AnyMappedDictionary<K, V>?
    /// Maps an existing dictionary or inserts default key-value pairs
    ///
    ///  - Parameters:
    ///     - id: The ID of the dictionary to map
    ///     - default: A default value to insert if there is no mapped dictionary yet
    ///  - Returns: The mapped dictionary
    func dictionary<K: Hashable & Codable, V: Codable>(id: Data, default: [K: V]) throws -> AnyMappedDictionary<K, V>
}
