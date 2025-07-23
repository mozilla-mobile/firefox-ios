// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Delegate protocol for streaming chat completions.
public protocol LiteLLMStreamDelegate: AnyObject {
    /// Called when a new chunk of content is received.
    func liteLLMClient(_ client: LiteLLMClient, didReceive text: String)
    /// Called when the stream ends or errors out.
    func liteLLMClient(_ client: LiteLLMClient, didFinishWith error: Error?)
}
