// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class MetadataFetcherHelperTests: XCTestCase {
    var metadataDelegate: MockMetadataFetcherDelegate!

    override func setUp() {
        super.setUp()
        metadataDelegate = MockMetadataFetcherDelegate()
    }

    override func tearDown() {
        super.tearDown()
        metadataDelegate = nil
    }

    func testFetchFromSessionGivenNotWebpageURLThenPageMetadataNil() {
        let subject = createSubject()
        let session = MockWKEngineSession()
        let url = URL(string: "blob:example.com")!

        subject.fetch(fromSession: session, url: url)

        XCTAssertNil(session.sessionData.pageMetadata)
    }

    func testFetchFromSessionGivenInternalURLThenPageMetadataNil() {
        let subject = createSubject()
        let session = MockWKEngineSession()
        let url = URL(string: "http://localhost:1234/test-fixture/")!

        subject.fetch(fromSession: session, url: url)

        XCTAssertNil(session.sessionData.pageMetadata)
        XCTAssertEqual(metadataDelegate.didLoadPageMetadataCalled, 0)
    }

    func testFetchFromSessionGivenErrorThenPageMetadataNil() {
        let subject = createSubject()
        let session = MockWKEngineSession()
        let url = URL(string: "https://mozilla.com")!
        enum TestError: Error { case example }
        session.webviewProvider.webView.javascriptResult = .failure(TestError.example)

        subject.fetch(fromSession: session, url: url)

        XCTAssertNil(session.sessionData.pageMetadata)
        XCTAssertEqual(metadataDelegate.didLoadPageMetadataCalled, 0)
    }

    func testFetchFromSessionGivenURLThenJavascriptIsProper() {
        let expectedJavascript = "__firefox__.metadata && __firefox__.metadata.getMetadata()"
        let subject = createSubject()
        let session = MockWKEngineSession()
        let url = URL(string: "https://mozilla.com")!

        subject.fetch(fromSession: session, url: url)

        XCTAssertEqual(session.webviewProvider.webView.savedJavaScript, expectedJavascript)
        XCTAssertEqual(metadataDelegate.didLoadPageMetadataCalled, 0)
    }

    func testFetchFromSessionGivenEmptyResultThenPageMetadataNil() {
        let subject = createSubject()
        let session = MockWKEngineSession()
        let url = URL(string: "https://mozilla.com")!
        session.webviewProvider.webView.javascriptResult = .success(["": ""])

        subject.fetch(fromSession: session, url: url)

        XCTAssertNil(session.sessionData.pageMetadata)
        XCTAssertEqual(metadataDelegate.didLoadPageMetadataCalled, 0)
    }

    func testFetchFromSessionGivenPageMetadataResultThenPageMetadataDelegateCalled() {
        let expectedTitle = "Some title"
        let expectedPageMetadata = createDictionnaryPageMetadata(title: expectedTitle)
        let subject = createSubject()
        let session = MockWKEngineSession()
        let url = URL(string: "https://mozilla.com")!
        session.webviewProvider.webView.javascriptResult = .success(expectedPageMetadata)

        subject.fetch(fromSession: session, url: url)

        XCTAssertNotNil(session.sessionData.pageMetadata)
        XCTAssertEqual(session.sessionData.pageMetadata?.title, expectedTitle)
        XCTAssertEqual(metadataDelegate.didLoadPageMetadataCalled, 1)
    }

    // MARK: Helper

    func createSubject() -> MetadataFetcherHelper {
        return DefaultMetadataFetcherHelper(delegate: metadataDelegate)
    }

    func createDictionnaryPageMetadata(title: String) -> [String: Any] {
        return [
            MetadataKeys.imageURL.rawValue: "",
            MetadataKeys.imageDataURI.rawValue: "",
            MetadataKeys.pageURL.rawValue: "",
            MetadataKeys.title.rawValue: title,
            MetadataKeys.description.rawValue: "",
            MetadataKeys.type.rawValue: "",
            MetadataKeys.provider.rawValue: "",
            MetadataKeys.favicon.rawValue: "",
            MetadataKeys.keywords.rawValue: "",
            MetadataKeys.language.rawValue: ""
        ]
    }
}

class MockMetadataFetcherDelegate: MetadataFetcherDelegate {
    var didLoadPageMetadataCalled = 0

    func didLoad(pageMetadata: EnginePageMetadata) {
        didLoadPageMetadataCalled += 1
    }
}
