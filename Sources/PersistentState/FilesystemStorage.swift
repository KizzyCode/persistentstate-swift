import Foundation


/// A storage related error
public enum FilesystemError: Error {
    /// The database directory does not exist
    case invalidDir(String, StaticString = #file, Int = #line)
}


/// A filesystem backed storage
///
///  - Attention: When using the `FilesystemStorage`, keys should not be longer that 150 bytes. The entire key is
///    base64-urlsafe encoded and allows arbitrary UTF-8 characters.
public class FilesystemStorage {
    /// The default prefix for stored files
    public static let prefix = "de.KizzyCode.PersistentState.FilesystemStorage."
    /// The default safety margin when checking for enough free disk space
    public static let safetyMargin = 8 * 1024 * 1024
    
    /// The prefix for stored files
    private let prefix: String
    /// The required safety margin when checking for enough free disk space
    private let safetyMargin: Int
    /// The database directory
    private let dir: URL
    
    /// Creates a filesystem backed storage that stores the data in an application specific data directory
    ///
    ///  - Discussion: This function uses
    ///   `/var/mobile/Containers/Data/Application/<Some_UUID>/Documents/` on iOS, iPadOS, tvOS and watchos,
    ///   `/Users/<Current_User>/Library/Application Support/<Bundle_ID>/` on Catalyst and macOS and `~/.<Bundle_ID>`
    ///   for unknown-OS'.
    ///
    ///  - Parameters:
    ///     - bundleID: The application bundle ID
    ///     - prefix: The required overhead when checking for enough free disk space
    ///     - safetyMargin: The required overhead when checking for enough free disk space
    ///  - Throws: `FilesystemError.invalidDir` if the directory does not exists or is not writeable
    public convenience init(bundleID: String, prefix: String = FilesystemStorage.prefix,
                            safetyMargin: Int = FilesystemStorage.safetyMargin) throws {
        #if os(macOS) || targetEnvironment(macCatalyst)
            let appDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Application Support")
                .appendingPathComponent(bundleID)
        #elseif os(iOS) || os(watchOS) || os(tvOS)
            _ = bundleID
            let appDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        #else
            let userDir = ("~" as NSString).expandingTildeInPath
            let appDir = URL(fileURLWithPath: userDir).appendingPathComponent(".\(bundleID)")
        #endif
        
        try self.init(dir: appDir.path, prefix: prefix, safetyMargin: safetyMargin)
    }
    /// Creates a filesystem backed storage that stores the data in the container directory for an `appGroup`
    ///
    ///  - Discussion: This function uses
    ///    `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)` to get the container URL.
    ///    Common examples are `/private/var/mobile/Containers/Shared/AppGroup/<Some_UUID>/` on iOS and
    ///    `/Users/<Current_User>/Library/Group%20Containers/<Group>/` on Catalyst and macOS.
    ///
    ///  - Parameters:
    ///     - appGroup: The app group to get the container directory for
    ///     - prefix: The required overhead when checking for enough free disk space
    ///     - testOverhead: The required overhead when checking for enough free disk space
    ///  - Throws: `FilesystemError.invalidDir` if the directory does not exists or is not writeable
    ///
    ///  - Warning: If there is no container URL for the given app group, a fatal error is raised.
    public convenience init(appGroup group: String, prefix: String = FilesystemStorage.prefix,
                            safetyMargin: Int = FilesystemStorage.safetyMargin) throws {
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)!
        try self.init(dir: dir.path, prefix: prefix, safetyMargin: safetyMargin)
    }
    /// Creates a filesystem backed storage
    ///
    ///  - Parameters:
    ///     - dir: The directory to store the key-value records in
    ///     - prefix: The required overhead when checking for enough free disk space
    ///     - testOverhead: The required overhead when checking for enough free disk space
    ///  - Throws: `FilesystemError.invalidDir` if the directory does not exists or is not writeable
    public required init(dir: String, prefix: String = FilesystemStorage.prefix,
                         safetyMargin: Int = FilesystemStorage.safetyMargin) throws {
        // Set parameters
        self.prefix = prefix
        self.safetyMargin = safetyMargin
        
        // Check if the directory exists
        var isDir = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: dir, isDirectory: &isDir), isDir.boolValue else {
            throw FilesystemError.invalidDir("The given path is not a directory: \(dir)")
        }
        self.dir = URL(fileURLWithPath: dir).absoluteURL
        
        // Create and delete a test file
        let path = self.dir.appendingPathComponent(UUID().uuidString)
        do {
            try "Testolope".data(using: .utf8)!.write(to: path)
            try FileManager.default.removeItem(at: path)
        } catch let err {
            throw FilesystemError.invalidDir("Failed to create/delete test file: \(err)")
        }
    }
}
extension FilesystemStorage: Storage {
    /// Lists all entries
    ///
    ///  - Returns: All existing keys
    ///
    ///  - Warning: This function raises a fatal error if the directory cannot be read or if an entry contains an
    ///    invalid percent encoding.
    public func list() -> [String] {
        try! FileManager.default.contentsOfDirectory(atPath: self.dir.path)
            .filter({ $0.starts(with: self.prefix) })
            .map({ $0.dropFirst(self.prefix.count) })
            .map({ String(base64Urlsafe: $0)! })
    }
    /// Reads an entry if it exists
    ///
    ///  - Parameter key: The associated key
    ///  - Returns: The entry or `nil` if the entry does not exist
    ///
    ///  - Warning: This function raises a fatal error if a file for the given key exists but cannot be read.
    public func read<S: StringProtocol>(_ key: S) -> Data? {
        let path = self.dir.appendingPathComponent(self.prefix + key.base64Urlsafe)
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        return try! Data(contentsOf: path, options: .mappedIfSafe)
    }
    /// Creates/replaces an entry
    ///
    ///  - Parameters:
    ///     - key: The associated key
    ///     - value: The value to write
    ///  - Throws: `StorageError.outOfSpace` if there is not enough free space to write the entry
    ///
    ///  - Warning: This function raises a fatal error if it cannot check for enough free space or the entry cannot not
    ///    be written even if there is enough free space.
    public func write<S: StringProtocol, D: DataProtocol>(_ key: S, value: D) throws {
        let path = self.dir.appendingPathComponent(self.prefix + key.base64Urlsafe)
        
        let freeSpace = try! self.dir.resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity!
        guard freeSpace + self.safetyMargin >= value.count else {
            throw StorageError.outOfSpace("Not enough free disk space to write entry")
        }
        try! Data(value).write(to: path, options: .atomic)
    }
    /// Deletes an entry if it exists
    ///
    ///  - Parameter key: The associated key
    ///
    ///  - Warning: This function raises a fatal error if a file for the given key exists but cannot be deleted.
    public func delete<S: StringProtocol>(_ key: S) {
        let path = self.dir.appendingPathComponent(self.prefix + key.base64Urlsafe)
        
        if FileManager.default.fileExists(atPath: path.path) {
            try! FileManager.default.removeItem(at: path)
        }
    }
}


// Implement base64 URL-safe encoding
public extension DataProtocol {
    /// The string as URL-safe base64 encoded string
    var base64Urlsafe: String {
        // Make string URL-safe
        Data(self).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
    }
}
// Implement base64 URL-safe decoding
public extension Data {
    /// Decodes a base64 URL-safe encoded string
    ///
    ///  - Parameter encoded: The encoded string to decode
    ///  - Returns: The successfully decoded string or `nil`
    init?<S: StringProtocol>(base64Urlsafe encoded: S) {
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
            return nil
        }
        self = decoded
    }
}


// Implement base64 URL-safe encoding
public extension StringProtocol {
    /// The string as URL-safe base64 encoded string
    var base64Urlsafe: String { self.data(using: .utf8)!.base64Urlsafe }
}
// Implement base64 URL-safe decoding
public extension String {
    /// Decodes a base64 URL-safe encoded string
    ///
    ///  - Parameter encoded: The encoded string to decode
    ///  - Returns: The successfully decoded string or `nil`
    init?<S: StringProtocol>(base64Urlsafe encoded: S) {
        guard let data = Data(base64Urlsafe: encoded) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        self = string
    }
}
