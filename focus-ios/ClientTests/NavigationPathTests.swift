// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class NavigationPathTests: XCTestCase {
    
    private var appScheme: String {
        AppInfo.isKlar ? "firefox-klar" : "firefox-focus"
    }
    
    private let address = "https://www.apple.com/"
    private let badAddress = "boomer"
    
    func testHostIsOpenURLAndTheAddressIsValid() {
        let appAddress = "\(appScheme)://open-url?url=\(address)"
        let sut = NavigationPath(url: URL(string: appAddress)!)!
        XCTAssertEqual(sut,
                       NavigationPath.url(URL(string: address)!))
    }
    
    func testHostIsOpenURLAndTheAddressIsNotValid() {
        let appAddress = "\(appScheme)://open-url?url=\(badAddress)"
        let sut = NavigationPath(url: URL(string: appAddress)!)
        XCTAssertEqual(sut,
                       NavigationPath.url(URL(string: badAddress)!))
    }
    
    func testHostIsOpenTextAndTheAddressIsValid() {
        let appAddress = "\(appScheme)://open-text?text=\(address)"
        let sut = NavigationPath(url: URL(string: appAddress)!)!
        XCTAssertEqual(sut,
                       NavigationPath.text(address))
    }
    
    func testHostIsOpenTextAndTheAddressIsNotValid() {
        let appAddress = "\(appScheme)://open-text?text=\(badAddress)"
        let sut = NavigationPath(url: URL(string: appAddress)!)!
        XCTAssertEqual(sut,
                       NavigationPath.text(badAddress))
    }
    
    func testSchemesAreCaseInsensitive() {
        XCTAssertEqual(NavigationPath(url: URL(string: "HtTpS://www.apple.com")!),
                       NavigationPath.url(URL(string: "https://www.apple.com")!))
        
        XCTAssertEqual(NavigationPath(url: URL(string: "\(appScheme.uppercased())://open-url?url=\(address)")!),
                       NavigationPath.url(URL(string: address)!))
    }
}
