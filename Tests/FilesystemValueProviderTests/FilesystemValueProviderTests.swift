import Foundation
import XCTest
import ValueProvider
@testable import FilesystemValueProvider


final class FilesystemValueProviderTests: XCTestCase {
    let testDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("de.KizzyCode.FilesystemValueProvider.Tests")
    
    override func setUp() {
        self.tearDown()
        try! FileManager.default.createDirectory(at: self.testDir, withIntermediateDirectories: false)
        print("Writing entries to \"\(self.testDir.path)\"...")
    }
    override func tearDown() {
        if FileManager.default.fileExists(atPath: self.testDir.path) {
            print("Deleting \"\(self.testDir.path)\"...")
            try! FileManager.default.removeItem(at: self.testDir)
        }
    }
    
    func testCounter() throws {
        let storage = try FilesystemValueProvider(basePath: self.testDir)
        
        for shadow in 0..<512 {
            var counter = try storage.value(for: "Counter".bytes, default: 0)
            let value = try counter.load()
            try counter.store(value + 1)
            
            XCTAssert(value == shadow, "Invalid counter")
        }
    }
    
    func testDict() throws {
        let storage = try FilesystemValueProvider(basePath: self.testDir)
        var shadow: [String: String] = [:]
        
        for _ in 0..<512 {
            let key = UUID().uuidString, value = UUID().uuidString
            shadow[key] = value
            
            var dictionary = try storage.dictionary(for: "Dictionary".bytes, default: [String: String]())
            try dictionary.store(key: key, value: value)
            XCTAssertEqual(try dictionary.load(), shadow, "Invalid counter")
        }
    }
    
    func testExample() throws {
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
    }
    
    static var allTests = [
        ("testCounter", testCounter),
        ("testDict", testDict),
        ("testExample", testExample)
    ]
}
