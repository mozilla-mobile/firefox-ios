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
    case wayback(WaybackErrorModel)
    var title: String {
        switch self {
        case .internetConnection: return .NativeErrorPage.NoInternetConnection.TitleLabel
        case .cellularDataRestricted:
            return String(format: .NativeErrorPage.CellularDataRestricted.TitleLabel, AppName.shortName.rawValue)
        case .badCertDomain: return String.NativeErrorPage.BadCertDomain.TitleLabel
        case .generic: return .NativeErrorPage.GenericError.TitleLabel
        case .wayback: return .NativeErrorPage.Wayback.TitleLabel
        }
    }

    var description: String {
        switch self {
        case .internetConnection: return .NativeErrorPage.NoInternetConnection.Description
        case .cellularDataRestricted:
            return String(format: .NativeErrorPage.CellularDataRestricted.Description, AppName.shortName.rawValue)
        case .badCertDomain: return String.NativeErrorPage.BadCertDomain.Description
        case .generic(let model): return String(format: .NativeErrorPage.GenericError.Description,
                                                AppName.shortName.description,
                                                model.url?.host ?? String.NativeErrorPage.GenericError.UnknownHost)
        case .wayback: return String(format: .NativeErrorPage.Wayback.Description, AppName.shortName.description)
        }
    }

    var foxImageName: String {
        switch self {
        case .internetConnection, .generic, .wayback, .cellularDataRestricted:
            return ImageIdentifiers.NativeErrorPage.noInternetConnection
        case .badCertDomain: return ImageIdentifiers.NativeErrorPage.securityError
        }
    }

    var url: URL? {
        switch self {
        case .internetConnection, .cellularDataRestricted: return nil
        case .badCertDomain(let model): return model.url
        case .generic(let model): return model.url
        case .wayback(let model): return model.url
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
        case .internetConnection, .cellularDataRestricted, .generic, .wayback: return true
        case .badCertDomain: return false
        }
    }

    var isWayback: Bool {
        if case .wayback = self { return true }
        return false
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

struct WaybackErrorModel: Equatable {
    let url: URL
}
