// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// Ecosia: Regression guard. These tests read the actual source/config files
// (rather than exercising runtime behavior) because what they protect - icon/theme
// swaps, a Tuist resource glob, an Info.plist key - isn't otherwise observable from a
// unit test: ShareViewController lives in an extension target that can't be
// instantiated in this test host, and the Tuist resource wiring is build-time only.
// If a future Firefox upstream merge drops one of these, the relevant assertion below
// should fail instead of the ShareTo extension quietly reverting to Firefox branding.
final class ShareToUpstreamCustomizationTests: XCTestCase {

    private func fileContents(at relativePath: String) throws -> String {
        let path = (RepoPath.root() as NSString).appendingPathComponent(relativePath)
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Strips `/* ... */` block comments so assertions only match live code, matching
    /// this repo's `/* Ecosia: <reason> ... */` convention for commenting out
    /// superseded Firefox code (see Ecosia.docc/agents/ARCHITECTURE.md).
    private func activeSource(_ source: String) -> String {
        source.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)
    }

    func testShareViewController_UsesEcosiaBrandingAndDropsSendToDevice() throws {
        // Given
        let source = try fileContents(at: "firefox-ios/Extensions/ShareTo/ShareViewController.swift")
        let active = activeSource(source)

        // Then: the Ecosia customizations are live...
        XCTAssertTrue(active.contains("EcosiaThemeManager"))
        XCTAssertTrue(active.contains("imageName: \"open-in-ecosia\""))
        XCTAssertTrue(active.contains("UIImage(named: \"ecosiaShareToIcon\")"))
        XCTAssertTrue(active.contains("forInfoDictionaryKey: \"MozPublicURLScheme\""))

        // ...and the superseded Firefox code they replace is not.
        XCTAssertFalse(active.contains("StandardImageIdentifiers.Large.logoFirefox"))
        XCTAssertFalse(active.contains("UIImage(named: \"Icon-Small\")"))
        XCTAssertFalse(active.contains("#selector(actionSendToDevice)"))
        XCTAssertFalse(active.contains("\"firefox://open-url"))
        XCTAssertFalse(active.contains("\"firefox://open-text"))
    }

    func testShareToInfoPlist_DeclaresPublicURLScheme() throws {
        let path = (RepoPath.root() as NSString).appendingPathComponent("firefox-ios/Extensions/ShareTo/Info.plist")
        let plist = try XCTUnwrap(NSDictionary(contentsOfFile: path))
        XCTAssertEqual(plist["MozPublicURLScheme"] as? String, "$(MOZ_PUBLIC_URL_SCHEME)")
    }

    func testExtensionTarget_BundlesEcosiaShareToAssets() throws {
        let source = try fileContents(at: "firefox-ios/Tuist/ProjectDescriptionHelpers/Targets+Extensions.swift")
        XCTAssertTrue(source.contains("Ecosia/UI/ShareToAssets.xcassets"))
    }
}
