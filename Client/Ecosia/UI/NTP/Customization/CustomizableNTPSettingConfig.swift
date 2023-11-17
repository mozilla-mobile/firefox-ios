// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core

enum CustomizableNTPSettingConfig: CaseIterable {
    case topSites
    case climateImpact
    case ecosiaNews
    case aboutEcosia

    var localizedTitleKey: String.Key {
        switch self {
        case .topSites: return .topSites
        case .climateImpact: return .climateImpact
        case .ecosiaNews: return .ecosiaNews
        case .aboutEcosia: return .aboutEcosia
        }
    }
    
    var persistedFlag: Bool {
        get {
            switch self {
            case .topSites: return User.shared.showTopSites
            case .climateImpact: return User.shared.showClimateImpact
            case .ecosiaNews: return User.shared.showEcosiaNews
            case .aboutEcosia: return User.shared.showAboutEcosia
            }
        }
        set {
            switch self {
            case .topSites: User.shared.showTopSites = newValue
            case .climateImpact: User.shared.showClimateImpact = newValue
            case .ecosiaNews: User.shared.showEcosiaNews = newValue
            case .aboutEcosia: User.shared.showAboutEcosia = newValue
            }
        }
    }
    
    var analyticsLabel: Analytics.Label.NTP {
        switch self {
        case .topSites: return .topSites
        case .climateImpact: return .impact
        case .ecosiaNews: return .news
        case .aboutEcosia: return .about
        }
    }
}
