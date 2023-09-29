// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Utility functions related to Fakespot
public struct FakespotUtils {
    public static var learnMoreUrl: URL? {
        // Returns the predefined URL associated to learn more button action.
        return URL(string: "https://support.mozilla.org/kb/review-checker-review-quality")
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
        return URL(string: "https://www.fakespot.com/review-checker?utm_source=review-checker&utm_campaign=fakespot-by-mozilla&utm_medium=inproduct&utm_term=core-sheet")
    }
}
