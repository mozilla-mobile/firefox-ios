// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Defines the role of an LLM message, catching typos at compile time.
public enum LiteLLMRole: String, Codable {
    case system, user, assistant
}
