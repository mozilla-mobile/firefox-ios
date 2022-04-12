// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The Message Store is responible for tracking and updating certain metadata of a Message. This
/// will primarily help us determine if messages are expired, and perhaps what caused expiry.

protocol GleanPlumbMessagingStoreProtocol {

    /// Return associated metadata for preexisting or new messages.
    func getMessageMetadata(messageId: String) -> GleanPlumbMessageMetaData

    /// Track and persist impression counts of the message.
    func onMessageDisplayed(_ message: GleanPlumbMessage)

    /// Track and persist user interactions with the message.
    func onMessagePressed(_ message: GleanPlumbMessage)

    /// Do the bookkeeping for message dismissed Counts and expiry.
    func onMessageDismissed(_ message: GleanPlumbMessage)

    /// Handle all points of expiry and Telemetry, and returns an updated metadata object for use.
    func onMessageExpired(_ message: GleanPlumbMessageMetaData, shouldReport: Bool) -> GleanPlumbMessageMetaData

}

class GleanPlumbMessageStore: GleanPlumbMessagingStoreProtocol {

    // MARK: - Properties

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let messagingHelper: GleanPlumbHelper

    init(messagingHelper: GleanPlumbHelper = GleanPlumbHelper()) {
        self.messagingHelper = messagingHelper
    }

    // MARK: - MessageStoreProtocol methods

    /// Returns the metadata that persists on system. If there's none, it returns default data.
    func getMessageMetadata(messageId: String) -> GleanPlumbMessageMetaData {

        /// Return preexisting Message Metadata.
        if let metadata = get(key: messageId) {
            return metadata
        }

        return GleanPlumbMessageMetaData(id: messageId,
                                         impressions: 0,
                                         dismissals: 0,
                                         isExpired: false)
    }

    /// Update message metadata and persist that information.
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        var messageToTrack = message.metadata

        messageToTrack.impressions += 1

        if messagingHelper.checkExpiryFor(message) {
            messageToTrack = onMessageExpired(messageToTrack, shouldReport: true)
        }

        set(key: message.id, metadata: messageToTrack)
    }

    /// For the MVP, we always expire the message.
    func onMessagePressed(_ message: GleanPlumbMessage) {
        let messageToTrack = onMessageExpired(message.metadata, shouldReport: false)

        set(key: message.id, metadata: messageToTrack)
    }

    /// Depending on the surface, we may do different things with dismissal. But for the MVP,
    /// dismissal expires the message.
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        var messageToTrack = onMessageExpired(message.metadata, shouldReport: false)

        messageToTrack.dismissals += 1

        set(key: message.id, metadata: messageToTrack)
    }

    /// Updates a message's metadata and reports expiration Telemetry when applicable.
    /// A message expires in three ways (dismissal, interaction and max impressions), but only
    /// impressions should report an expired message.
    func onMessageExpired(_ message: GleanPlumbMessageMetaData, shouldReport: Bool) -> GleanPlumbMessageMetaData {
        var messageToTrack = message
        messageToTrack.isExpired = true

        if shouldReport {
            TelemetryWrapper.recordEvent(category: .information,
                                         method: .view,
                                         object: .homeTabBanner,
                                         value: .messageExpired,
                                         extras: [TelemetryWrapper.EventExtraKey.messageKey.rawValue: message.id])
        }

        return messageToTrack
    }

    // MARK: - Private helpers

    /// Generate a key that's "treated" to prevent collisions.
    private func generateKey(from key: String) -> String {
        return "GleanPlumb.Messages.\(key)"
    }

    /// Persist a message's metadata.
    private func set(key: String, metadata: GleanPlumbMessageMetaData) {
        if let encoded = try? encoder.encode(metadata) {
            UserDefaults.standard.set(encoded, forKey: generateKey(from: key))
        }
    }

    /// Return persisted message metadata.
    private func get(key: String) -> GleanPlumbMessageMetaData? {

        /// Return a persisted message's metadata.
        if let decodableMessageMetaData = UserDefaults.standard.data(forKey: generateKey(from: key)),
           let decodedData = try? decoder.decode(GleanPlumbMessageMetaData.self, from: decodableMessageMetaData) {
            return decodedData
        }

        return nil
    }

}
