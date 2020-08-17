import Foundation
import XCTest
@testable import PersistentState


final class PersistentStateTests: XCTestCase {
    let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("de.KizzyCode.PersistentState.Tests")
    
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
        let storage = try FilesystemStorage(dir: self.testDir.path)
        
        for shadow in 0..<512 {
            let counter = PersistentBox(storage: storage, key: "Counter", default: 0)
            let value = counter.get({ (value: inout Int) -> Int in
                defer { value += 1 }
                return value
            })
            
            XCTAssert(value == shadow, "Invalid counter")
        }
    }
    
    func testDict() throws {
        let storage = try FilesystemStorage(dir: self.testDir.path)
        var shadow: [String: String] = [:]
        
        for _ in 0..<512 {
            let key = UUID().uuidString, value = UUID().uuidString
            shadow[key] = value
            
            let persistent: PersistentDict<String, String> = .init(storage: storage, key: "Dict")
            persistent[key] = value
            XCTAssert(persistent.dict == shadow, "Invalid counter")
        }
    }
    
    func testExample() {
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
                self.value.get({ (value: inout Int) -> Int in
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
    }
    
    static var allTests = [
        ("testCounter", testCounter),
        ("testDict", testDict),
        ("testExample", testExample)
    ]
}
