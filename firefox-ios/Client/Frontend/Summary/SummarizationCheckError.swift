// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Possible errors encountered when evaluating or parsing the JS result.
public enum SummarizationCheckError: Error {
    /// Thrown when `evaluateJavaScript` itself fails.
    case jsEvaluationFailed(Error)
    /// Thrown when the raw JS result is not valid JSON.
    case invalidJSON
    /// Thrown when decoding the JSON into a model fails.
    case decodingFailed(Error)

    var description: String {
        switch self {
        case .jsEvaluationFailed(let error):
            return "JavaScript evaluation failed: \(error.localizedDescription)"
        case .invalidJSON:
            return "Invalid JSON from page script"
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        }
    }
}
