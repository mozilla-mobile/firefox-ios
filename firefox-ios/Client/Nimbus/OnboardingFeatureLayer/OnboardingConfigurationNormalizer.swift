// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import protocol MozillaAppServices.NimbusMessagingHelperProtocol

/// Resolves the active onboarding flow and validates prerequisites.
final class OnboardingConfigurationNormalizer {
    private let helperUtility: NimbusMessagingHelperUtilityProtocol

    init(helperUtility: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility()) {
        self.helperUtility = helperUtility
    }

    /// Resolves the active flow, validating onboarding type and prerequisites.
    ///
    /// - Parameters:
    ///   - activeFlowKey: The flow key selected by configuration.
    ///   - flows: Flow definitions (flow-owned cards).
    ///   - conditions: Condition lookup table for JEXL evaluation.
    ///   - onboardingType: Fresh install or upgrade.
    /// - Returns: The active flow if valid; otherwise nil.
    func resolveActiveFlow(
        activeFlowKey: String?,
        flows: [String: NimbusOnboardingFlow],
        conditions: [String: String],
        onboardingType: OnboardingType
    ) -> NimbusOnboardingFlow? {
        guard let activeFlowKey,
              let flow = flows[activeFlowKey],
              flow.onboardingType == onboardingType
        else {
            return nil
        }

        guard let helper = helperUtility.createNimbusMessagingHelper() else {
            return nil
        }

        let isEligible = evaluatePrerequisites(
            flow.prerequisites,
            conditions: conditions,
            helper: helper
        )

        return isEligible ? flow : nil
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
