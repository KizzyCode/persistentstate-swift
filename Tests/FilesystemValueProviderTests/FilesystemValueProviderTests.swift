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
            var counter = try storage.value(id: "Counter".bytes, default: 0)
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
            
            var dictionary = try storage.dictionary(id: "Dictionary".bytes, default: [String:String]())
            try dictionary.store(key: key, value: value)
            XCTAssertEqual(try dictionary.load(), shadow, "Invalid counter")
        }
    }
    
    func testExample() throws {
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
    }
    
    static var allTests = [
        ("testCounter", testCounter),
        ("testDict", testDict),
        ("testExample", testExample)
    ]
}
