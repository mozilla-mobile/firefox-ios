// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum AddressModifiedStatus {
    case saved
    case updated
    case removed

    var message: String {
        switch self {
        case .saved: return .Addresses.Settings.Edit.AddressSavedConfirmation
        case .updated: return .Addresses.Settings.Edit.AddressUpdatedConfirmation
        case .removed: return .Addresses.Settings.Edit.AddressRemovedConfirmation
        }
    }
}
