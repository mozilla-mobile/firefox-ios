// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ErrorPageType: Equatable {
    case internetConnection
    case badCertDomain
    case generic
    case wayback

    var isRegularUI: Bool {
        switch self {
        case .internetConnection, .generic, .wayback: return true
        case .badCertDomain: return false
        }
    }
}

struct ErrorPageModel: Equatable {
    let errorTitle: String
    let errorDescription: String
    let foxImageName: String
    let url: URL?
    let advancedSection: AdvancedSectionConfig?
    let showGoBackButton: Bool
    // TODO - FXIOS-16001 - Refactoring the error page model 
    // so that the error page type determines the model structure 
    // rather than storing type within the error page model itself.
    let type: ErrorPageType

    struct AdvancedSectionConfig: Equatable {
        let buttonText: String
        let infoText: String
        let warningText: String
        let certificateErrorCode: String?
        let showProceedButton: Bool
    }
}
