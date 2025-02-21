// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

final class WKEngineWebViewTests: XCTestCase {
    private var delegate: MockWKEngineWebViewDelegate!

    override func setUp() {
        super.setUp()
        delegate = MockWKEngineWebViewDelegate()
    }

    override func tearDown() {
        delegate = nil
        super.tearDown()
    }

    func testNoLeaks() {
        let subject = createSubject()
        subject.close()

        // Wait for Webview to fully deallocate
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testLoadingObserver() {
        let subject = createSubject()
        let expectation = keyValueObservingExpectation(for: subject, keyPath: "loading", expectedValue: false)

        subject.load(URLRequest(url: URL(string: "https://www.example.com")!))

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(delegate.progressChangedCalled, 3)
        XCTAssertEqual(delegate.loadingChangedCalled, 2)
        XCTAssertEqual(delegate.urlChangedCalled, 1)
        XCTAssertEqual(delegate.hasOnlySecureBrowserChangedCalled, 1)
    }

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> DefaultWKEngineWebView {
        let parameters = WKWebviewParameters(blockPopups: true, isPrivate: false)
        let configuration = DefaultWKEngineConfigurationProvider(parameters: parameters)
        let subject = DefaultWKEngineWebView(frame: .zero,
                                             configurationProvider: configuration)!
        subject.delegate = delegate
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
