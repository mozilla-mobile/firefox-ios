// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The Message Store is responible for tracking and updating certain metadata of a Message. This
/// will primarily help us determine if messages are expired, and perhaps what caused expiry.

protocol MessageStoreProtocol {
    
    /// Return associated metadata for preexisting or new messages.
    func getMessageMetadata(messageId: String) -> MessageMeta
    
    /// Track and persist impression counts of the message.
    func onMessageDisplayed(message: Message)
    
    /// Track and persist user interactions with the message.
    func onMessagePressed(message: Message)
    
    /// Do the bookkeeping for message dismissed Counts and expiry.
    func onMessageDismissed(message: Message)
    
}

protocol MessageStoreProvider { }

extension MessageStoreProvider {
    var messageStore: MessageStore {
        return MessageStore.shared
    }
}

class MessageStore: MessageStoreProtocol {
    
    // MARK: - Properties
    
    static let shared = MessageStore()
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - MessageStoreProtocol methods
    
    /// Returns the metadata that persists on system. If there's none, it returns default data.
    func getMessageMetadata(messageId: String) -> MessageMeta {
        
        /// Return preexisting Message Metadata.
        if let metadata = get(key: messageId) {
            return metadata
        }
        
        return MessageMeta(messageId: messageId,
                           messageImpressions: 0,
                           messageDismissed: 0,
                           isExpired: false)
    }
    
    /// Update message metadata and persist that information.
    func onMessageDisplayed(message: Message) {
        var messageToTrack = message.metadata
        let messageImpressions = message.metadata.messageImpressions
        let messageMaxCount = message.styleData.maxDisplayCount
        
        messageToTrack.messageImpressions += 1
        
        /// Determine if it's expired.
        if messageImpressions >= messageMaxCount || messageToTrack.isExpired {
            messageToTrack.isExpired = true
        }
        
        if let encoded = try? encoder.encode(messageToTrack) {
            set(key: message.messageId, encoded: encoded)
        }
    }
    
    /// For the MVP, we need to expire the message.
    func onMessagePressed(message: Message) {
        var messageToTrack = message.metadata
        
        messageToTrack.isExpired = true
        
        if let encoded = try? encoder.encode(messageToTrack) {
            set(key: message.messageId, encoded: encoded)
        }
    }
    
    /// Depending on the surface, we may do different things with dismissal. But for the MVP,
    /// dismissal expires the message.
    func onMessageDismissed(message: Message) {
        var messageToTrack = message.metadata
        
        messageToTrack.isExpired = true
        messageToTrack.messageDismissed += 1
        
        if let encoded = try? encoder.encode(messageToTrack) {
            set(key: message.messageId, encoded: encoded)
        }
    }
    
    // MARK: - Private helpers
    
    /// Generate a key that's "treated" to prevent collisions.
    private func generateKey(from key: String) -> String {
        return "GleanPlumb.Messages.\(key)"
    }
    
    /// Persist a message's metadata.
    private func set(key: String, encoded: Data) {
        UserDefaults.standard.set(encoded, forKey: generateKey(from: key))
    }
    
    /// Return persisted message metadata.
    private func get(key: String) -> MessageMeta? {
        
        /// Return a persisted message's metadata.
        if let decodableMessageMetaData = UserDefaults.standard.data(forKey: generateKey(from: key)),
           let decodedData = try? decoder.decode(MessageMeta.self, from: decodableMessageMetaData) {
            return decodedData
        }
        
        return nil
    }
    
}
