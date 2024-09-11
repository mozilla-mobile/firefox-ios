// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The Message Store is responsible for tracking and updating certain metadata of a Message. This
/// will primarily help us determine if messages are expired, and perhaps what caused expiry.

protocol GleanPlumbMessageStoreProtocol {
    /// Return associated metadata for preexisting or new messages.
    func getMessageMetadata(messageId: String) -> GleanPlumbMessageMetaData

    /// Track and persist impression counts of the message.
    func onMessageDisplayed(_ message: GleanPlumbMessage)

    /// Track and persist user interactions with the message.
    func onMessagePressed(_ message: GleanPlumbMessage, shouldExpire: Bool)

    /// Do the bookkeeping for message dismissed Counts and expiry.
    func onMessageDismissed(_ message: GleanPlumbMessage)

    /// Handle all points of expiry and Telemetry.
    func onMessageExpired(_ message: GleanPlumbMessageMetaData,
                          surface: MessageSurfaceId,
                          shouldReport: Bool)
}

class GleanPlumbMessageStore: GleanPlumbMessageStoreProtocol {
    // MARK: - Properties

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    // Should not be used outside of unit test to reset the UserDefaults
    static let rootKey = "GleanPlumb.Messages."

    // MARK: - MessageStoreProtocol methods

    /// Returns the metadata that persists on system. If there's none, it returns default data.
    func getMessageMetadata(messageId: String) -> GleanPlumbMessageMetaData {
        // Return preexisting Message Metadata.
        if let metadata = get(key: messageId) { return metadata }

        return GleanPlumbMessageMetaData(id: messageId,
                                         impressions: 0,
                                         dismissals: 0,
                                         isExpired: false)
    }

    /// Update message metadata. Report if that message has expired, and then persist the updated message Metadata.
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        message.metadata.impressions += 1

        if message.isExpired {
            onMessageExpired(message.metadata,
                             surface: message.surface,
                             shouldReport: true)
        }

        set(key: message.id, metadata: message.metadata)
    }

    func onMessagePressed(_ message: GleanPlumbMessage, shouldExpire: Bool) {
        if shouldExpire {
            onMessageExpired(message.metadata,
                             surface: message.surface,
                             shouldReport: false)
        }

        set(key: message.id, metadata: message.metadata)
    }

    /// Depending on the surface, we may do different things with dismissal. But for the MVP,
    /// dismissal expires the message.
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        onMessageExpired(message.metadata,
                         surface: message.surface,
                         shouldReport: false)
        message.metadata.dismissals += 1

        set(key: message.id, metadata: message.metadata)
    }

    /// Updates a message's metadata and reports expiration Telemetry when applicable.
    /// A message expires in three ways (dismissal, interaction and max impressions), but only
    /// impressions should report an expired message.
    func onMessageExpired(
        _ messageData: GleanPlumbMessageMetaData,
        surface: MessageSurfaceId,
        shouldReport: Bool
    ) {
        messageData.isExpired = true

        if shouldReport {
            TelemetryWrapper.recordEvent(
                category: .information,
                method: .view,
                object: .messaging,
                value: .messageExpired,
                extras: [
                    TelemetryWrapper.EventExtraKey.messageKey.rawValue: messageData.id,
                    TelemetryWrapper.EventExtraKey.messageSurface.rawValue: surface.rawValue
                ])
        }
    }

    // MARK: - Private helpers

    /// Generate a key that's "treated" to prevent collisions.
    ///
    /// Collisions can happen if a message key string and a string elsewhere in the codebase happen to be the same.
    /// We prevent it by prepending `GleanPlumb.Messages.` to the message key.
    private func generateKey(from key: String) -> String {
        return "\(GleanPlumbMessageStore.rootKey)\(key)"
    }

    /// Persist a message's metadata.
    private func set(key: String, metadata: GleanPlumbMessageMetaData) {
        if let encoded = try? encoder.encode(metadata) {
            UserDefaults.standard.set(encoded, forKey: generateKey(from: key))
        }
        UserDefaults.resetStandardUserDefaults()
    }

    /// Return persisted message metadata.
    private func get(key: String) -> GleanPlumbMessageMetaData? {
        // Return a persisted message's metadata.
        if let decodableMessageMetaData = UserDefaults.standard.data(forKey: generateKey(from: key)),
           let decodedData = try? decoder.decode(GleanPlumbMessageMetaData.self, from: decodableMessageMetaData) {
            return decodedData
        }

        return nil
    }
}
