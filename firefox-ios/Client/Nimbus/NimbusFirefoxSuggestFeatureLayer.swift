// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

protocol NimbusFirefoxSuggestFeatureLayerProtocol {
    var config: [SuggestionType: Bool] { get }
    func isSuggestionProviderAvailable(_ provider: SuggestionProvider) -> Bool
}

/// A translation layer for the `firefoxSuggestFeature.fml`
/// Responsible for creating a model for suggestion information available in the fml.
class NimbusFirefoxSuggestFeatureLayer: NimbusFirefoxSuggestFeatureLayerProtocol {
    let nimbus: FxNimbus

    var config: [SuggestionType: Bool] {
        nimbus.features.firefoxSuggestFeature.value().availableSuggestionsTypes
    }

    init(nimbus: FxNimbus = .shared) {
        self.nimbus = nimbus
    }

    func isSuggestionProviderAvailable(_ provider: SuggestionProvider) -> Bool {
        return switch provider {
        case .amp: config[.amp] ?? false
        case .ampMobile: config[.ampMobile] ?? false
        case .wikipedia: config[.wikipedia] ?? false
        default: false
        }
    }
}
