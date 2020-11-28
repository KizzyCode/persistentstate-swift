# ValueProvider

This package defines an API for values managed by a value provider; e.g. to interface on-disk values.


## Example

```swift
/// A persistent counter example
struct Example {
    /// Define a test directory (usually you do this once somewhere in your app)
    static let testDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("de.KizzyCode.FilesystemValueProvider.Tests")
    
    /// Define a provider (usually you do this once somewhere in your app)
    static let provider = try! FilesystemValueProvider(basePath: Self.testDir)
    
    /// The counter value
    @Mapped(provider: Self.provider, for: "Example.counter", default: 0)
    private var counter: Int
    
    /// Does something with the counter value
    public mutating func count() {
        defer { self.counter += 1 }
        print("Counter:", self.counter)
    }
}

// Do something with out example
var example = Example()
example.count()
```
