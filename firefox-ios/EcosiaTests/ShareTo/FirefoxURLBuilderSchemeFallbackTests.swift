// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ActionExtensionKit
import Foundation
import XCTest

// Ecosia: Regression guard. When `MozInternalURLScheme` is absent from
// Info.plist, upstream Firefox falls back to the "firefox" scheme. Ecosia must fall
// back to "ecosia" so ShareTo/action-extension deep links resolve to our app instead
// of a non-existent "firefox://" handler.
//
// EcosiaTests is app-hosted by Client (see Targets+Tests.swift), so `Bundle.main`
// here is the Client app bundle, which always has `MozInternalURLScheme` set to
// "ecosia" via EcosiaCommon.xcconfig - the fallback branch is never actually reached
// in this process. testMozInternalScheme_MatchesConfiguredScheme below only guards
// against that xcconfig value drifting; testFallbackSource_ReturnsEcosia is the one
// that actually guards the fallback code path itself, by asserting on the source.
final class FirefoxURLBuilderSchemeFallbackTests: XCTestCase {

    func testMozInternalScheme_MatchesConfiguredScheme() {
        let subject = FirefoxURLBuilder()
        XCTAssertEqual(subject.mozInternalScheme, "ecosia")
    }

    func testBuildFirefoxURL_UsesEcosiaScheme() throws {
        let subject = FirefoxURLBuilder()
        let shareItem = ActionShareItem(url: "https://example.com", title: nil)
        let result = try XCTUnwrap(subject.buildFirefoxURL(from: .shareItem(shareItem)))
        XCTAssertEqual(result.scheme, "ecosia")
    }

    func testFallbackSource_ReturnsEcosiaNotFirefox() throws {
        // Given
        let path = (RepoPath.root() as NSString)
            .appendingPathComponent("BrowserKit/Sources/ActionExtensionKit/FirefoxURLBuilding.swift")
        let source = try String(contentsOfFile: path, encoding: .utf8)
        let active = source.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)

        // Then: the line inside the `guard ... else` fallback, not the happy-path return
        let fallbackLine = try XCTUnwrap(
            active.components(separatedBy: "\n").first { $0.contains("return \"") && !$0.contains("return string") }
        )
        XCTAssertTrue(fallbackLine.contains("return \"ecosia\""), "Fallback line was: \(fallbackLine)")
    }
}
