// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Message is a representation of `MessageData` from `GleanPlumb` that we can better utilize.
struct GleanPlumbMessage {

    /// The message Key, a unique identifier.
    let id: String

    /// An access point to MessageData from Nimbus Messaging.
    let data: MessageData

    /// The action to be done when a user positively engages with the message (CTA).
    let action: String

    /// The conditions that need to be satisfied for a message to be considered eligible to present.
    let triggers: [String]

    /// The access point to StyleData from Nimbus Messaging.
    let style: StyleData

    /// The minimal data about a message that we should persist.
    var metadata: GleanPlumbMessageMetaData

}

/// `MessageMeta` is where we store parts of the message that help us aggregate, query and determine non-expired messages.
struct GleanPlumbMessageMetaData: Codable {

    /// The message Key.
    let id: String

    /// The number of times a message was seen by the user.
    var impressions: Int

    /// The number of times a user intentionally dismissed the message.
    var dismissals: Int

    /// A message expiry status.
    var isExpired: Bool
}

