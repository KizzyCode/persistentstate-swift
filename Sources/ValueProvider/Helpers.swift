import Foundation


/// A mapped value
@propertyWrapper public struct Mapped<Value: Codable> {
    /// The mapped value
    private var mapped: AnyMappedValue<Value>
    
    /// Creates a new mapped value
    ///
    ///  - Parameters:
    ///     - provider: The value provider
    ///     - id: The value ID
    ///     - default: A default value to insert if there is no mapped value yet
    public init(provider: ValueProvider, for id: ID, default: Value) {
        self.mapped = try! provider.value(for: id, default: `default`)
    }
    /// Creates a new mapped value
    ///
    ///  - Parameters:
    ///     - provider: The value provider
    ///     - id: The value ID
    public init(provider: ValueProvider, for id: ID) where Value: Default {
        self.mapped = try! provider.value(for: id)
    }
    
    /// The wrapped value
    public var wrappedValue: Value {
        get { try! self.mapped.load() }
        set { try! self.mapped.store(newValue) }
    }
}


/// A type erased `MappedValue` implementation
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
    
    // A specialized constructor to avoid the nesting of `AnyMappedValue`s
    /// Wraps a s specific `MappedValue` implementation
    ///
    ///  - Parameter mappedValue: The value to map
    public init(_ mappedValue: AnyMappedValue<Value>) {
        self = mappedValue
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


/// A type erased `MappedDictionary` implementation
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
    
    /// Wraps a specific `MappedValue` implementation
    ///
    ///  - Parameter mappedDictionary: The dictionary to map
    public init<T: MappedDictionary>(_ mappedDictionary: T) where T.Key == Key, T.Value == Value {
        var mappedDictionary = mappedDictionary
        self._list = { try mappedDictionary.list() }
        self._loadAll = { try mappedDictionary.load() }
        self._load = { try mappedDictionary.load(key: $0) }
        self._loadOrInsert = { try mappedDictionary.load(key: $0, default: $1) }
        self._store = { try mappedDictionary.store(key: $0, value: $1) }
        self._delete = { try mappedDictionary.delete() }
    }
    
    // A specialized constructor to avoid the nesting of `AnyMappedDictionary`s
    /// Wraps a specific `MappedValue` implementation
    ///
    ///  - Parameter mappedDictionary: The dictionary to map
    public init(_ mappedDictionary: AnyMappedDictionary<Key, Value>) {
        self = mappedDictionary
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
