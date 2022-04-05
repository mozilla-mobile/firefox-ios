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

protocol MessagingManagerProvider {
    
    /// Does the bookkeeping and preparation of messages for their respective surfaces.
    func onStartup()
    
    /// Finds the next message to be displayed out of all showable messages.
    func getNextMessage(for surface: MessageSurfaceId) -> Message?
    
    /// Using the helper, this should get the message action string ready for use.
    func onMessagePressed(message: Message)
    
    /// Handles what to do with a message when a user has dismissed it.
    func onMessageDismissed(message: Message)
    
    /// If the message is malformed (missing key elements the surface expects), then
    /// report the malformed message.
    func onMalformedMessage(message: Message)
}

/// The `MessagingManager` is responsible for several things including:
/// - preparing Messages for a given UI surface
/// - reacting to user interactions on the `Message` to handle:
///     - impression counts
///     - user dismissal of a message
///     - expiration logic
/// - reporting telemetry for `Message`s
class MessagingManager: MessagingManagerProvider, MessagingHelperProtocol, UserDefaultsManageable {
    
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
        onStartup()
    }
    
    // MARK: - Messaging Protocol Conformance
    
    func onStartup() {
        prepareStylesForSurfaces()
        
        prepareMessagesForSurfaces()
    }
    
    /// The assumption is that the array will be ordered from highest to lowest priority messages.
    /// That's why we'll always work with the first item from it.
    func getNextMessage(for surface: MessageSurfaceId) -> Message? {
        
        /// If we have an empty array, that means all showable messages for that surface are expired by this point.
        /// The injection site should handle the `nil` case by resorting to its default behavior and message.
        guard var upcomingMessage = showableMessagesForSurface[surface]?.first else { return nil }
        
        let currentImpressionCount = upcomingMessage.metadata.messageImpressions
        let currentMessageMaxCount = upcomingMessage.styleData.maxDisplayCount
        let encoder = JSONEncoder()
        
        if currentImpressionCount < currentMessageMaxCount {
            
            /// We have a non-expired message. Do the necessary bookkeeping and return it.
            upcomingMessage.metadata.messageImpressions += 1
            
            if let encoded = try? encoder.encode(upcomingMessage.metadata) {
                UserDefaults.standard.set(encoded, forKey: upcomingMessage.messageId)
            }
            
            return upcomingMessage
        } else {
            /// Technically, we should never deal with this case. Our `onStartup` prepares the list of showable messages
            /// cleanly, assuming we both store message Metadata properly here and retrieve metadata in the helper's `evalExpiry`
            
            /// We're dealing with an expired message. Do the bookkeeping, remove it from showables, and return the
            /// Message that follows.
            upcomingMessage.metadata.isExpired = true
            
            if let encoded = try? encoder.encode(upcomingMessage.metadata) {
                UserDefaults.standard.set(encoded, forKey: upcomingMessage.messageId)
            }
            
            /// Filter expired messages from our collection of showable messages
            let nonExpiredMessagesForSurface = showableMessagesForSurface[surface]?.filter { !$0.metadata.isExpired } ?? []
            
            showableMessagesForSurface[surface]?.append(contentsOf: nonExpiredMessagesForSurface)
        }
        
        return nil
    }
    
    /// Handle when a user hits the CTA of the surface.
    func onMessagePressed(message: Message) {
        /// TODO: Track in telemetry
        /// handle substitutions
        
        var messageToOperateOn = message
        let surface = messageToOperateOn.messageData.surface
        let encoder = JSONEncoder()
        
        switch message.messageData.surface {
        case .newTabCard:
            messageToOperateOn.metadata.isExpired = true
            
            if let encoded = try? encoder.encode(messageToOperateOn.metadata) {
                UserDefaults.standard.set(encoded, forKey: messageToOperateOn.messageId)
            }
            
            /// Remove this message from showables.
            showableMessagesForSurface[surface] = showableMessagesForSurface[surface]?.filter {
                $0.messageId != messageToOperateOn.messageId
            }
            
        default: break
        }
    }
    
    /// For now, we will assume all dismissed messages should become expired.
    func onMessageDismissed(message: Message) {
        var messageToOperateOn = message
        let surface = message.messageData.surface
        let encoder = JSONEncoder()
   
        /// TODO: Track the dismissal in telemetry

        /// Expire the message and save.
        messageToOperateOn.metadata.messageDismissed += 1
        messageToOperateOn.metadata.isExpired = true
        
        if let encoded = try? encoder.encode(messageToOperateOn.metadata) {
            UserDefaults.standard.set(encoded, forKey: messageToOperateOn.messageId)
        }
        
        /// Remove this message from showables.
        showableMessagesForSurface[surface] = showableMessagesForSurface[surface]?.filter {
            $0.messageId != messageToOperateOn.messageId
        }
    }
    
    func onMalformedMessage(message: Message) {
        // telemetry
        // expiry of message
    }
    
    // MARK: - Misc helpers
    
    /// This takes a set of styles and creates a dictionary from them, for easier access to its properties.
    func prepareStylesForSurfaces() {
        let nonNilStyles = messagingHelper.evalStyleNilValues()
        
        nonNilStyles.forEach { style in
            styles[style.key] = Style(priority: style.value.priority, maxDisplayCount: style.value.maxDisplayCount)
        }
    }
    
    /// This takes all fetched messages, works on them step by step, to give us a collection of
    /// non-expired, valid, triggered and sorted messages for its associated UI surface.
    func prepareMessagesForSurfaces() {
        let initialMessageSet = FxNimbus.shared.features.messaging.value().messages
        
        let nonExpiredMessages = messagingHelper.evalExpiry(messages: initialMessageSet)
        
        let nonExpiredAndNonNilMessages = messagingHelper.evalMessageNilValues(messages: nonExpiredMessages)
        
        let nonExpiredNonNilAndTriggeredMessages = messagingHelper.evalMessageTriggers(messages: nonExpiredAndNonNilMessages)
        
        /// Populate showables sorted by priority.
        populateShowableMessagesWith(messages: nonExpiredNonNilAndTriggeredMessages)
    }
    
    /// This populates showable messages.
    private func populateShowableMessagesWith(messages: [String : MessageData]) {
        let decoder = JSONDecoder()
        
        /// Populate our showables first, and sort afterwards.
        messages.forEach { message in
            var preparedMessage: Message
            
            let surfaceId = message.value.surface
            
            let newMessageMeta = MessageMeta(messageId: message.key,
                                             messageImpressions: 0,
                                             messageDismissed: 0,
                                             isExpired: false)
            
            /// If we have a preexisting message, fill in our showable message with its associated metadata.
            if let decodableMessageMetadata = UserDefaults.standard.data(forKey: message.key),
                let decodedData = try? decoder.decode(MessageMeta.self, from: decodableMessageMetadata) {
                preparedMessage = Message(messageId: message.key,
                                          messageData: message.value,
                                          action: message.value.action,
                                          styleData: styles[message.value.style] ?? Style(priority: 50, maxDisplayCount: 5),
                                          metadata: decodedData)
            } else {
                /// We have a brand new message. Fill in the defaults.
                preparedMessage = Message(messageId: message.key,
                                          messageData: message.value,
                                          action: message.value.action,
                                          styleData: styles[message.value.style] ?? Style(priority: 50, maxDisplayCount: 5),
                                          metadata: newMessageMeta)
            }
            
            if showableMessagesForSurface.keys.contains(surfaceId) {
                showableMessagesForSurface[surfaceId]?.append(preparedMessage)
            } else {
                showableMessagesForSurface[surfaceId] = []
                showableMessagesForSurface[surfaceId]?.append(preparedMessage)
            }
            
        }
        
        /// Sort these messages according to their priority.
        showableMessagesForSurface.keys.forEach { key in
            let sortedMessages = showableMessagesForSurface[key]?.sorted(by: { message1, message2 in
                message1.styleData.priority > message2.styleData.priority
            }) ?? []
            
            showableMessagesForSurface[key]?.removeAll()
            showableMessagesForSurface[key]?.append(contentsOf: sortedMessages)
        }
        
        /// Persist these messages' metadata for future tracking.
        let encoder = JSONEncoder()
        
        showableMessagesForSurface.keys.forEach { key in
            showableMessagesForSurface[key]?.forEach { message in
                if let encoded = try? encoder.encode(message.metadata) {
                    UserDefaults.standard.set(encoded, forKey: message.messageId)
                }
            }
        }
        
        print("sup")
    }
    
}
