/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import XCTest
@testable import Firefox_Focus

class DomainCompletionTests: XCTestCase {
    private let SIMPLE_DOMAIN = "example.com"
    private let HTTP_DOMAIN = "http://example.com"
    private let HTTPS_DOMAIN = "https://example.com"
    private let WWWW_DOMAIN = "https://www.example.com"
    private let TEST_NO_PERIOD = "example"
    
    func testAddCustomDomain() {
        addADomain(domain: SIMPLE_DOMAIN)
    }
    
    func testAddCustomDomainWithHttp() {
        addADomain(domain: HTTP_DOMAIN)
    }
    
    func testAddCustomDomainWithHttps() {
        addADomain(domain: HTTPS_DOMAIN)
    }
    
    func testAddCustomDomainWithWWW() {
        addADomain(domain: WWWW_DOMAIN)
    }
    
    func testAddCustomDomainDuplicate() {
        Settings.setCustomDomainSetting(domains: [SIMPLE_DOMAIN])
        switch CustomCompletionSource().add(suggestion: WWWW_DOMAIN) {
        case .error(let error):
            XCTAssertEqual(error, .duplicateDomain)
        case .success:
            XCTFail()
        }
    }
    
    func testRemoveCustomDomain() {
        Settings.setCustomDomainSetting(domains: [SIMPLE_DOMAIN])
        switch CustomCompletionSource().remove(at: 0) {
        case .error:
            XCTFail()
        case .success:
            XCTAssertEqual(0, Settings.getCustomDomainSetting().count)
        }
    }
    
    func testAddCustomDomainWithoutPeriod() {
        Settings.setCustomDomainSetting(domains: [])
        switch CustomCompletionSource().add(suggestion: TEST_NO_PERIOD) {
        case .error(let error):
            XCTAssertEqual(error, .invalidUrl)
        case .success:
            XCTFail()
        }
    }
    
    private func addADomain(domain: String) {
        Settings.setCustomDomainSetting(domains: [])
        switch CustomCompletionSource().add(suggestion: domain) {
        case .error(_):
            XCTFail()
        case .success:
            let domains = Settings.getCustomDomainSetting()
            XCTAssertEqual(domains.count, 1)
        }
    }
}
