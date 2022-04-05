// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The Message Store is responible for tracking and updating certain metadata of a Message. This
/// will primarily help us determine if messages are expired, and perhaps what caused expiry.

protocol MessageStoreProtocol {
    /// The message store is responsible for knowing if it's an old or new message, and
    /// return associated metadata.
    func getMessageMetadata(messageId: String) -> MessageMeta
    
    /// Do the bookkeeping to track and persist impression counts.
    func onMessageDisplayed(message: Message)
    
    ///
    func hasMessageExpired(message: Message)
    
    /// Do the bookkeeping for message dismissed Counts and expiry.
    func onMessageDismissed(message: Message)
    
    func saveMetaData()
}

class MessageStore: MessageStoreProtocol {
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    func getMessageMetadata(messageId: String) -> MessageMeta {
        /// Handles returning preexisting message meta.
        let decoder = JSONDecoder()
    
        if let decodableMessageMetadata = UserDefaults.standard.data(forKey: messageId),
           let decodedData = try? decoder.decode(MessageMeta.self, from: decodableMessageMetadata) {
            return decodedData
        }
            
        return MessageMeta(messageId: messageId,
                           messageImpressions: 0,
                           messageDismissed: 0,
                           isExpired: false)
    }
    
    func onMessageDisplayed(message: Message) {
//        saveMetadata(message.messageId, message.metadata.copy(metadata.impressions + 1))
        
        var messageToTrack = message.metadata
        messageToTrack.messageImpressions += 1
        
        if let encoded = try? encoder.encode(messageToTrack) {
            UserDefaults.standard.set(encoded, forKey: message.messageId)
            
        }
        
    }
    
    func hasMessageExpired(message: Message) {
        // placeholder
    }
    
    func onMessageDismissed(message: Message) {
        // placehodler
    }
    
    func saveMetaData() {
        // placeholder
    }
    
//    private func set(key: String, encoded: MessageMetadata) {
//        UserDefaults.standard.set(encoded, for: treatKey(key))
//    }
//
//    private treatKey(_ key: String) -> String {
//        return "gleanplumb.messages.\(key)"
//    }
//
//    private func get(key: String) -> MessageMetadata {
//        return UserDefaults.standard.get(for: treatKey(key))
//    }
    
    
}
