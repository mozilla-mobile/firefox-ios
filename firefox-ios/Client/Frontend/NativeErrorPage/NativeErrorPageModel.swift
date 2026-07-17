// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum ErrorPageModel: Equatable {
    case internetConnection
    case cellularDataRestricted
    case badCertDomain(BadCertDomainModel)
    case generic(GenericErrorModel)

    var title: String {
        switch self {
        case .internetConnection: return .NativeErrorPage.NoInternetConnection.TitleLabel
        case .cellularDataRestricted: return .NativeErrorPage.CellularDataRestricted.TitleLabel
        case .badCertDomain: return String.NativeErrorPage.BadCertDomain.TitleLabel
        case .generic: return .NativeErrorPage.GenericError.TitleLabel
        }
    }

    var description: String {
        switch self {
        case .internetConnection: return .NativeErrorPage.NoInternetConnection.Description
        case .cellularDataRestricted: return .NativeErrorPage.CellularDataRestricted.Description
        case .badCertDomain: return String.NativeErrorPage.BadCertDomain.Description
        case .generic: return .NativeErrorPage.GenericError.Description
        }
    }

    var foxImageName: String {
        switch self {
        case .internetConnection, .cellularDataRestricted:
            return ImageIdentifiers.NativeErrorPage.noInternetConnection
        case .badCertDomain, .generic: return ImageIdentifiers.NativeErrorPage.securityError
        }
    }

    var url: URL? {
        switch self {
        case .internetConnection, .cellularDataRestricted: return nil
        case .badCertDomain(let model): return model.url
        case .generic(let model): return model.url
        }
    }

    var advancedSection: AdvancedSectionConfig? {
        switch self {
        case .badCertDomain(let model): return model.advancedSection
        default: return nil
        }
    }

    var isRegularUI: Bool {
        switch self {
        case .internetConnection, .cellularDataRestricted, .generic: return true
        case .badCertDomain: return false
        }
    }

    struct AdvancedSectionConfig: Equatable {
        let buttonText: String
        let infoText: String
        let warningText: String
        let certificateErrorCode: String?
        let showProceedButton: Bool
    }
}

struct BadCertDomainModel: Equatable {
    let url: URL
    let advancedSection: ErrorPageModel.AdvancedSectionConfig
}

struct GenericErrorModel: Equatable {
    let url: URL?
}
