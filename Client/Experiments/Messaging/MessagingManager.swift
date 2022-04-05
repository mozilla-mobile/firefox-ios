// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

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
    
    /// Track the impression display in Glean, and do the pass the bookeeping to increment the impression count and expire to `MessageStore`.
    func onMessageDisplayed(message: Message)
    
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
class MessagingManager: MessagingManagerProvider, MessagingHelperProtocol, Loggable {
    
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
    
    // MARK: - Inits
    
    init() {
        onStartup()
    }
    
    // MARK: - Messaging Protocol Conformance
    
    func onStartup() {
        // placeholder
    }
    
    /// We assemble one message at a time. If there's any issue with it, return `nil`.
    /// Reporting a malformed message is done at the call site when reacting to a `nil`.
    func createMessage(messageId: String, message: MessageData, lookupTables: Messaging, messageStore: MessageStoreProtocol) -> Message? {
        
        /// Ascertain a Message's style, to know priority and max impressions.
        guard let style = lookupTables.styles[message.style] else { return nil }
        
        /// The message action should be either from the lookup table OR a URL.
        let action = lookupTables.actions[message.action] ?? message.action
        guard action.contains("://") else { return nil }
        
        let triggers = message.trigger.compactMap { trigger in
            lookupTables.triggers[trigger]
        }
        
        /// Ensure the message contains everything the surface needs. Otherwise, it's malformed.
        var surfaceMissingProperties: Bool
        switch message.surface {
        case .newTabCard:
            surfaceMissingProperties = messagingHelper.evalNewTabCardNils(message: message)
        case .unknown:
            /// This case should never hit in the MVP. We've defaulted surfaceIDs to `NewTabCard`
            return nil
        }
        
        if surfaceMissingProperties {
            return nil
        }
        
        /// Be sure the count on `triggers` and `message.triggers` are equal.
        /// If these mismatch, that means a message contains a trigger not in the triggers lookup table.
        /// JEXLS can only be evaluated on supported triggers. Otherwise, consider the message malformed.
        if triggers.count != message.trigger.count {
            return nil
        }
        
        return Message(messageId: messageId,
                       messageData: message,
                       action: action,
                       triggers: triggers,
                       styleData: style,
                       metadata: messageStore.getMessageMetadata(messageId: messageId))
    }
    
    /// Returns the next well-formed, non-expired, triggered message in priority order.
    func getNextMessage(for surface: MessageSurfaceId) -> Message? {
        let feature = FxNimbus.shared.features.messaging.value()
        let messageStore = MessageStore()
        let helper: GleanPlumbMessageHelper
        
        /// Create our GleanPlumbMessageHelper, to evaluate triggers later.
        do {
            helper = try Experiments.shared.createMessageHelper(additionalContext: messagingHelper.createAdditionalContext())
        } catch {
            /// If we're here, then all of Messaging is in limbo! Report the error and let the surface handle this `nil`
            Logger.browserLogger.error("GleanPlumbMessageHelper could not be created! With error \(error)")
            return nil
        }
        
        /// All these are non-expired, well formed messages for a requested surface.
        let messages = feature.messages.compactMap { key, messageData -> Message? in
            if let message = self.createMessage(messageId: key,
                                                message: messageData,
                                                lookupTables: feature,
                                                messageStore: messageStore) {
                return message
            }
            
            /// TODO: report message malformed to glean
            
            return nil
        }.filter { message in
            !messagingHelper.isMessageExpired(message: message)
        }.filter { message in
            message.messageData.surface == surface
        }.sorted { message1, message2 in
            message1.styleData.priority > message2.styleData.priority
        }
        
        /// Take the first triggered message.
        guard let message = messages.first(where: { message in
            do {
                return try messagingHelper.isMessageEligible(message: message, messageHelper: helper)
            } catch {
                /// TODO: report this as a malformed message.
                return false
            }
        }) else {
            return nil
        }
        
        /// If it's a message under experiment, we need to react to whether it's a control or not.
        if messagingHelper.isMessageUnderExperiment(experimentKey: feature.messageUnderExperiment, message: message) {
            /// TODO: Report via telemetry
            FxNimbus.shared.features.messaging.recordExposure()
            let onControlActions = FxNimbus.shared.features.messaging.value().onControl
            
            if message.messageData.isControl {
                switch onControlActions {
                case .showNone:
                    return nil
                case .showNextMessage:
                    return messages.first { message in
                        do {
                            return try messagingHelper.isMessageEligible(message: message, messageHelper: helper)
                            && !message.messageData.isControl
                        } catch {
                            /// TODO: report this as a malformed message.
                            return false
                        }
                    }
                }
            }
        }
        
        return message
    }
    
    /// We report to Glean, and do give the rest to the MessageStore
    func onMessageDisplayed(message: Message) {
        /// TODO: Report an impression event for Glean
        
        
    }
    
    /// The assumption is that the array will be ordered from highest to lowest priority messages.
    /// That's why we'll always work with the first item from it.
//    func LegacygetNextMessage(for surface: MessageSurfaceId) -> Message? {
//
//        /// If we have an empty array, that means all showable messages for that surface are expired by this point.
//        /// The injection site should handle the `nil` case by resorting to its default behavior and message.
//        guard var upcomingMessage = showableMessagesForSurface[surface]?.first else { return nil }
//
//        let currentImpressionCount = upcomingMessage.metadata.messageImpressions
//        let currentMessageMaxCount = upcomingMessage.styleData.maxDisplayCount
//        let encoder = JSONEncoder()
//
//        if currentImpressionCount < currentMessageMaxCount {
//
//            if let messageIndex = showableMessagesForSurface[surface]?.firstIndex(where: { $0.messageId == upcomingMessage.messageId }) {
//                showableMessagesForSurface[surface]?.remove(at: messageIndex)
//            }
//
//            /// We have a non-expired message. Do the necessary bookkeeping and return it.
//            upcomingMessage.metadata.messageImpressions += 1
//
//            if let encoded = try? encoder.encode(upcomingMessage.metadata) {
//                UserDefaults.standard.set(encoded, forKey: upcomingMessage.messageId)
//            }
//
//            return upcomingMessage
//        } else {
//            /// onStartup doesn't handle messages from showables. We need to do that here.
//
//            /// We're dealing with an expired message. Do the bookkeeping, remove it from showables, and return the
//            /// Message that follows.
//            upcomingMessage.metadata.isExpired = true
//
//            if let encoded = try? encoder.encode(upcomingMessage.metadata) {
//                UserDefaults.standard.set(encoded, forKey: upcomingMessage.messageId)
//            }
//
//            /// Filter expired messages from our collection of showable messages
//            let nonExpiredMessagesForSurface = showableMessagesForSurface[surface]?.filter { !$0.metadata.isExpired } ?? []
//
//            showableMessagesForSurface[surface]?.append(contentsOf: nonExpiredMessagesForSurface)
//        }
//
//        return nil
//    }
    
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
    
    /// This takes all fetched messages, works on them step by step, to give us a collection of
    /// non-expired, valid, triggered and sorted messages for its associated UI surface.
//    func prepareMessagesForSurfaces() {
//        let initialMessageSet = FxNimbus.shared.features.messaging.value().messages
//
//        let nonExpiredMessages = messagingHelper.evalExpiry(messages: initialMessageSet)
//
//        let nonExpiredAndNonNilMessages = messagingHelper.evalMessageNilValues(messages: nonExpiredMessages)
//
//        let nonExpiredNonNilAndTriggeredMessages = messagingHelper.evalMessageTriggers(messages: nonExpiredAndNonNilMessages)
//
//        /// Populate showables sorted by priority.
////        populateShowableMessagesWith(messages: nonExpiredNonNilAndTriggeredMessages)
//    }
    
    /// This populates showable messages.
//    private func populateShowableMessagesWith(messages: [String : MessageData]) {
//        let decoder = JSONDecoder()
//
//        /// Populate our showables first, and sort afterwards.
//        messages.forEach { message in
//            var preparedMessage: Message
//
//            let surfaceId = message.value.surface
//
//            let newMessageMeta = MessageMeta(messageId: message.key,
//                                             messageImpressions: 0,
//                                             messageDismissed: 0,
//                                             isExpired: false)
//
//            /// If we have a preexisting message, fill in our showable message with its associated metadata.
//            if let decodableMessageMetadata = UserDefaults.standard.data(forKey: message.key),
//                let decodedData = try? decoder.decode(MessageMeta.self, from: decodableMessageMetadata) {
//                preparedMessage = Message(messageId: message.key,
//                                          messageData: message.value,
//                                          action: message.value.action,
//                                          triggers: <#[String]#>,
//                                          styleData: styles[message.value.style] ?? Style(priority: 50, maxDisplayCount: 5),
//                                          metadata: decodedData)
//            } else {
//                /// We have a brand new message. Fill in the defaults.
//                preparedMessage = Message(messageId: message.key,
//                                          messageData: message.value,,
//                                          triggers: <#[String]#>
//                                          action: message.value.action,
//                                          styleData: styles[message.value.style] ?? Style(priority: 50, maxDisplayCount: 5),
//                                          metadata: newMessageMeta)
//            }
//
//            if showableMessagesForSurface.keys.contains(surfaceId) {
//                showableMessagesForSurface[surfaceId]?.append(preparedMessage)
//            } else {
//                showableMessagesForSurface[surfaceId] = []
//                showableMessagesForSurface[surfaceId]?.append(preparedMessage)
//            }
//
//        }
//
//        /// Sort these messages according to their priority.
//        showableMessagesForSurface.keys.forEach { key in
//            let sortedMessages = showableMessagesForSurface[key]?.sorted(by: { message1, message2 in
//                message1.styleData.priority > message2.styleData.priority
//            }) ?? []
//
//            showableMessagesForSurface[key]?.removeAll()
//            showableMessagesForSurface[key]?.append(contentsOf: sortedMessages)
//        }
//
//        /// Persist these messages' metadata for future tracking.
//        let encoder = JSONEncoder()
//
//        showableMessagesForSurface.keys.forEach { key in
//            showableMessagesForSurface[key]?.forEach { message in
//                if let encoded = try? encoder.encode(message.metadata) {
//                    UserDefaults.standard.set(encoded, forKey: message.messageId)
//                }
//            }
//        }
//
//        print("sup")
//    }
    
}
