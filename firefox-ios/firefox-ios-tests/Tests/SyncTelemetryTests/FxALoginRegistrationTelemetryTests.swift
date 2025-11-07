// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
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
    var telemetryWrapper: MockTelemetryWrapper!

    override func setUp() {
        super.setUp()
        telemetryWrapper = MockTelemetryWrapper()
        fxaWebViewTelemetry = FxAWebViewTelemetry(telemetryWrapper: telemetryWrapper)
    }

    override func tearDown() {
        fxaWebViewTelemetry = nil
        telemetryWrapper = nil
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

    // MARK: - recordTelemetry() tests

      func testRecordTelemetry_signinStarted_recordsCorrectEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .startedFlow(type: .signinStarted))

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 1)
          XCTAssertEqual(telemetryWrapper.recordedCategories.first, .firefoxAccount)
          XCTAssertEqual(telemetryWrapper.recordedMethods.first, .view)
          XCTAssertEqual(telemetryWrapper.recordedObjects.first, .fxaLoginWebpage)
      }

      func testRecordTelemetry_signinCompleted_recordsCorrectEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .startedFlow(type: .signinStarted))
          fxaWebViewTelemetry.recordTelemetry(for: .completed)

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 2)
          XCTAssertEqual(telemetryWrapper.recordedObjects.last, .fxaLoginCompleteWebpage)
      }

      func testRecordTelemetry_signinTokenCode_recordsCorrectEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .startedFlow(type: .signinTokenCode))

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 1)
          XCTAssertEqual(telemetryWrapper.recordedCategories.first, .firefoxAccount)
          XCTAssertEqual(telemetryWrapper.recordedMethods.first, .view)
          XCTAssertEqual(telemetryWrapper.recordedObjects.first, .fxaConfirmSignInToken)
      }

      func testRecordTelemetry_signupStarted_recordsCorrectEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .startedFlow(type: .signupStarted))

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 1)
          XCTAssertEqual(telemetryWrapper.recordedCategories.first, .firefoxAccount)
          XCTAssertEqual(telemetryWrapper.recordedMethods.first, .view)
          XCTAssertEqual(telemetryWrapper.recordedObjects.first, .fxaRegistrationWebpage)
      }

      func testRecordTelemetry_signupCompleted_recordsCorrectEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .startedFlow(type: .signupStarted))
          fxaWebViewTelemetry.recordTelemetry(for: .completed)

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 2)
          XCTAssertEqual(telemetryWrapper.recordedObjects.last, .fxaRegistrationCompletedWebpage)
      }

      func testRecordTelemetry_confirmSignupCode_recordsCorrectEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .startedFlow(type: .confirmSignupCode))

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 1)
          XCTAssertEqual(telemetryWrapper.recordedCategories.first, .firefoxAccount)
          XCTAssertEqual(telemetryWrapper.recordedMethods.first, .view)
          XCTAssertEqual(telemetryWrapper.recordedObjects.first, .fxaConfirmSignUpCode)
      }

      func testRecordTelemetry_completedWithoutStartedFlow_doesNotRecordEvent() {
          fxaWebViewTelemetry.recordTelemetry(for: .completed)

          XCTAssertEqual(telemetryWrapper.recordEventCallCount, 0)
      }
}
