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
    var actionParams: [String: String] { get }
    var microsurveyConfig: MicrosurveyConfig? { get }
}

extension MessageData: MessageDataProtocol {}

protocol StyleDataProtocol {
    var priority: Int { get }
    var maxDisplayCount: Int { get }
}

extension StyleData: StyleDataProtocol {}

/// Message is a facade object onto configuration provided by the Nimbus Messaging component
/// and the Nimbus SDK.
struct GleanPlumbMessage {
    /// The message Key, a unique identifier.
    ///
    /// This is corresponds to a MessageKey string from Nimbus.
    ///
    let id: String

    /// The underlying MessageData from Nimbus.
    ///
    /// Embedding apps should not read from this directly.
    let data: MessageDataProtocol

    /// The action URL as resolved by the Nimbus Messaging component.
    ///
    /// Embedding apps should not read from this directly.
    let action: String?

    /// The conditions that need to be satisfied for a message to be considered eligible to present.
    ///
    /// Embedding apps should not read from this directly.
    let triggerIfAll: [String]

    /// The conditions that need to be not satisfied for a message to be considered eligible to present.
    ///
    /// Embedding apps should not read from this directly.
    let exceptIfAny: [String]

    /// The access point to StyleData from Nimbus Messaging.
    ///
    /// Embedding apps should not read from this directly.
    let style: StyleDataProtocol

    /// The minimal data about a message that we should persist.
    ///
    /// Embedding apps should not read from this directly.
    var metadata: GleanPlumbMessageMetaData

    /// Has the message been shown a maximal number of times?
    ///
    /// Embedding apps should not read from this directly.
    var isExpired: Bool {
        metadata.isExpired || metadata.impressions >= style.maxDisplayCount
    }

    /// Has the message been tapped on or dismissed.
    ///
    /// Embedding apps should not read from this directly.
    var isInteractedWith: Bool {
        metadata.isExpired || metadata.dismissals > 0
    }

    /// The surface id for this message.
    ///
    /// Embedding apps should not read from this directly.
    var surface: MessageSurfaceId {
        data.surface
    }

    /// The survey options for this message if it has a microsurvey configuration.
    /// Embedding apps should not read from this directly.
    var options: [String] {
        return data.microsurveyConfig?.options ?? []
    }

    /// The icon for this message if it has a microsurvey configuration.
    /// Embedding apps should not read from this directly.
    var icon: UIImage? {
        return data.microsurveyConfig?.icon
    }

    var utmContent: String? {
        return data.microsurveyConfig?.utmContent
    }
}

/// Public properties for this message.
///
/// These are the only properties needed by the message surfaces.
extension GleanPlumbMessage {
    /// Button label. If the button is tapped then call `messaging.onMessageClicked(message)`
    ///
    /// If the button label is `nil`, don't draw a button, and make the whole message surface tappable.
    public var buttonLabel: String? {
        data.buttonLabel
    }

    /// The message to be displayed
    public var text: String {
        data.text
    }

    /// The title to be displayed above the message.
    ///
    /// If this is `nil` then do not display a title.
    public var title: String? {
        data.title
    }
}

/// `MessageMeta` is where we store parts of the message that help us aggregate, query
/// and determine non-expired messages.
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
