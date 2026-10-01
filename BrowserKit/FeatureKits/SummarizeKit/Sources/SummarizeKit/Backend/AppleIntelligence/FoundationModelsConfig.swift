// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct FoundationModelsConfig {
    /// `maxWords` limits the number of words in the input text.
    /// 3000 words was computed by assuming an average of 1.3 tokens per word.
    /// Given the foundation model’s 4,096 token context window, this brings us to approx. 3000 words.
    public static let maxWords = 3_000
}
