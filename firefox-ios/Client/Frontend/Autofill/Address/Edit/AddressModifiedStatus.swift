// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum AddressModifiedStatus {
    enum ErrorType {
        case save(action: () -> Void)
        case update(action: () -> Void)
        case remove(action: () -> Void)

        var message: String {
            switch self {
            case .save, .update: return .Addresses.Settings.Edit.AddressSaveError
            case .remove: return .Addresses.Settings.Edit.AddressRemoveError
            }
        }

        var actionTitle: String {
            return .Addresses.Settings.Edit.AddressSaveRetrySuggestion
        }

        var action: () -> Void {
            switch self {
            case .save(let action), .update(let action), .remove(let action):
                return action
            }
        }
    }

    case updated
    case error(ErrorType)

    var message: String {
        switch self {
        case .updated: return .Addresses.Settings.Edit.AddressUpdatedConfirmationV2
        case .error(let type): return type.message
        }
    }
}
