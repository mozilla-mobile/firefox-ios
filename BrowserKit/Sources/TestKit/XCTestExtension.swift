// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

public extension XCTestCase {
    /// Tracks an object for memory leaks by asserting it's deallocated after the test completes.
    @MainActor
    func trackForMemoryLeaks(_ object: AnyObject?, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Memory leak detected in \(file):\(line)")
        }
    }
    
    /// Unwraps un async method return optional value.
    func unwrapAsync<T>(asyncMethod: () async throws -> T?,
                        file: StaticString = #filePath,
                        line: UInt = #line) async throws -> T {
        let returnValue = try await asyncMethod()
        return try XCTUnwrap(returnValue, file: file, line: line)
    }

    /// Asserts that an async throwing expression throws a specific error type.
    ///
    /// Usage:
    /// ```swift
    /// await assertAsyncThrows(ofType: NetworkError.self) {
    ///     try await service.fetchData()
    /// } verify: { error in
    ///     XCTAssertEqual(error.code, 404)
    /// }
    /// ```
    @MainActor
    func assertAsyncThrows<E: Error, T>(
        ofType expectedType: E.Type,
        _ expression: () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line,
        verify: ((E) -> Void)? = nil
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error \(expectedType), but no error thrown.", file: file, line: line)
        } catch let error as E {
            verify?(error)
        } catch {
            XCTFail("Expected error \(expectedType), but got \(error)", file: file, line: line)
        }
    }
    
    /// Asserts that an async throwing methods throws the expected Equatable error type.
    ///
    /// Usage:
    /// ```swift
    /// await assertAsyncThrowsEqual(MyErrorCase.unknown) {
    ///     try await service.fetchData()
    /// }
    /// ```
    @MainActor
    func assertAsyncThrowsEqual<E: Error & Equatable, T>(
        _ expected: E,
        _ expression: @MainActor () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await assertAsyncThrows(ofType: E.self, expression, file: file, line: line) { error in
            XCTAssertEqual(error, expected, file: file, line: line)
        }
    }
}
