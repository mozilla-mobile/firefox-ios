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

    case saved
    case updated
    case removed
    case error(ErrorType)

    var message: String {
        switch self {
        case .saved: return .Addresses.Settings.Edit.AddressSavedConfirmation
        case .updated: return .Addresses.Settings.Edit.AddressUpdatedConfirmationV2
        case .removed: return .Addresses.Settings.Edit.AddressRemovedConfirmation
        case .error(let type): return type.message
        }
    }
}
