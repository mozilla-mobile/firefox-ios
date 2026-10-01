// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// All supported LLM backends, This is used mainly as an identifier instead of using raw strings.
public enum SummarizerModel: String, Sendable {
    case appleSummarizer
    case liteLLMSummarizer
}
