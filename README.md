# PersistentState

This package helps you to build persistent objects; i.e. objects that need to persist across app restarts. 


## Example

```swift
/// A persistent counter
// swiftlint:disable nesting
class Counter {
    private var value: PersistentBox<Int>
    
    /// Loads the counter with `name` or creates a new one starting with `0`
    public init(name: String) {
        let storage = try! FilesystemStorage(bundleID: "de.KizzyCode.PersistentStorage.Example")
        self.value = .init(storage: storage, key: "Counter.\(name)", default: 0)
    }
    
    /// Returns the next counter value
    public func next() -> Int {
        self.value({ (value: inout Int) -> Int in
            defer { value += 1 }
            return value
        })
    }
}

// A persistent dictionary e.g. to store settings
let storage = try! FilesystemStorage(dir: self.testDir.path)
let settings: PersistentDict<String, String> = .init(storage: storage, key: "Settings")

settings["account"] = "Testolope"
XCTAssert(settings["account"]! == "Testolope")
```
