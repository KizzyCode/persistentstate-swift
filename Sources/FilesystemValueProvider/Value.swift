import Foundation
import ValueProvider


/// A filesystem backed value provider
public struct FilesystemMappedValue<Value: Codable> {
    /// The file path
    private let path: URL
    /// The value encoder
    private let encoder: ValueEncoder
    /// The value decoder
    private let decoder: ValueDecoder
    
    /// Loads a filesystem mapped value if it exists
    ///
    ///  - Parameters:
    ///     - id: The dictionary ID
    ///     - basePath: The filesystem base path to work in
    ///     - encoder: The value encoder
    ///     - decoder: The value decoder
    internal init?(id: Data, basePath: URL, encoder: ValueEncoder, decoder: ValueDecoder) {
        // Set the vars
        self.path = basePath.appendingPathComponent(id.base64Safe)
        self.encoder = encoder
        self.decoder = decoder
        
        // Check whether a file exists or not
        guard FileManager.default.fileExists(atPath: self.path.path) else {
            return nil
        }
    }
    /// Loads a filesystem mapped value if it exists
    ///
    ///  - Parameters:
    ///     - id: The dictionary ID
    ///     - default: A default value to insert if there is no mapped value yet
    ///     - basePath: The filesystem base path to work in
    ///     - encoder: The value encoder
    ///     - decoder: The value decoder
    internal init(id: Data, default: Value, basePath: URL, encoder: ValueEncoder, decoder: ValueDecoder) throws {
        // Set the vars
        self.path = basePath.appendingPathComponent(id.base64Safe)
        self.encoder = encoder
        self.decoder = decoder
        
        // Write the default value if there is no value yet
        if !FileManager.default.fileExists(atPath: self.path.path) {
            try self.store(`default`)
        }
    }
}
extension FilesystemMappedValue: MappedValue {
    public func load() throws -> Value {
        let data = try Data(contentsOf: self.path)
        return try self.decoder.decode(Value.self, from: data)
    }
    public func store(_ newValue: Value) throws {
        let data = try self.encoder.encode(newValue)
        try data.write(to: self.path, options: .atomic)
    }
    public func delete() throws {
        try FileManager.default.removeItem(at: self.path)
    }
}
