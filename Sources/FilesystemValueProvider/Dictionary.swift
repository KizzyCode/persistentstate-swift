import Foundation
import ValueProvider
import CryptoKit


/// A filesystem mapped dictionary
public struct FilesystemMappedDictionary<Key: Codable & Hashable, Value: Codable> {
    /// The dictionary base path
    private let dictionaryBasePath: URL
    /// The value encoder
    private let encoder: ValueEncoder
    /// The value decoder
    private let decoder: ValueDecoder
    
    /// Loads a filesystem mapped dictionary
    ///
    ///  - Parameters:
    ///     - id: The dictionary ID
    ///     - basePath: The filesystem base path to work in
    ///     - encoder: The value encoder
    ///     - decoder: The value decoder
    internal init?(id: Data, basePath: URL, encoder: ValueEncoder, decoder: ValueDecoder) {
        // Set vars
        self.dictionaryBasePath = basePath.appendingPathComponent(id.base64Safe)
        self.encoder = encoder
        self.decoder = decoder
        
        // Check whether the dictionary folder exists
        var isDirectory = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: self.dictionaryBasePath.path, isDirectory: &isDirectory)
        guard exists, isDirectory.boolValue else {
            return nil
        }
    }
    /// Initializes a filesystem mapped dictionary
    ///
    ///  - Parameters:
    ///     - id: The dictionary ID
    ///     - basePath: The filesystem base path to work in
    ///     - default: A default value to insert if there is no mapped dictionary yet
    ///     - encoder: The value encoder
    ///     - decoder: The value decoder
    internal init(id: Data, basePath: URL, default: [Key: Value], encoder: ValueEncoder, decoder: ValueDecoder) throws {
        // Use an existing instance if any
        if let existing = Self(id: id, basePath: basePath, encoder: encoder, decoder: decoder) {
            self = existing
            return
        }
        
        // Set vars
        self.dictionaryBasePath = basePath.appendingPathComponent(id.base64Safe)
        self.encoder = encoder
        self.decoder = decoder
        
        // Create directory and write all default entries
        try FileManager.default.createDirectory(at: self.dictionaryBasePath, withIntermediateDirectories: true)
        for (key, value) in `default` {
            try self.store(key: key, value: value)
        }
    }
    
    /// Creates a file path for a key
    ///
    ///  - Parameter key: The key
    ///  - Returns: The file path based upon the key
    private func path(for key: Key) throws -> URL {
        let data = try self.encoder.encode(key)
        return self.dictionaryBasePath.appendingPathComponent(data.base64Safe)
    }
}
extension FilesystemMappedDictionary: MappedDictionary {
    public func list() throws -> Set<Key> {
        // List all entries
        let entries = try FileManager.default.contentsOfDirectory(at: self.dictionaryBasePath,
                                                                  includingPropertiesForKeys: nil,
                                                                  options: .skipsHiddenFiles)
        
        // Parse all entries
        let encodedKeys = entries.compactMap({ try? Data(base64Safe: $0.lastPathComponent) })
        return try Set(encodedKeys.map({ try self.decoder.decode(Key.self, from: $0) }))
    }
    public func load() throws -> [Key: Value] {
        // List all entries and collect their values
        try self.list().reduce(into: [:], { $0[$1] = try self.load(key: $1) })
    }
    public func load(key: Key) throws -> Value? {
        // Check whether the entry exists
        let path = try self.path(for: key)
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        
        // Load and decode the value
        let data = try Data(contentsOf: path)
        return try self.decoder.decode(Value.self, from: data)
    }
    public func load(key: Key, default: Value) throws -> Value {
        // Gets or inserts the value
        if let value = try self.load(key: key) {
            return value
        } else {
            try self.store(key: key, value: `default`)
            return `default`
        }
    }
    public func store(key: Key, value: Value?) throws {
        // Update or delete the entry
        let path = try self.path(for: key)
        if let value = value {
            let data = try self.encoder.encode(value)
            try data.write(to: path, options: .atomic)
        } else if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }
    }
    public func delete() throws {
        try FileManager.default.removeItem(at: self.dictionaryBasePath)
    }
}
