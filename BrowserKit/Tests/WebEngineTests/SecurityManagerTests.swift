// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class SecurityManagerTests: XCTestCase {
    // MARK: - Internal Navigation

    func testCanNavigateGivenInternalNotAUrlThenRefused() {
        let context = BrowsingContext(type: .internalNavigation,
                                      url: "blabla")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    func testCanNavigateGivenInternalNoSchemeThenRefused() {
        let context = BrowsingContext(type: .internalNavigation,
                                      url: "banana.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    func testCanNavigateGivenInternalAboutHTTPSThenAllowed() {
        let context = BrowsingContext(type: .internalNavigation,
                                      url: "https://mozilla.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    func testCanNavigateGivenInternalAboutUrlThenAllowed() {
        let context = BrowsingContext(type: .internalNavigation,
                                      url: "about://home.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    func testCanNavigateGivenInternalAboutSchemeOnlyUrlThenRefused() {
        let context = BrowsingContext(type: .internalNavigation,
                                      url: "about:")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    // MARK: - External Navigation

    func testCanNavigateGivenExternalNotAUrlThenRefused() {
        let context = BrowsingContext(type: .externalNavigation,
                                      url: "blabla")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    func testCanNavigateGivenExternalHTTPSURLThenAllowed() {
        let context = BrowsingContext(type: .externalNavigation,
                                      url: "https://mozilla.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    func testCanNavigateGivenExternalHTTPURLThenAllowed() {
        let context = BrowsingContext(type: .externalNavigation,
                                      url: "http://mozilla.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    func testCanNavigateGivenExternalDataURLThenAllowed() {
        let context = BrowsingContext(type: .externalNavigation,
                                      url: "data://someDataBlob.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    func testCanNavigateGivenExternalJavascriptURLThenRefused() {
        let context = BrowsingContext(type: .externalNavigation,
                                      url: "javascript://badurl.com")
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    // MARK: Helper

    func createSubject() -> DefaultSecurityManager {
        let subject = DefaultSecurityManager()
        trackForMemoryLeaks(subject)
        return subject
    }
}
