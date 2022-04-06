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
    /// Deprecate.
    func onStartup()
    
    /// Finds the next message to be displayed out of all showable messages.
    /// Surface calls.
    func getNextMessage(for surface: MessageSurfaceId) -> Message?
    
    /// Report impressions in Glean, and then pass the bookkeeping to increment the impression count and expire to `MessageStore`.
    /// Surface calls.
    func onMessageDisplayed(message: Message)
    
    /// Using the helper, this should get the message action string ready for use.
    /// Surface calls.
    func onMessagePressed(message: Message)
    
    /// Handles what to do with a message when a user has dismissed it.
    /// Surface calls.
    func onMessageDismissed(message: Message)
    
    /// If the message is malformed (missing key elements the surface expects), then
    /// report the malformed message.
    /// Manager calls.
    func onMalformedMessage(messageKey: String)
}

/// The `MessagingManager` is responsible for several things including:
/// - preparing Messages for a given UI surface
/// - reacting to user interactions on the `Message` to handle:
///     - impression counts
///     - user dismissal of a message
///     - expiration logic
/// - reporting telemetry for `Message`s
class MessagingManager: MessagingManagerProvider, MessagingHelperProtocol, MessageStoreProvider, Loggable {
    
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
    
    /// Perform any startup setup if necessary.
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
    
    /// Returns the next well-formed, non-expired, triggered message in descending priority order.
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
            
            onMalformedMessage(messageKey: key)
            
            return nil
        }.filter { message in
            !messagingHelper.isMessageExpired(message: message)
        }.filter { message in
            message.messageData.surface == surface
        }.sorted { message1, message2 in
            message1.styleData.priority > message2.styleData.priority
        }
        
        /// Populating showables for the surface gives us a way to access all messages at once.
        /// And showables will always be up to date when the surface calls for a message.
        showableMessagesForSurface[surface]?.append(contentsOf: messages)
        
        /// Take the first triggered message.
        guard let message = messages.first(where: { message in
            do {
                return try messagingHelper.isMessageEligible(message: message, messageHelper: helper)
            } catch {
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
    
    func onMessageDisplayed(message: Message) {
        
        /// TODO: Report message impression to Telemetry
        
        /// Forward bookkeeping responsibilities to the store.
        messageStore.onMessageDisplayed(message: message)
    }
    
    /// Handle when a user hits the CTA of the surface.
    func onMessagePressed(message: Message) {
        
        /// TODO: Report telemetry on press event
        
        switch message.messageData.surface {
        case .newTabCard:
            messageStore.onMessagePressed(message: message)
        default: break
        }
    }
    
    /// For now, we will assume all dismissed messages should become expired.
    func onMessageDismissed(message: Message) {
        
        /// TODO: Telemetry for dismissal of the message.
        
        /// If a message is dismissed, we expire it right away. Forward that to the store.
        messageStore.onMessageDismissed(message: message)
    }
    
    /// A malformed message should be reported.
    func onMalformedMessage(messageKey: String) {
        
        /// Telemetry event for malformed message.
        ///
        /// ASK: Should we save a malformed message key as expired..? I'd say no.
        
    }
    
}
