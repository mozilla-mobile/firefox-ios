// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class SecurityManagerTests: XCTestCase {
    // MARK: - Internal Navigation

    @MainActor
    func testCanNavigateGivenInternalNotAUrlThenRefused() {
        let url = URL(string: "blabla")!
        let context = BrowsingContext(type: .internalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    @MainActor
    func testCanNavigateGivenInternalNoSchemeThenRefused() {
        let url = URL(string: "banana.com")!
        let context = BrowsingContext(type: .internalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    @MainActor
    func testCanNavigateGivenInternalAboutHTTPSThenAllowed() {
        let url = URL(string: "https://mozilla.com")!
        let context = BrowsingContext(type: .internalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    @MainActor
    func testCanNavigateGivenInternalAboutUrlThenAllowed() {
        let url = URL(string: "about://home.com")!
        let context = BrowsingContext(type: .internalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    @MainActor
    func testCanNavigateGivenInternalAboutSchemeOnlyUrlThenRefused() {
        let url = URL(string: "about:")!
        let context = BrowsingContext(type: .internalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    // MARK: - External Navigation
    @MainActor
    func testCanNavigateGivenExternalNotAUrlThenRefused() {
        let url = URL(string: "blabla")!
        let context = BrowsingContext(type: .externalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    @MainActor
    func testCanNavigateGivenExternalHTTPSURLThenAllowed() {
        let url = URL(string: "https://mozilla.com")!
        let context = BrowsingContext(type: .externalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    @MainActor
    func testCanNavigateGivenExternalHTTPURLThenAllowed() {
        let url = URL(string: "http://mozilla.com")!
        let context = BrowsingContext(type: .externalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    @MainActor
    func testCanNavigateGivenExternalDataURLThenAllowed() {
        let url = URL(string: "data://someDataBlob.com")!
        let context = BrowsingContext(type: .externalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .allowed)
    }

    @MainActor
    func testCanNavigateGivenExternalJavascriptURLThenRefused() {
        let url = URL(string: "javascript://badurl.com")!
        let context = BrowsingContext(type: .externalNavigation,
                                      url: url)
        let subject = createSubject()

        let result = subject.canNavigateWith(browsingContext: context)

        XCTAssertEqual(result, .refused)
    }

    // MARK: Helper
    @MainActor
    func createSubject() -> DefaultSecurityManager {
        let subject = DefaultSecurityManager()
        trackForMemoryLeaks(subject)
        return subject
    }
}
