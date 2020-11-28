import Foundation
import ValueProvider


/// A `FilesystemValueProvider` related error
public enum FilesystemValueProviderError: Error {
    /// A filename is invalid
    case invalidFilename(StaticString = #file, Int = #line)
    /// Failed to access or modify a file
    case accessError(String, StaticString = #file, Int = #line)
}


/// A filesystem-backed value provider
public struct FilesystemValueProvider {
    /// The base path to store the entries in
    private let basePath: URL
    /// The value encoder to use
    private let encoder: ValueEncoder
    /// The value decoder to use
    private let decoder: ValueDecoder
    
    /// Creates a new filesystem value provider
    ///
    ///  - Parameters:
    ///     - basePath: The base path to store the entries in
    ///     - encoder: The value encoder to use
    ///     - decoder: The value decoder to use
    public init(basePath: URL, encoder: ValueEncoder = JSONEncoder(), decoder: ValueDecoder = JSONDecoder()) throws {
        // Set vars
        self.basePath = basePath
        self.encoder = encoder
        self.decoder = decoder
        
        // Create the base path folder
        try FileManager.default.createDirectory(at: self.basePath, withIntermediateDirectories: true)
        
        // Create and delete a test file
        let path = self.basePath.appendingPathComponent(UUID().uuidString)
        do {
            try "Testolope".data(using: .utf8)!.write(to: path)
            try FileManager.default.removeItem(at: path)
        } catch let err {
            throw FilesystemValueProviderError.accessError("Failed to create/delete test file: \(err)")
        }
    }
    
    /// Creates a new filesystem value provider with `DefaultPath.applicationData(bundleID)` as path
    ///
    ///  - Parameters:
    ///     - bundleID: The bundle ID to get the default application data folder for
    ///     - encoder: The value encoder to use
    ///     - decoder: The value decoder to use
    public init(for bundleID: String, encoder: ValueEncoder = JSONEncoder(),
                decoder: ValueDecoder = JSONDecoder()) throws {
        let path = DefaultPath.applicationData(for: bundleID)
        try self.init(basePath: path, encoder: encoder, decoder: decoder)
    }
    
    #if os(iOS) || os(watchOS) || os(tvOS)
    /// Creates a new filesystem value provider with `DefaultPath.applicationData` as path
    ///
    ///  - Parameters:
    ///     - encoder: The value encoder to use
    ///     - decoder: The value decoder to use
    public init(encoder: ValueEncoder = JSONEncoder(), decoder: ValueDecoder = JSONDecoder()) throws {
        let path = DefaultPath.applicationData
        try self.init(basePath: path, encoder: encoder, decoder: decoder)
    }
    #endif
}
extension FilesystemValueProvider: ValueProvider {
    public func value<T: Codable>(for id: ID) throws -> AnyMappedValue<T>? {
        let value =
            FilesystemMappedValue<T>(
                id: id.bytes, basePath: self.basePath,
                encoder: self.encoder, decoder: self.decoder)
        return value.map({ AnyMappedValue($0) })
    }
    public func value<T: Codable>(for id: ID, default: T) throws -> AnyMappedValue<T> {
        let value =
            try FilesystemMappedValue(
                id: id.bytes, default: `default`, basePath: self.basePath,
                encoder: self.encoder, decoder: self.decoder)
        return AnyMappedValue(value)
    }
    
    public func dictionary<K: Hashable & Codable, V: Codable>(for id: ID) throws -> AnyMappedDictionary<K, V>? {
        let dictionary =
            FilesystemMappedDictionary<K, V>(
                id: id.bytes, basePath: self.basePath,
                encoder: self.encoder, decoder: self.decoder)
        return dictionary.map({ AnyMappedDictionary($0) })
    }
    public func dictionary<K: Hashable & Codable, V: Codable>(for id: ID, default: [K: V]) throws
        -> AnyMappedDictionary<K, V>
    {
        let dictionary =
            try FilesystemMappedDictionary(
                id: id.bytes, basePath: self.basePath, default: `default`,
                encoder: self.encoder, decoder: self.decoder)
        return AnyMappedDictionary(dictionary)
    }
}


/// Provides some default paths
public struct DefaultPath {
    #if os(iOS) || os(watchOS) || os(tvOS)
    /// A path to the application data directory; usually something like
    /// `/var/mobile/Containers/Data/Application/<Some_UUID>/Documents/`
    public static let applicationData = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    #endif
    
    /// Gets the default application data folder for a given bundle ID
    ///
    ///  - Parameter bundleID: The bundle ID
    ///  - Returns: The applications data directory; i.e.
    ///     - `/var/mobile/Containers/Data/Application/<Some_UUID>/Documents/` for iOS, iPadOS, tvOS and watchos
    ///     - `/Users/<Current_User>/Library/Application Support/<Bundle_ID>/` on Catalyst and macOS
    ///     - `~/.<Bundle_ID>` for other OS
    public static func applicationData<S: StringProtocol>(for bundleID: S) -> URL {
    #if os(macOS) || targetEnvironment(macCatalyst)
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Application Support")
            .appendingPathComponent(String(bundleID))
    #elseif os(iOS) || os(watchOS) || os(tvOS)
        _ = bundleID
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    #else
        let userDir = ("~" as NSString).expandingTildeInPath
        return URL(fileURLWithPath: userDir).appendingPathComponent(".\(bundleID)")
    #endif
    }
}


/// Implements Base64-URL-safe coding for `Data`
public extension Data {
    /// The Base64-URL-safe encoded representation of `self`
    ///
    ///  - Discussion: This implementation uses the default Base64-encoding with the following modifications:
    ///     - `+` is replaced by `-`
    ///     - `/` is replaced by `_`
    ///     - The padding with `=` chars is removed
    var base64Safe: String {
        Data(self).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }
    
    /// Decodes some Base64-URL-safe encoded bytes
    ///
    ///  - Parameter encoded: The encoded bytes
    ///
    ///  - Discussion: This implementation expects the default Base64-encoding with the following modifications:
    ///     - `+` has been replaced by `-`
    ///     - `/` has been replaced by `_`
    ///     - The padding with `=` chars has been removed
    init<S: StringProtocol>(base64Safe encoded: S) throws {
        // Reverse URL-safe modifications
        var encoded = String(encoded)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch encoded.count % 4 {
            case 2: encoded += "=="
            case 3: encoded += "="
            default: break
        }
        
        // Base64 decode string
        guard let decoded = Data(base64Encoded: encoded) else {
            throw FilesystemValueProviderError.invalidFilename()
        }
        self = decoded
    }
}
