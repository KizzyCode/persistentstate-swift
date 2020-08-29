import Foundation


/// A box that makes a codable variable persistent
public final class PersistentBox<T: Codable> {
    /// The storage to use
    private let storage: Storage
    /// The associated persistent storage key for this dictionary
    private let key: String
    /// The error handler
    private var onError: ((String) -> Bool)?
    /// The coder to en-/decode the value
    private var coder: Coder
    
    /// The cache for the value
    private var value: T?
    
    /// Creates a new box that either loads the existing object or uses the default value
    ///
    ///  - Parameters:
    ///     - storage: The persistent storage to use
    ///     - key: The associated persistent storage key for this box
    ///     - default: The default value to use if there is no stored value object
    ///     - onError: The error hander
    ///     - coder: The coder to en-/decode the value
    public init<S: StringProtocol>(storage: Storage, key: S, default: @autoclosure () -> T,
                                   onError: ErrorHandler? = nil, coder: Coder = JSONCoder.default) {
        // Write the default value if necessary
        let key = String(key)
        if !storage.list().contains(key) {
            let data = try! coder.encode(`default`())
            storage.tryWrite(key, value: data, onError: onError)
        }
        
        // Init object
        self.storage = storage
        self.key = String(key)
        self.onError = onError
        self.coder = coder
    }
    /// Creates a new box that either loads the existing object or returns `nil`
    ///
    ///  - Parameters:
    ///     - storage: The persistent storage to use
    ///     - key: The associated persistent storage key for this box
    ///     - onError: The error hander
    ///     - coder: The coder to en-/decode the value
    public init?<S: StringProtocol>(storage: Storage, key: S, onError: ErrorHandler? = nil,
                                    coder: Coder = JSONCoder.default) {
        // Check if there is a stored value
        let key = String(key)
        guard storage.list().contains(key) else {
            return nil
        }
        
        // Init object
        self.storage = storage
        self.key = String(key)
        self.onError = onError
        self.coder = coder
    }
    
    /// Accesses/modifies the persistent value and writes the modified variable to the persistent storage
    ///
    ///  - Parameter access: The accessor/modifier for the value
    ///  - Returns: The value returned by the closure
    ///
    ///  - Throws: Rethrows any error from the closure
    public func callAsFunction<R>(_ access: (inout T) throws -> R) rethrows -> R {
        // Load value if necessary
        if self.value == nil {
            let data = self.storage.read(self.key)!
            self.value = try! self.coder.decode(T.self, from: data)
        }
        
        /// Write the value after access
        defer {
            let data = try! self.coder.encode(self.value!)
            self.storage.tryWrite(self.key, value: data, onError: self.onError)
        }
        return try access(&self.value!)
    }
}
