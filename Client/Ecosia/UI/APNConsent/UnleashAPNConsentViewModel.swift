// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Core

// MARK: - UnleashAPNConsentViewModel

/// Final class implementing the APNConsentViewModelProtocol for a specific variant.
final class UnleashAPNConsentViewModel: APNConsentViewModelProtocol {
    
    // MARK: Properties
    
    /// Title for the APN consent view, currently based on the Unleash variant.
    var title: String {
        switch EngagementServiceExperiment.variantName {
        case "test1": return .localized(.apnConsentVariantNameTest1HeaderTitle)
        default: return .localized(.apnConsentVariantNameControlHeaderTitle)
        }
    }
    
    /// Image for the APN consent view, currently based on the Unleash variant.
    var image: UIImage? {
        switch EngagementServiceExperiment.variantName {
        case "test1": return .init(named: "apnConsentImageTest1")
        default: return .init(named: "apnConsentImageControl")
        }
    }
    
    /// List items for the APN consent view, currently based on the Unleash variant.
    var listItems: [APNConsentListItem] {
        switch EngagementServiceExperiment.variantName {
        case "test1": return listItemsVariantNameTest1
        default: return listItemsVariantNameControl
        }
    }
    
    /// CTA (Call to Action) allow button title.
    var ctaAllowButtonTitle: String {
        .localized(.apnConsentCTAAllowButtonTitle)
    }
    
    /// Skip button title.
    var skipButtonTitle: String {
        .localized(.apnConsentSkipButtonTitle)
    }
}

extension UnleashAPNConsentViewModel {
    
    // MARK: List Items for Different Variants
    
    /// List items for the `control` variant.
    private var listItemsVariantNameControl: [APNConsentListItem] {
        [
            APNConsentListItem(title: .localized(.apnConsentVariantNameControlFirstItemTitle)),
            APNConsentListItem(title: .localized(.apnConsentVariantNameControlSecondItemTitle))
        ]
    }
    
    /// List items for the `test1` variant.
    private var listItemsVariantNameTest1: [APNConsentListItem] {
        [
            APNConsentListItem(title: .localized(.apnConsentVariantNameTest1FirstItemTitle)),
            APNConsentListItem(title: .localized(.apnConsentVariantNameTest1SecondItemTitle))
        ]
    }
}
