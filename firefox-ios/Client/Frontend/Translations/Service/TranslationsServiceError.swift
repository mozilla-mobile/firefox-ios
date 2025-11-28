// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Errors thrown by `TranslationsService` when preconditions or WebView state are invalid.
enum TranslationsServiceError: Error, Equatable {
    case missingWebView
    case deviceLanguageUnavailable
    case jsEvaluationFailed(reason: String)
    case pageLanguageDetectionFailed(description: String)
    case unknown(domain: String, code: Int)
    /// Converts an unknown error into a `TranslationsServiceError`.
    /// This intentionally loses information about the original error type.
    /// We don't want to collect potentially sensitive error details in telemetry for unknown errors.
    static func fromUnknown(_ error: Error) -> TranslationsServiceError {
        if let known = error as? TranslationsServiceError {
            return known
        }
        let ns = error as NSError
        return .unknown(domain: ns.domain, code: ns.code)
    }
    /// Stable, telemetry-safe description for this error.
    /// We don't strictly need this since the enum cases are already not using any raws error messages,
    /// but this makes it explicit and easier to control.
    var telemetryDescription: String {
        switch self {
        case .missingWebView:
            return "missing_webview"
        case .deviceLanguageUnavailable:
            return "device_language_unavailable"
        case .jsEvaluationFailed(let reason):
            /// reason is already a stable token like "JS evaluation failed: startTranslationsJS"
            return "js_evaluation_failed(\(reason))"
        case .pageLanguageDetectionFailed(let description):
            return "page_language_detection_failed(\(description))"
        case .unknown(let domain, let code):
            return "unknown(domain:\(domain),code:\(code))"
        }
    }
}
