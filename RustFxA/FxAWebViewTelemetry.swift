// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum FxAFlow {
    case completed
    case startedFlow(type: FxAUrlPathStartedFlow)
}

enum FxAUrlPathStartedFlow: String {
    case signinStarted = "signin"
    case signupStarted = "signup"
    case confirmSignupCode = "confirm_signup_code"
    case signinTokenCode = "signin_token_code"
}

class FxAWebViewTelemetry {
//    Below are some valid flows for fxa url path but we only
//    record registration and sign in. Out of which /authorization and
//    /oauth can be skipped as they are mainly redirection flows that
//    leads to an actual login or registration page
//
//    Registration:
//    -------------
//    /authorization > /oauth > /oauth/signin > /oauth/signup >
//    /confirm_signup_code - This is not always guaranteed to show up
//
//    Sign in:
//    -------------
//    /authorization > /oauth > /oauth/signin >
//    /signin_token_code - This is not always guaranteed to show up
//
//    Other flows:
//    -------------
//    /reset_password
//    /confirm_reset_password

    // There are two valid started flow
    // signup and signin
    var validStartedFlow: FxAUrlPathStartedFlow?

    func getFlowFromUrl(fxaUrl: URL?) -> FxAUrlPathStartedFlow? {
        guard let url = fxaUrl,
              let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
              !urlComponents.path.isEmpty
        else { return nil }

        var pathElements = urlComponents.path.components(separatedBy: "/")
        pathElements.reverse()
        guard let element = pathElements.first(where: { !$0.isEmpty }),
              let flow = FxAUrlPathStartedFlow(rawValue: element)
        else { return nil }

        return flow
    }
    /// Records telemetry for  a particular FxAFlow
    ///
    /// - Parameters:
    ///     - flow: A type of FxAFlow for which telemetry has
    func recordTelemetry(for flow: FxAFlow) {
        let eventObject: TelemetryWrapper.EventObject
        switch flow {
        case .completed:
            switch validStartedFlow {
            case .signinStarted:
                eventObject = .fxaLoginCompleteWebpage
            case .signupStarted:
                eventObject = .fxaRegistrationCompletedWebpage
            default: return
            }
        case .startedFlow(let type):
            switch type {
            case .signinStarted:
                validStartedFlow = type
                eventObject = .fxaLoginWebpage
            case .signupStarted:
                validStartedFlow = type
                eventObject = .fxaRegistrationWebpage
            case .confirmSignupCode:
                eventObject = .fxaConfirmSignUpCode
            case .signinTokenCode:
                eventObject = .fxaConfirmSignInToken
            }
        }
        TelemetryWrapper.recordEvent(
            category: .firefoxAccount,
            method: .view,
            object: eventObject)
    }
}
