// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Shared
@testable import Client

struct MockFxAUrls {
    static let mockSigInUrl = URL(string: "https://accounts.firefox.com/oauth/signin?action=email")!
    static let mockSignUpUrl = URL(string: "https://accounts.firefox.com/oauth/signup?action=email")!
    static let mockConfirmSignUpCodeUrl = URL(string: "https://accounts.firefox.com/oauth/confirm_signup_code")!
    // Added / in the end as some urls end with a slash
    static let mockSignInTockenUrl =  URL(string: "https://accounts.firefox.com/oauth/signin_token_code/")!
}

class SyncTelemetryTests: XCTestCase {

    var fxaWebViewTelemetry: FxAWebViewTelemetry!

    override func setUp() {
        super.setUp()
        fxaWebViewTelemetry = FxAWebViewTelemetry()
    }

    override func tearDown() {
        fxaWebViewTelemetry = nil
        super.tearDown()
    }

    func testSignInFlow() {
        let flow = fxaWebViewTelemetry.getFlowFromUrl(fxaUrl: MockFxAUrls.mockSigInUrl)
        XCTAssertNotNil(flow)
        XCTAssertEqual(flow, FxAUrlPathStartedFlow.signinStarted)
    }
    
    func testSignUpFlow() {
        let flow = fxaWebViewTelemetry.getFlowFromUrl(fxaUrl: MockFxAUrls.mockSignUpUrl)
        XCTAssertNotNil(flow)
        XCTAssertEqual(flow, FxAUrlPathStartedFlow.signupStarted)
    }
    
    func testSignInTokenFlow() {
        let flow = fxaWebViewTelemetry.getFlowFromUrl(fxaUrl: MockFxAUrls.mockSignInTockenUrl)
        XCTAssertNotNil(flow)
        XCTAssertEqual(flow, FxAUrlPathStartedFlow.signinTokenCode)
    }
    
    func testConfirmSignUpCodeFlow() {
        let flow = fxaWebViewTelemetry.getFlowFromUrl(fxaUrl: MockFxAUrls.mockConfirmSignUpCodeUrl)
        XCTAssertNotNil(flow)
        XCTAssertEqual(flow, FxAUrlPathStartedFlow.confirmSignupCode)
    }
}
