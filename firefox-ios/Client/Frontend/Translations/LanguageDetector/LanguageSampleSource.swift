// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A small abstraction for obtaining a language sample from webpage content.
/// This is done to allow `LanguageDetector` to request text from a page without knowing
/// whether the source is a real `WKWebView` running JavaScript or a test mock.
protocol LanguageSampleSource: Sendable {
    /// `scriptEvalExpression` is the JavaScript expression that should be evaluated
    /// by the underlying implementation.
    @MainActor
    func getLanguageSample(scriptEvalExpression: String) async throws -> String?
}
