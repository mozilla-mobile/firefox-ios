// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import protocol MozillaAppServices.NimbusMessagingHelperProtocol

/// Normalizes onboarding configuration to unified internal representation.
///
/// Supports two configuration modes:
/// - Legacy mode: Flat card dictionary (existing behavior)
/// - Flow mode: Flow-based composition (new behavior)
///
/// Both modes normalize to the same card dictionary format, ensuring
/// downstream code (feature layer) remains unchanged.
final class OnboardingConfigurationNormalizer {
    private let helperUtility: NimbusMessagingHelperUtilityProtocol
    
    /// Mapping of normalized card keys to step order overrides.
    /// Used when cards come from flows to override card's default order.
    private(set) var stepOrderOverrides: [String: Int] = [:]
    
    init(helperUtility: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility()) {
        self.helperUtility = helperUtility
    }
    
    /// Normalizes configuration to unified card dictionary format.
    ///
    /// - Parameters:
    ///   - cards: Card definitions (legacy mode)
    ///   - flows: Flow definitions (flow mode)
    ///   - conditions: Condition lookup table for JEXL evaluation
    ///   - onboardingVariant: Current UI variant (from feature flags)
    ///   - onboardingType: Fresh install or upgrade
    /// - Returns: Normalized card dictionary (same format regardless of mode)
    func normalize(
        cards: [String: NimbusOnboardingCardData],
        flows: [String: NimbusOnboardingFlow],
        conditions: [String: String],
        onboardingVariant: OnboardingVariant,
        onboardingType: OnboardingType
    ) -> [String: NimbusOnboardingCardData] {
        // Clear step order overrides for new normalization
        stepOrderOverrides.removeAll()
        // Detect mode: if flows are non-empty, use flow mode; otherwise, legacy mode
        if !flows.isEmpty {
            return normalizeFromFlows(
                flows: flows,
                cards: cards,
                conditions: conditions,
                onboardingVariant: onboardingVariant,
                onboardingType: onboardingType
            )
        }
        
        // Legacy mode: pass cards through unchanged
        return cards
    }
    
    /// Expands flows to normalized card dictionary.
    ///
    /// - Finds applicable flows (matching uiVariant and onboardingType)
    /// - Evaluates flow-level prerequisites
    /// - Expands flow steps to cards
    /// - Evaluates step-level prerequisites
    /// - Returns normalized card dictionary
    private func normalizeFromFlows(
        flows: [String: NimbusOnboardingFlow],
        cards: [String: NimbusOnboardingCardData],
        conditions: [String: String],
        onboardingVariant: OnboardingVariant,
        onboardingType: OnboardingType
    ) -> [String: NimbusOnboardingCardData] {
        guard let helper = helperUtility.createNimbusMessagingHelper() else {
            // If helper creation fails, cannot evaluate prerequisites
            // Fall back to legacy mode (empty flows = legacy behavior)
            return cards
        }
        
        // Find applicable flows
        let applicableFlows = flows.values.filter { flow in
            // Match onboarding type
            guard flow.onboardingType == onboardingType else { return false }
            
            // Match UI variant (if specified)
            if let flowVariant = flow.uiVariant {
                guard flowVariant == onboardingVariant else { return false }
            }
            
            // Evaluate flow-level prerequisites
            return evaluatePrerequisites(
                flow.prerequisites,
                conditions: conditions,
                helper: helper
            )
        }
        
        // Expand flows to cards
        var normalizedCards: [String: NimbusOnboardingCardData] = [:]
        
        for flow in applicableFlows {
            for (stepIndex, step) in flow.steps.enumerated() {
                // Get referenced card
                guard let baseCard = cards[step.cardReference] else {
                    // Card not found - skip step (log in debug builds)
                    #if DEBUG
                    print("OnboardingConfigurationNormalizer: Card '\(step.cardReference)' not found, skipping step")
                    #endif
                    continue
                }
                
                // Evaluate step-level prerequisites
                if !evaluatePrerequisites(
                    step.prerequisites,
                    conditions: conditions,
                    helper: helper
                ) {
                    // Step prerequisites not met - skip step
                    continue
                }
                
                // Create normalized card with step overrides
                let normalizedCard = applyStepOverrides(
                    baseCard: baseCard,
                    step: step,
                    flowName: flow.flowName.isEmpty ? "flow" : flow.flowName,
                    stepIndex: stepIndex
                )
                
                // Use flow name + step index as key to avoid collisions
                // Format: "{flowName}-step-{index}"
                let cardKey = "\(flow.flowName.isEmpty ? "flow" : flow.flowName)-step-\(stepIndex)"
                normalizedCards[cardKey] = normalizedCard
                
                // Store step order override (step order takes precedence over card order)
                stepOrderOverrides[cardKey] = step.order
            }
        }
        
        return normalizedCards
    }
    
    /// Applies step-level overrides to base card.
    ///
    /// For Phase 1, we use the card's order. Step-level order overrides
    /// will be handled in the feature layer when creating card models.
    private func applyStepOverrides(
        baseCard: NimbusOnboardingCardData,
        step: NimbusOnboardingFlowStep,
        flowName: String,
        stepIndex: Int
    ) -> NimbusOnboardingCardData {
        // Phase 1: Use base card as-is
        // Step order override will be applied in feature layer when creating models
        // This keeps the normalization layer simple and focused on mode detection
        return baseCard
    }
    
    /// Evaluates prerequisites using JEXL.
    ///
    /// Reuses the same logic from NimbusOnboardingFeatureLayerProtocol.
    private func evaluatePrerequisites(
        _ prerequisites: [String],
        conditions: [String: String],
        helper: NimbusMessagingHelperProtocol
    ) -> Bool {
        // Empty prerequisites means always eligible
        guard !prerequisites.isEmpty else { return true }
        
        // Use the same evaluation logic as card prerequisites
        let conditionsList = prerequisites.compactMap { conditions[$0] }
        guard conditionsList.count == prerequisites.count else {
            // Some prerequisites not found in condition table
            return false
        }
        
        do {
            return try NimbusMessagingEvaluationUtility().doesObjectMeet(
                verificationRequirements: conditionsList,
                using: helper
            )
        } catch {
            // Evaluation error - consider not eligible
            return false
        }
    }
}
