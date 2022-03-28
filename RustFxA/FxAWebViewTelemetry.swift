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
        guard let url = fxaUrl else { return nil }
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        guard !urlComponents.path.isEmpty else { return nil }
        var pathElements = urlComponents.path.components(separatedBy: "/")
        pathElements.reverse()
        guard let element = pathElements.first(where: { $0 != "" }),
              let flow = FxAUrlPathStartedFlow(rawValue: element) else {
            return nil
        }

        return flow
    }

    func recordTelemetry(for flow: FxAFlow) {
        switch flow {
        case .completed:
            if validStartedFlow == .signinStarted {
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view,
                                             object: .fxaLoginCompleteWebpage)
            } else if validStartedFlow == .signupStarted {
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view,
                                             object: .fxaRegistrationCompletedWebpage)
            }
        case .startedFlow(let type):
            switch type {
            case .signinStarted:
                validStartedFlow = type
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view,
                                             object: .fxaLoginWebpage)
            case .signupStarted:
                validStartedFlow = type
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view,
                                             object: .fxaRegistrationWebpage)
            case .confirmSignupCode:
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view,
                                             object: .fxaConfirmSignUpCode)
            case .signinTokenCode:
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .view,
                                             object: .fxaConfirmSignInToken)
            }
        }
    }
}
