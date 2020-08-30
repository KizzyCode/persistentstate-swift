import Foundation


/// A persistant dictionary that immediately writes all changes to the persistent storage
public final class PersistentDict<K: Codable & Hashable, V: Codable> {
    /// The box containing the dictionary
    private var box: PersistentBox<[K: V]>
    
    /// The persistent dictionary
    public var dict: [K: V] {
        get { self.box({ $0 }) }
        set { self.box({ $0 = newValue }) }
    }
    
    /// Either loads the the stored dictionary or uses the default value
    ///
    ///  - Parameters:
    ///     - storage: The persistent storage to use
    ///     - key: The associated persistent storage key for this dict
    ///     - default: The default value to use if there is no stored value
    ///     - onError: The error hander
    ///     - coder: The coder to en-/decode the value
    public init<S: StringProtocol>(storage: Storage, key: S, default: @autoclosure () -> [K: V] = [:],
                                   onError: ErrorHandler? = nil, coder: Coder = JSONCoder.default) {
        self.box = PersistentBox(storage: storage, key: key, default: `default`(), onError: onError, coder: coder)
    }
    /// Either loads the the stored dictionary or uses the default value
    ///
    ///  - Parameters:
    ///     - storage: The persistent storage to use
    ///     - key: The associated persistent storage key for this dict
    ///     - default: The default value to use if there is no stored value
    ///     - onError: The error hander
    ///     - coder: The coder to en-/decode the value
    public init?<S: StringProtocol>(storage: Storage, key: S, onError: ErrorHandler? = nil,
                                    coder: Coder = JSONCoder.default) {
        guard let box = PersistentBox<[K: V]>(storage: storage, key: key, onError: onError, coder: coder) else {
            return nil
        }
        self.box = box
    }
    
    /// Accesses the value for the given key
    public subscript(index: K) -> V? {
        get { self.box({ $0[index] }) }
        set { self.box({ $0[index] = newValue }) }
    }
    
    /// Gets the stored value for `key` or inserts `default` and returns the value
    ///
    ///  - Parameters:
    ///     - key: The key
    ///     - default: The default value to insert and return if there is no value for `key` yet
    ///  - Returns: The value for `key` or the newly inserted `default` value
    public func getOrInsert(key: K, default: @autoclosure () -> V) -> V {
        if self[key] == nil {
            self[key] = `default`()
        }
        return self[key]!
    }
    
    /// Accesses/modifies the persistent value for `key` and writes the modified variable to the persistent storage
    ///
    ///  - Parameters:
    ///     - key: The key
    ///     - default: The default value to insert and return if there is no value for `key` yet
    ///     - access: The accessor/modifier for the value
    ///  - Returns: The value returned by the closure
    ///
    ///  - Throws: Rethrows any error from the closure
    ///
    ///  - Warning: If there is no value for `key` and `default` is `nil`, a fatal error is raised.
    public func callAsFunction<R>(key: K, default: @autoclosure () -> V? = nil,
                                  _ access: (inout V) throws -> R) rethrows -> R {
        // Load the value
        if self[key] == nil {
            self[key] = `default`() ?? { fatalError("There is no value for the given key \(key)") }()
        }
        var value = self[key]!
        
        // Set the modified value and return the accessor result
        defer { self[key] = value }
        return try access(&value)
    }
}
