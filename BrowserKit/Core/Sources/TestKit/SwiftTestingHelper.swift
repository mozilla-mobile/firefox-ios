// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

/// A base test case class for Swift Testing test suites that provides common testing utilities,
/// such as memory leak detection.
///
/// ## Usage
///
/// **IMPORTANT:** To ensure correct memory leak detection, `SwiftTestingHelper` must be declared
/// as the **first stored property** in your test struct and tracked objects are declared as a **local variable**.
/// This ensures that it deallocates last, after all tracked objects have been deallocated.
public final class SwiftTestingHelper {
    private struct MemoryLeakCheck {
        weak var object: AnyObject?
        let location: SourceLocation
    }

    private var memoryLeakCheck: MemoryLeakCheck?

    public init() {}

    /// Tracks an object for memory leak detection.
    ///
    /// Registers an object to be checked for memory leaks when the test completes. The object is
    /// held with a weak reference, and during deinitialization, verifies the object was deallocated.
    ///
    /// - Note: Only one object can be tracked per `SwiftTestingHelper` instance.
    /// To track multiple objects, we will need to expand, but no use case for it currently so keeping it simple.
    ///
    /// Example:
    /// ```swift
    /// @Suite
    /// struct MyTests {
    ///     let helper = SwiftTestingHelper()  // ✓ Declare FIRST
    ///     // Other properties here...
    ///
    ///     @Test
    /// func testMyClass() {
    ///     let subject = helper.trackForMemoryLeaks(MyClass())  // ✓ Local variable
    ///     // test code
    /// } // ← subject deallocates here, before helper
    /// ```
    @discardableResult
    public final func trackForMemoryLeaks<T: AnyObject>(
        _ instance: T,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) -> T {
        let location = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
        memoryLeakCheck = MemoryLeakCheck(object: instance, location: location)
        return instance
    }

    deinit {
        guard let memoryLeakCheck else {
            Issue.record("No objects to verify for memory leaks.")
            return
        }
        #expect(memoryLeakCheck.object == nil, "Potential memory leak detected", sourceLocation: memoryLeakCheck.location)
    }
}
