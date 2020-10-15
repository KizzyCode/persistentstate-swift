# ValueProvider

This package defines an API for values managed by a value provider; e.g. to interface on-disk values.


## Example

```swift
/// A persistent counter
// swiftlint:disable nesting
struct Counter {
    /// The mapped value
    private var counter: AnyMappedValue<Int>
    
    /// Loads the counter with `name` or creates a new one starting with `0`
    public init(name: String) throws {
        let path = DefaultPath.applicationData(for: "de.KizzyCode.ValueProvider.Example.Counter"),
            storage = try FilesystemValueProvider(basePath: path)
        self.counter = try storage.value(id: name.bytes, default: 0)
    }
    
    /// Returns the next counter value
    public mutating func next() throws -> Int {
        let value = try self.counter.load()
        try self.counter.store(value + 1)
        return value
    }
}

// A persistent dictionary e.g. to store settings
let path = DefaultPath.applicationData(for: "de.KizzyCode.ValueProvider.Example.Dictionary"),
    storage = try FilesystemValueProvider(basePath: path)

var settings = try storage.dictionary(id: "Settings".bytes, default: [String:String]())
settings["account"] = "Testolope"
XCTAssertEqual(settings["account"]!, "Testolope")
```
