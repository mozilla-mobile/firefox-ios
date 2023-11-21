// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
 
#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class RequestHandlerTests: XCTestCase {
    
    private let alertCallback: (UIAlertController) -> Void = { _ in }
    private let reguestHandler = RequestHandler()
    private let EXTERNAL_SCHEME = "itms-appss"
    private let INVALID_URL = "Invalid URL"
    private let HTTPS_INTERNAL_SCHEME = "https"
    private let EXAMPLE_HOST = "www.example.com"
    
    func testValidURLAndScheme() {
        let urlRequest = URLRequest(url: URL(string: "\(HTTPS_INTERNAL_SCHEME)://\(EXAMPLE_HOST)")!)
        let sut = reguestHandler.handle(request: urlRequest, alertCallback: alertCallback)
        XCTAssertTrue(sut)
    }
    
    func testInvalidURLAndScheme() {
        var urlRequest = URLRequest(url: URL(string: "\(HTTPS_INTERNAL_SCHEME)://\(EXAMPLE_HOST)")!)
        urlRequest.url = URL(string: INVALID_URL)
        let sut = reguestHandler.handle(request: urlRequest, alertCallback: alertCallback)
        XCTAssertFalse(sut)
    }
    
    func testSchemeIsNotInternalScheme() {
        let urlRequest = URLRequest(url: URL(string: "\(EXTERNAL_SCHEME)://\(EXAMPLE_HOST)")!)
        let sut = reguestHandler.handle(request: urlRequest, alertCallback: alertCallback)
        XCTAssertFalse(sut)
    }
    
    func testInternalSchemeAndHostIsNil() {
        let urlRequest = URLRequest(url: URL(string: "\(HTTPS_INTERNAL_SCHEME)://")!)
        let sut = reguestHandler.handle(request: urlRequest, alertCallback: alertCallback)
        XCTAssertTrue(sut)
    }
    
    func testInternalSchemeAndSpecialCaseHosts() {
        var urlRequest = URLRequest(url: URL(string: "\(HTTPS_INTERNAL_SCHEME)://\("maps.apple.com")")!)
        var sut = reguestHandler.handle(request: urlRequest, alertCallback: alertCallback)
        XCTAssertFalse(sut)
        urlRequest = URLRequest(url: URL(string: "\(HTTPS_INTERNAL_SCHEME)://\("itunes.apple.com")")!)
        sut = reguestHandler.handle(request: urlRequest, alertCallback: alertCallback)
        XCTAssertFalse(sut)
    }
}
