// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Using explicit roles not only catches typos at compile time, it also helps mitigate prompt-injection:
/// - `system`: trusted policy/constraints the model must follow
/// - `user`: untrusted input that should never override `system` content
/// - `assistant`: model output
public enum LiteLLMRole: String, Codable, Sendable {
    case system, user, assistant
}
