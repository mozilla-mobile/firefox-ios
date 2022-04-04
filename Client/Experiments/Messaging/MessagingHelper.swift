// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import MozillaAppServices
import Shared

protocol MessagingHelperProtocol { }

extension MessagingHelperProtocol {
    var messagingHelper: MessagingHelper {
        return MessagingHelper.shared
    }
}

/// The Message Helper is responsible for preparing fetched messages to appear in a UI surface.
/// It should do all operations on a message and return only valid, eligible, non-expired messages FOR the associated surface.
class MessagingHelper: Loggable, UserDefaultsManageable {
    
    // MARK: - Properties
    
    static let shared = MessagingHelper()
    
    // MARK: - Public helpers
    
    /// Filter messages that are EXPIRED.
    func evalExpiry(messages: [String : MessageData]) -> [String : MessageData] {
        let nonExpiredMessages = messages.filter { message in
            
            /// If this is the first time we're dealing with this `Message`, then we have no expiration data.
            /// Therefore, it's not expired for now.
            guard let preExistingMessage: MessageMeta = userDefaultsManager.getPreference(message.key) else { return true }
            
            /// Not the first time we're seeing this `Message`, so we should have expiry data.
            return !preExistingMessage.isExpired
        }
        
        return nonExpiredMessages
    }
    
    /// A message can be well-formed, but can still be missing values the surface specifically needs. This will filter those and
    /// return a dictionary of messages that satisfy the needs of its associated UI surface.
    func evalMessageNilValues(messages: [String : MessageData]) -> [String : MessageData] {
        let nonNilMessages = messages.filter { message in
            let messageBeingEval = message.value
            
            switch messageBeingEval.surface {
            case .newTabCard:
                return evalNewTabCardNils(message: messageBeingEval)
                
            // This case should never hit in the MVP.
            case .unknown:
                return false
            }
        }
        
        return nonNilMessages
    }
    
    /// Filter messages that DON'T satisfy all triggers.
    func evalMessageTriggers(messages: [String: MessageData]) -> [String: MessageData] {
        let triggerMap: [String: Bool] = evalProvidedTriggers()
        var triggeredMessages: [String: MessageData] = [:]
        
        /// For each message, determine its triggers statuses.
        triggeredMessages = messages.filter { message in
            var allTriggersSatisfied = true
            
            message.value.trigger.forEach {
                let triggerResult = triggerMap[$0]
                
                if let existsInDict = triggerResult, !existsInDict {
                    allTriggersSatisfied = false
                }
                
            }
            
            return allTriggersSatisfied
        }
        
        return triggeredMessages
    }
    
    /// Actions tend to require substitutions. We need to replace these template strings with finalized values.
    func evalSubstitutions(messages: [String: MessageData]) {
        // Placeholder until I figure out how to work with that part of GleanPlumbMessageHelper
    }
    
    /// Filter styles that DON'T contain all necessary fields. Currently, we pass defaults but it may not always be the case
    /// when supporting a wider set of custom styles.
    func evalStyleNilValues() -> [String : StyleData] {
        var styles = FxNimbus.shared.features.messaging.value().styles
        
        styles = styles.filter { style in
            [style.value.priority, style.value.maxDisplayCount].allNotNil()
        }
        
        return styles
    }
    
    // MARK: - Private surface helpers
    
    /// The NewTabCard (DefaultBrowserCard) expects certain things from a message. We need
    /// to check that all these are NOT nil. The also ends up checking if a message is malformed.
    /// - title
    /// - text
    /// - button-label
    /// - action
    /// - trigger
    /// - style
    private func evalNewTabCardNils(message: MessageData) -> Bool {
        let anyPropertiesNil = [message.title,
                                message.text,
                                message.buttonLabel,
                                message.action,
                                message.style].allNotNil() && !message.trigger.isEmpty
        
        return anyPropertiesNil
    }
    
    // MARK: - Private message helpers
    
    /// We expect messages to utilize triggers we're aware of from the FML. So, we can evaluate them
    /// and pass it to where it's needed.
    /// - Returns: Returns all triggers that evaluate to TRUE.
    private func evalProvidedTriggers() -> [String : Bool] {
        let gleanPlumbHelper: GleanPlumbMessageHelper
        var admissableTriggers: [String: Bool] = [:]
        
        do {
            // JEXLS are evaluated against app context
            // app can provide details about itself  to JEXL --> like isDefaultBrowser
            // Look up how to do these in iOS and pass it in!!
            gleanPlumbHelper = try Experiments.shared.createMessageHelper(additionalContext: ["is_default_browser" : false, "date_string": "YYYY-MM-DD"])
        } catch {
            Logger.browserLogger.error("GleanPlumbMessageHelper could not be created!")
            return [:]
        }
        
        let providedTriggers = FxNimbus.shared.features.messaging.value().triggers
        
        providedTriggers.forEach { trigger in
            let isAdmissable = evaluateTrigger(trigger: trigger, with: gleanPlumbHelper)
            isAdmissable ? admissableTriggers[trigger.key] = isAdmissable : nil
        }
        
        return admissableTriggers
    }
    
    /// Helper that evaluates a single trigger, and returns the Bool.
    private func evaluateTrigger(trigger: Dictionary<String, String>.Element,
                                 with helper: GleanPlumbMessageHelper) -> Bool {
        var triggerValue = false
        
        do {
            triggerValue = try helper.evalJexl(expression: trigger.value)
        } catch {
            Logger.browserLogger.error("JEXL could not be evaluated! Be sure this JEXL exists in your FML!")
        }
        
        return triggerValue
    }
    
    /// We expect to encounter `Style`s that are already within the FML for the MVP. So, we evaluate them and
    /// pass to where they're needed.
    private func evalProvidedStyles() {
        let styles = FxNimbus.shared.features.messaging.value().styles
        
        
    }
    
}
