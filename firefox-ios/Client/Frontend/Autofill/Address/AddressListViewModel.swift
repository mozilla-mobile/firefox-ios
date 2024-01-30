// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared
import Storage

// TODO: PHASE-2 FXIOS-7653
// AddressListViewModelDelegate: A protocol to notify delegates about address updates.
// protocol AddressListViewModelDelegate: AnyObject {
//     func didUpdateAddresses(_ addresses: [Address])
// }

// TODO: Refactor the Address extension for global usage (FXIOS-8337)
extension Address {
    var fullName: String {
        return "\(givenName) \(familyName)"
    }

    var addressCityStateZipcode: String {
        return "\(addressLevel2), \(addressLevel1) \(postalCode)"
    }
}

// AddressListViewModel: A view model for managing addresses.
class AddressListViewModel: ObservableObject {
    // MARK: - Properties

    @Published var addresses: [Address] = []
    @Published var showSection = false
    private let profile: Profile?
    private let logger: Logger

    // MARK: - Initializer

    /// Initializes the AddressListViewModel.
    /// - Parameter profile: The profile associated with the address list.
    init(profile: Profile? = nil, logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    // MARK: - Fetch Addresses

    /// Fetches addresses from the associated profile's autofill.
    func fetchAddresses() {
        // Assuming profile is a class-level variable
        profile?.autofill.listAllAddresses { [weak self] storedAddresses, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let addresses = storedAddresses {
                    self.addresses = addresses
                    self.showSection = !addresses.isEmpty
                } else if let error = error {
                    self.logger.log("Error fetching addresses",
                                    level: .warning,
                                    category: .address,
                                    description: "Error fetching addresses: \(error.localizedDescription)")
                }
            }
        }
    }
}
