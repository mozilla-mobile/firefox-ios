// MARK: - AppInfoTests

import XCTest
@testable import BrowserKit

class AppInfoTests: XCTestCase {
    // ...

    func testHandleAutocomplete() {
        // Arrange
        let appInfo = AppInfo()
        let query = "test"

        // Act
        let suggestion = appInfo.handleAutocomplete(query)

        // Assert
        XCTAssertNotNil(suggestion)
    }

    // ...
}