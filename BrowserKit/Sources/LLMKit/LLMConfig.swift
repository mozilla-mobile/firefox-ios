// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A configuration container for our different features that uses LLM.
/// This used because we to generalize the configuration that we pass in for our `LiteLLMClient`.
public protocol LLMConfig: Sendable {
    var instructions: String { get }
    var options: [String: AnyHashable] { get }
}
