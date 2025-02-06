// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class LanguageTests: XCTestCase {
    func testSettingLanguageCurrentToUnexpectedLanguageReturnsDefault() {
        Language.current = Language.make(for: Locale(identifier: "nz"))
        XCTAssertEqual(.en, Language.current)
    }

    func testMake() {
        XCTAssertEqual(.en, Language.make(for: .init(identifier: "en-DE")))
        XCTAssertEqual(.de, Language.make(for: .init(identifier: "de-MX")))
        XCTAssertEqual(.es, Language.make(for: .init(identifier: "es-ES")))
        XCTAssertEqual(.es, Language.make(for: .init(identifier: "es-MX")))
        XCTAssertEqual(.en, Language.make(for: .init(identifier: "en-US")))
        XCTAssertEqual(.es, Language.make(for: .init(identifier: "es-US")))
        XCTAssertEqual(.en, Language.make(for: .init(identifier: "Invalid")))
    }
}
