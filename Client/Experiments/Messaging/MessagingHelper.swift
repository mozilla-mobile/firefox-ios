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
    
    let userDefaults = UserDefaults.standard
    
    /// Styles inform us of a message's priority and maximum display count. The ordering goes from
    /// `DEFAULT` being the lowest to `URGENT` being the highest for priority. However, they CAN
    /// be overriden to mean different things!
    var styles: [String: Style] = [:]
    
    init() {
        prepareStylesForSurfaces()
    }
    
    // MARK: - Public helpers
    
    /// Filter messages that are EXPIRED.
    func evalExpiry(messages: [String : MessageData]) -> [String : MessageData] {
        let decoder = JSONDecoder()
        
        let nonExpiredMessages = messages.filter { message in
            
            /// Determine if we've encountered this message before.
            /// If we have, determine its status.
            if let decodableMessageMetadata = UserDefaults.standard.data(forKey: message.key),
                var decodedData = try? decoder.decode(MessageMeta.self, from: decodableMessageMetadata) {
                
                let hasExceededImpressionLimit = decodedData.messageImpressions >= styles[message.value.style]?.maxDisplayCount ?? 5
                
                /// Expire it, and remember it!
                if hasExceededImpressionLimit {
                    let encoder = JSONEncoder()
                    
                    decodedData.isExpired = true
                    
                    if let encoded = try? encoder.encode(decodedData) {
                        UserDefaults.standard.set(encoded, forKey: message.key)
                    }
                }
                
                return !decodedData.isExpired && !hasExceededImpressionLimit
            }
            
            /// If we're here, that means we haven't seen this message before and therefore, not expired.
            return true
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-mm-dd"
        let todaysDate = dateFormatter.string(from: Date())
        
        do {
            /// JEXLS are evaluated more accurately when given app context (details about the app on device).
            gleanPlumbHelper = try Experiments.shared.createMessageHelper(additionalContext: ["is_default_browser" : false,
                                                                                              "date_string": todaysDate])
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
    
    // MARK: - Misc. helpers
    
    /// This takes a set of styles and creates a dictionary from them, for easier access to its properties.
    func prepareStylesForSurfaces() {
        let nonNilStyles = evalStyleNilValues()
        
        nonNilStyles.forEach { style in
            styles[style.key] = Style(priority: style.value.priority, maxDisplayCount: style.value.maxDisplayCount)
        }
    }
    
}
