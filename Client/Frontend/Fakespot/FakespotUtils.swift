// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Utility functions related to Fakespot
public struct FakespotUtils {
    public static var learnMoreUrl: URL? {
        // Returns the predefined URL associated to learn more button action.
        guard let url = SupportUtils.URLForTopic("review_checker_mobile") else { return nil }

        let queryItems = [URLQueryItem(name: "utm_campaign", value: "fakespot-by-mozilla"),
                          URLQueryItem(name: "utm_term", value: "core-sheet")]
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = queryItems

        return urlComponents?.url
    }

    public static var privacyPolicyUrl: URL? {
        // Returns the predefined URL associated to privacy policy button action.
        return URL(string: "https://www.fakespot.com/privacy-policy")
    }

    public static var termsOfUseUrl: URL? {
        // Returns the predefined URL associated to terms of use button action.
        return URL(string: "https://www.fakespot.com/terms")
    }

    public static var fakespotUrl: URL? {
        // Returns the predefined URL associated to Fakespot button action.
        return URL(string: "https://www.fakespot.com/our-mission?utm_source=review-checker&utm_campaign=fakespot-by-mozilla&utm_medium=inproduct&utm_term=core-sheet")
    }
}
