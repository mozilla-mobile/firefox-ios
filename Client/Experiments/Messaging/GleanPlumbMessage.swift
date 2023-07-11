// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol MessageDataProtocol {
    var surface: MessageSurfaceId { get }
    var isControl: Bool { get }
    var title: String? { get }
    var text: String { get }
    var buttonLabel: String? { get }
    var experiment: String? { get }
}

extension MessageData: MessageDataProtocol {}

protocol StyleDataProtocol {
    var priority: Int { get }
    var maxDisplayCount: Int { get }
}

extension StyleData: StyleDataProtocol {}

/// Message is a representation of `MessageData` from `GleanPlumb` that we can better utilize.
struct GleanPlumbMessage {
    /// The message Key, a unique identifier.
    let id: String

    /// An access point to MessageData from Nimbus Messaging.
    internal let data: MessageDataProtocol

    /// The action to be done when a user positively engages with the message (CTA).
    let action: String

    /// The conditions that need to be satisfied for a message to be considered eligible to present.
    let triggers: [String]

    /// The access point to StyleData from Nimbus Messaging.
    let style: StyleDataProtocol

    /// The minimal data about a message that we should persist.
    internal var metadata: GleanPlumbMessageMetaData

    var isExpired: Bool {
        metadata.isExpired || metadata.impressions >= style.maxDisplayCount
    }

    var buttonLabel: String? {
        data.buttonLabel
    }

    var text: String {
        data.text
    }

    var title: String? {
        data.title
    }

    var surface: MessageSurfaceId {
        data.surface
    }
}

/// `MessageMeta` is where we store parts of the message that help us aggregate, query and determine non-expired messages.
class GleanPlumbMessageMetaData: Codable {
    /// The message Key.
    let id: String

    /// The number of times a message was seen by the user.
    var impressions: Int

    /// The number of times a user intentionally dismissed the message.
    var dismissals: Int

    /// A message expiry status.
    var isExpired: Bool

    init(id: String, impressions: Int, dismissals: Int, isExpired: Bool) {
        self.id = id
        self.impressions = impressions
        self.dismissals = dismissals
        self.isExpired = isExpired
    }
}
