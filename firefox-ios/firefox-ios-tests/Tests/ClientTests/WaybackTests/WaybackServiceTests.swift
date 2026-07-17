// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class WaybackServiceTests: XCTestCase {
    private var mockURLSession: URLSession!
    private var mockURLProtocol: MockURLProtocol!

    override func setUp() {
        super.setUp()
        mockURLProtocol = MockURLProtocol()

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)
    }

    override func tearDown() {
        mockURLProtocol.response = nil
        mockURLProtocol.data = nil
        mockURLSession = nil
        super.tearDown()
    }

    func test_fetchSnapshot_whenAvailable_returnsSnapshotWithURL() async throws {
        mockURLProtocol.data = Data("""
        {
            "archived_snapshots": {
                "closest": {
                    "available": true,
                    "url": "http://web.archive.org/web/20130919044612/http://example.com/",
                    "timestamp": "20130919044612",
                    "status": "200"
                }
            }
        }
        """.utf8)

        let snapshot = try await WaybackService.fetchSnapshot(for: "example.com", session: mockURLSession)

        XCTAssertEqual(snapshot?.available, true)
        XCTAssertEqual(snapshot?.url, "http://web.archive.org/web/20130919044612/http://example.com/")
    }

    func test_fetchSnapshot_whenNotArchived_returnsNil() async throws {
        mockURLProtocol.data = Data("""
        {"archived_snapshots":{}}
        """.utf8)

        let snapshot = try await WaybackService.fetchSnapshot(for: "example.com", session: mockURLSession)

        XCTAssertNil(snapshot)
    }
}
