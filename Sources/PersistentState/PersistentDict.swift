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
}
