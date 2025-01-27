// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Localizations

import XCTest

/// Firefox has a complicated localization story, and stores its strings in its own bundle.
/// This tests allow us to write code in Nimbus with some confidence that it will work here.
class NimbusIntegrationTests: XCTestCase {
    func testStringBundleAccess() throws {
        XCTAssertEqual(Locale.current.languageCode, "en")
        let stringWithNoTable = Strings.bundle.localizedString(
            forKey: "ShareExtension.OpenInFirefoxAction.Title",
            value: nil,
            table: nil
        )
        XCTAssertEqual(stringWithNoTable, "Open in Firefox")

        let stringWithTable = Strings.bundle.localizedString(
            forKey: "DefaultBrowserCard.Title",
            value: nil,
            table: "Default Browser"
        )
        XCTAssertEqual(stringWithTable, "Switch Your Default Browser")
    }

    func testStringFallbackBundleAccessExplicitLanguage() throws {
        let bundles = [
            Bundle.main,
            Strings.bundle.fallbackTranslationBundle(language: "es"),
        ].compactMap { $0 }
        let stringWithNoTable = bundles.getString(named: "ShareExtension.OpenInFirefoxAction.Title")
        XCTAssertEqual(stringWithNoTable, "Abrir en Firefox")

        let stringWithTable = bundles.getString(named: "Default Browser/DefaultBrowserCard.Title")
        XCTAssertEqual(stringWithTable, "Cambia tu navegador predeterminado")
    }

    func testStringFallbackBundleAccessImplicitLanguage() throws {
        let bundles = [
            Bundle.main,
            Strings.bundle.fallbackTranslationBundle(),
        ].compactMap { $0 }
        let stringWithNoTable = bundles.getString(named: "ShareExtension.OpenInFirefoxAction.Title")
        XCTAssertEqual(stringWithNoTable, "Open in Firefox")

        let stringWithTable = bundles.getString(named: "Default Browser/DefaultBrowserCard.Title")
        XCTAssertEqual(stringWithTable, "Switch Your Default Browser")
    }

    func testNSLocalizedStringAccess() throws {
        XCTAssertEqual(Locale.current.languageCode, "en")
        let stringWithNoTable = NSLocalizedString(
            "ShareExtension.OpenInFirefoxAction.Title",
            bundle: Strings.bundle,
            comment: ""
        )
        XCTAssertEqual(stringWithNoTable, "Open in Firefox")

        let stringWithTable = NSLocalizedString(
            "DefaultBrowserCard.Title",
            tableName: "Default Browser",
            bundle: Strings.bundle,
            comment: ""
        )
        XCTAssertEqual(stringWithTable, "Switch Your Default Browser")
    }

    func testLocalizedString_ForDefaultBrowserButton() throws {
        XCTAssertEqual(Locale.current.languageCode, "en")

        let nsString = NSLocalizedString(
            "DefaultBrowserCard.Button.v2",
            tableName: "Default Browser",
            bundle: Strings.bundle,
            comment: ""
        )
        XCTAssertEqual(nsString, "Learn How")

        let localizedString = Strings.bundle.localizedString(
            forKey: "DefaultBrowserCard.Button.v2",
            value: nil,
            table: "Default Browser"
        )
        XCTAssertEqual(localizedString, "Learn How")
    }
}
