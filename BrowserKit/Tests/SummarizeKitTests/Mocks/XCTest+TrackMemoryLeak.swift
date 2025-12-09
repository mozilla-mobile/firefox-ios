// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

public extension XCTestCase {
    @MainActor
    func trackForMemoryLeaks(_ object: AnyObject?, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Memory leak detected in \(file):\(line)")
        }
    }

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
}
