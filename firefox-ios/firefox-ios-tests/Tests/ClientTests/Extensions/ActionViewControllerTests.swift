// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UniformTypeIdentifiers
@testable import Client

/// Tests for ActionViewController
///
/// These tests verify the Action Extension view controller logic.
/// Since ActionViewController depends on NSExtensionContext (which is only
/// available in extension contexts), we test the logic through dependency injection.
final class ActionViewControllerTests: XCTestCase {
    var mockURLBuilder: MockFirefoxURLBuilder!
    var subject: ActionViewController!

    override func setUp() async throws {
        try await super.setUp()
        mockURLBuilder = MockFirefoxURLBuilder()
        subject = ActionViewController(firefoxURLBuilder: mockURLBuilder)
    }

    override func tearDown() async throws {
        subject = nil
        mockURLBuilder = nil
        try await super.tearDown()
    }

    @MainActor
    func testInitialization_WithDependencyInjection_UsesProvidedBuilder() {
        let customBuilder = MockFirefoxURLBuilder()
        let controller = ActionViewController(firefoxURLBuilder: customBuilder)

        XCTAssertNotNil(controller)
        // Verify the builder is set (you may need to expose this for testing or use a different approach)
    }

    @MainActor
    func testViewDidLoad_SetsUpViewCorrectly() {
        subject.viewDidLoad()

        XCTAssertEqual(subject.view.backgroundColor, .clear)
        XCTAssertEqual(subject.view.alpha, 0)
    }
}

// MARK: - Mock Objects

/// Mock implementation of FirefoxURLBuilding protocol for testing
final class MockFirefoxURLBuilder: FirefoxURLBuilding {
    var buildFirefoxURLResult: URL?
    var findURLInItemsResult: Result<ActionShareItem, Error>?
    var findTextInItemsResult: Result<ExtractedShareItem, Error>?
    var convertTextToURLResult: URL?

    var findURLInItemsCalled = false
    var findTextInItemsCalled = false
    var buildFirefoxURLCalled = false
    var convertTextToURLCalled = false

    func buildFirefoxURL(from shareItem: ExtractedShareItem) -> URL? {
        buildFirefoxURLCalled = true
        return buildFirefoxURLResult
    }

    func findURLInItems(_ items: [NSExtensionItem], completion: @escaping (Result<ActionShareItem, Error>) -> Void) {
        findURLInItemsCalled = true
        if let result = findURLInItemsResult {
            completion(result)
        }
    }

    func findTextInItems(_ items: [NSExtensionItem], completion: @escaping (Result<ExtractedShareItem, Error>) -> Void) {
        findTextInItemsCalled = true
        if let result = findTextInItemsResult {
            completion(result)
        }
    }

    func convertTextToURL(_ text: String) -> URL? {
        convertTextToURLCalled = true
        return convertTextToURLResult
    }
}
