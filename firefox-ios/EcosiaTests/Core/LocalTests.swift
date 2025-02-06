// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class LocalTests: XCTestCase {
    func testCurrent() {
        Language.current = .en
        XCTAssertEqual("en-us", Language.current.locale.rawValue)
    }

    func testCountryCode() {
        let locale = NSLocale(localeIdentifier: "it-DE")
        XCTAssertEqual("DE", locale.countryCode)
        XCTAssertEqual(.de_de, Local.make(for: locale as Locale))
    }

    func testRegion() {
        XCTAssertEqual(.de_de, Local.make(for: .init(identifier: "en-DE")))
        XCTAssertEqual(.es_mx, Local.make(for: .init(identifier: "de-MX")))
        XCTAssertEqual(.es_es, Local.make(for: .init(identifier: "es-ES")))
        XCTAssertEqual(.es_mx, Local.make(for: .init(identifier: "es-MX")))
        XCTAssertEqual(.en_us, Local.make(for: .init(identifier: "en-US")))
        XCTAssertEqual(.es_us, Local.make(for: .init(identifier: "es-US")))
        XCTAssertEqual(.en_us, Local.make(for: .init(identifier: "Invalid")))
    }

    func testIdentifier() {
        XCTAssertEqual("en-us", Local.en_us.rawValue)
        XCTAssertEqual("de-de", Local.de_de.rawValue)
    }
}
