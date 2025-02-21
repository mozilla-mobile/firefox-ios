// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

@available(iOS 16.0, *)
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
        _ = createSubject()
    }

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> DefaultWKEngineWebView {
        let parameters = WKWebviewParameters(blockPopups: true, isPrivate: false)
        let configuration = DefaultWKEngineConfigurationProvider(parameters: parameters)
        let subject = DefaultWKEngineWebView(frame: .zero,
                                             configurationProvider: configuration)!
        subject.delegate = delegate
        trackForMemoryLeaks(subject, file: file, line: line)

        // Each registered teardown block is run once, in last-in, first-out order, executed serially.
        // Order is important here since the close() function needs to be called before we check for leaks
        addTeardownBlock { [weak subject] in
            subject?.close()
            print("Laurie -                     \(CFGetRetainCount(subject))")
        }

        return subject
    }
}
