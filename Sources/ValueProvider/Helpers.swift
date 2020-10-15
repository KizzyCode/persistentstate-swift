import Foundation


/// A generic box around a specific `MappedValue` implementation
public struct AnyMappedValue<Value: Codable> {
    /// The `load` implementation
    private let _load: () throws -> Value
    /// The `store` implementation
    private let _store: (Value) throws -> Void
    /// The `delete` implementation
    private let _delete: () throws -> Void
    
    /// Wraps a s specific `MappedValue` implementation
    ///
    ///  - Parameter mappedValue: The value to map
    public init<T: MappedValue>(_ mappedValue: T) where T.Value == Value {
        var mappedValue = mappedValue
        self._load = { try mappedValue.load() }
        self._store = { try mappedValue.store($0) }
        self._delete = { try mappedValue.delete() }
    }
}
extension AnyMappedValue: MappedValue {
    public func load() throws -> Value {
        try self._load()
    }
    public mutating func store(_ newValue: Value) throws {
        try self._store(newValue)
    }
    public mutating func delete() throws {
        try self._delete()
    }
}


/// A generic box around a specific `MappedDictionary` implementation
public struct AnyMappedDictionary<Key: Codable & Hashable, Value: Codable> {
    /// The `list` implementation
    private let _list: () throws -> Set<Key>
    /// The `load/0` implementation
    private let _loadAll: () throws -> [Key: Value]
    /// The `load/1` implementation
    private let _load: (Key) throws -> Value?
    /// The `load/2` implementation
    private let _loadOrInsert: (Key, Value) throws -> Value
    /// The `store` implementation
    private let _store: (Key, Value?) throws -> Void
    /// The `delete` implementation
    private let _delete: () throws -> Void
    
    /// Wraps a s specific `MappedValue` implementation
    ///
    ///  - Parameter mappedValue: The value to map
    public init<T: MappedDictionary>(_ mappedDictionary: T) where T.Key == Key, T.Value == Value {
        var mappedDictionary = mappedDictionary
        self._list = { try mappedDictionary.list() }
        self._loadAll = { try mappedDictionary.load() }
        self._load = { try mappedDictionary.load(key: $0) }
        self._loadOrInsert = { try mappedDictionary.load(key: $0, default: $1) }
        self._store = { try mappedDictionary.store(key: $0, value: $1) }
        self._delete = { try mappedDictionary.delete() }
    }
}
extension AnyMappedDictionary: MappedDictionary {
    public func list() throws -> Set<Key> {
        try self._list()
    }
    public func load() throws -> [Key: Value] {
        try self._loadAll()
    }
    public func load(key: Key) throws -> Value? {
        try self._load(key)
    }
    public mutating func load(key: Key, default: Value) throws -> Value {
        try self._loadOrInsert(key, `default`)
    }
    public mutating func store(key: Key, value: Value?) throws {
        try self._store(key, value)
    }
    public mutating func delete() throws {
        try self._delete()
    }
}


// Implements easy access to the UTF-8 bytes of the string
public extension String {
    /// The UTF-8 bytes of the string
    var bytes: Data {
        self.data(using: .utf8)!
    }
}
