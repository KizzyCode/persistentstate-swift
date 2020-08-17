import Foundation


/// A storage related error
public enum FilesystemError: Error {
    /// The database directory does not exist
    case invalidDir(String, StaticString = #file, Int = #line)
}


/// A filesystem backed storage
///
///  - Attention: When using the `FilesystemStorage`, keys should not be longer that 200 bytes. Also, unsafe characters
///    are percent encoded and thus consume three bytes instead of one (safe characters are all US-ASCII alphanumericals
///    `[a-zA-Z0-9]` and `.-_`). Keys with a byte length lower than or equal to 66 are always valid.
public class FilesystemStorage {
    /// The overhead requirement when checking for enough free disk space
    private static let checkOverhead = 8 * 1024 * 1024
    /// The prefix for keys
    private static let prefix = "de.KizzyCode.PersistentState.FilesystemStorage."
    /// All safe characters
    private static let safe = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "0123456789" + ".-_")
    
    /// The database directory
    private let dir: URL
    
    /// Creates a filesystem backed storage that stores the data in an application specific data directory
    ///
    ///  - Discussion: This function uses
    ///   `/var/mobile/Containers/Data/Application/<Some_UUID>/Documents/` on iOS, iPadOS, tvOS and watchos,
    ///   `/Users/<Current_User>/Library/Application Support/<Bundle_ID>/` on Catalyst and macOS and
    ///   `~/.<Bundle_ID>` for unknown-OS
    ///
    ///  - Parameter bundleID: The application bundle ID
    ///  - Throws: `FilesystemError.invalidDir` if the directory does not exists or is not writeable
    public convenience init(bundleID: String) throws {
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
        
        try self.init(dir: appDir.path)
    }
    /// Creates a filesystem backed storage that stores the data in the container directory for an `appGroup`
    ///
    ///  - Discussion: This function uses
    ///    `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)` to get the container URL.
    ///    Common examples are `/private/var/mobile/Containers/Shared/AppGroup/<Some_UUID>/` on iOS and
    ///    `/Users/<Current_User>/Library/Group%20Containers/<Group>/` on Catalyst and macOS.
    ///
    ///  - Parameter appGroup: The app group to get the container directory for
    ///  - Throws: `FilesystemError.invalidDir` if the directory does not exists or is not writeable
    ///
    ///  - Warning: If there is no container URL for the given app group, a fatal error is raised.
    public convenience init(appGroup group: String) throws {
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)!
        try self.init(dir: dir.path)
    }
    /// Creates a filesystem backed storage
    ///
    ///  - Parameter dir: The directory to store the key-value records in
    ///  - Throws: `FilesystemError.invalidDir` if the directory does not exists or is not writeable
    public required init(dir: String) throws {
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
            .filter({ $0.starts(with: Self.prefix) })
            .map({ $0.dropFirst(Self.prefix.count) })
            .map({ $0.removingPercentEncoding! })
    }
    /// Reads an entry if it exists
    ///
    ///  - Parameter key: The associated key
    ///  - Returns: The entry or `nil` if the entry does not exist
    ///
    ///  - Warning: This function raises a fatal error if a file for the given key exists but cannot be read.
    public func read<S: StringProtocol>(_ key: S) -> Data? {
        let key = key.addingPercentEncoding(withAllowedCharacters: Self.safe)!
        let path = self.dir.appendingPathComponent(Self.prefix + key)
        
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
        let key = key.addingPercentEncoding(withAllowedCharacters: Self.safe)!
        let path = self.dir.appendingPathComponent(Self.prefix + key)
        
        let freeSpace = try! self.dir.resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity!
        guard freeSpace + Self.checkOverhead >= value.count else {
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
        let key = key.addingPercentEncoding(withAllowedCharacters: Self.safe)!
        let path = self.dir.appendingPathComponent(Self.prefix + key)
        
        if FileManager.default.fileExists(atPath: path.path) {
        	try! FileManager.default.removeItem(at: path)
        }
    }
}
