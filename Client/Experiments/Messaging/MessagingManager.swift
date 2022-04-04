// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import Foundation
import Combine

import MozillaAppServices

/// `Messaging` is synonymous with `GleanPlumb`.

protocol MessagingManagable { }

extension MessagingManagable {
    var messagingManager: MessagingManager {
        return MessagingManager.shared
    }
}

/// The `MessagingManager` is responsible for several things including:
/// - preparing Messages for a given UI surface
/// - reacting to user interactions on the `Message` to handle:
///     - impression counts
///     - user dismissal of a message
///     - expiration logic
/// - reporting telemetry for `Message`s
class MessagingManager: MessagingHelperProtocol, UserDefaultsManageable {
    
    // MARK: - Properties
    
    static let shared = MessagingManager()
    
    /// We map a message surface to a collection of valid and eligible messages for it. We expect this mapping to
    /// have these characteristics:
    /// - it correctly matches a surface to a message
    /// - the message is not expired
    /// - the message contains everything the surface needs, and is well-formed
    /// - the message satisfies all triggers
    ///
    /// This collection will remain updated by reacting to:
    /// - user actions that expire a message
    /// - reaching the expiry impression limit
    var showableMessagesForSurface: [MessageSurfaceId: [Message]] = [:]
    
    /// Styles inform us of a message's priority and maximum display count. The ordering goes from
    /// `DEFAULT` being the lowest to `URGENT` being the highest for priority. However, they CAN
    /// be overriden to mean different things!
    var styles: [String: Style] = [:]
    
    // MARK: - Inits
    
    init() {
        prepareStylesForSurfaces()
        
        prepareMessagesForSurfaces()
    }
    
    // MARK: - Misc helpers
    
    /// This takes all fetched messages, works on them step by step, to give us a collection of non-expired, valid and triggered messages for its associated UI surface.
    func prepareMessagesForSurfaces() {
        let initialMessageSet = FxNimbus.shared.features.messaging.value().messages
        
        let nonExpiredMessages = messagingHelper.evalExpiry(messages: initialMessageSet)
        
        let nonExpiredAndNonNilMessages = messagingHelper.evalMessageNilValues(messages: nonExpiredMessages)
        
        let nonExpiredNonNilAndTriggeredMessages = messagingHelper.evalMessageTriggers(messages: nonExpiredAndNonNilMessages)
        
        /// Substitutions pending!!!
        ///
        
        
        /// Populate showables, and sort later
        populateShowableMessagesWith(messages: nonExpiredNonNilAndTriggeredMessages)
    }
    
    /// The assumption is that the array will be ordered from highest to lowest priority messages.
    /// That's why we'll always work with the first item from it.
    ///
    /// NOTE THIS IS CRASHING on saving to userDefaults. FIX SOON.
    func getNextMessage(for surface: MessageSurfaceId) -> Message? {
        
        /// If we have an empty array, that means all showable messages for that surface are expired by this point.
        /// The injection site should handle the `nil` case by resorting to its default behavior and message.
        guard var upcomingMessage = showableMessagesForSurface[surface]?.first else { return nil }
        
        let currentImpressionCount = upcomingMessage.metadata.messageImpressions
        let currentMessageMaxCount = upcomingMessage.styleData.maxDisplayCount
        
        if currentImpressionCount < currentMessageMaxCount {
            /// We have a non-expired message. Do the necessary bookkeeping and return it.
            
            upcomingMessage.metadata.messageImpressions += 1
            
            /// Custom objects need to be saved as a `Data` instance.
            let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: upcomingMessage.metadata, requiringSecureCoding: false)
//            userDefaultsManager.setPreference(encodedData, key: upcomingMessage.messageId)
            
            return upcomingMessage
        } else {
            /// We're dealing with an expired message. Do the bookkeeping, remove it from showables, and return the
            /// Message that follows.
            
            upcomingMessage.metadata.isExpired = true
            
            /// Custom objects need to be saved as a `Data` instance.
            let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: upcomingMessage.metadata, requiringSecureCoding: false)
//            userDefaultsManager.setPreference(encodedData, key: upcomingMessage.messageId)
            
            /// Filter expired messages from our collection of showable messages
            let nonExpiredMessagesForSurface = showableMessagesForSurface[surface]?.filter {
                !$0.metadata.isExpired
            } ?? []
            
            showableMessagesForSurface[surface]?.append(contentsOf: nonExpiredMessagesForSurface)
        }
        
        return nil
    }
    
    /// This takes a set of styles and creates a dictionary from them, for easier access to its properties.
    func prepareStylesForSurfaces() {
        let nonNilStyles = messagingHelper.evalStyleNilValues()
        
        nonNilStyles.forEach { style in
            styles[style.key] = Style(priority: style.value.priority, maxDisplayCount: style.value.maxDisplayCount)
        }
    }
    
    /// This populates showable messages without sorting by priority.
    func populateShowableMessagesWith(messages: [String : MessageData]) {
        
        /// Populate our showables first, and sort afterwards.
        messages.forEach { message in
            var preparedMessage: Message
            
            let surfaceId = message.value.surface
            
            
            let newMessageMeta = MessageMeta(messageId: message.key,
                                             messageImpressions: 0,
                                             messageDismissed: 0,
                                             isExpired: false)
            
            /// We have a preexisting message. So, fill in our showable message with its associated metadata.
            if let preExistingMessageMeta: MessageMeta = userDefaultsManager.getPreference(message.key) {
                preparedMessage = Message(messageId: message.key,
                                      messageData: message.value,
                                      action: message.value.action,
                                      styleData: styles[message.key] ?? Style(priority: 50, maxDisplayCount: 5),
                                      metadata: preExistingMessageMeta)
            } else {
                /// We have a brand new message. Fill in the defaults as one.
                preparedMessage = Message(messageId: message.key,
                                      messageData: message.value,
                                      action: message.value.action,
                                      styleData: styles[message.key] ?? Style(priority: 50, maxDisplayCount: 5),
                                      metadata: newMessageMeta)
            }
            
            if showableMessagesForSurface.keys.contains(surfaceId) {
                showableMessagesForSurface[surfaceId]?.append(preparedMessage)
            } else {
                showableMessagesForSurface[surfaceId] = []
                showableMessagesForSurface[surfaceId]?.append(preparedMessage)
            }
            
        }
        
        // Now, I think I can access the inner elements and sort on priority.
        
        print("sup")
    }
    
}
