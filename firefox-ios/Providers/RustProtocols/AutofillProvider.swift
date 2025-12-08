// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import struct MozillaAppServices.UpdatableAddressFields
import struct MozillaAppServices.Address

protocol AddressProvider {
    func listAllAddresses(completion: @escaping @Sendable ([Address]?, Error?) -> Void)
    func addAddress(address: UpdatableAddressFields, completion: @escaping @Sendable (Result<Address, Error>) -> Void)
    func updateAddress(id: String,
                       address: UpdatableAddressFields,
                       completion: @escaping @Sendable (Result<Void, Error>) -> Void)
    func deleteAddress(id: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
}

protocol SyncAutofillProvider {
    func getStoredKey(completion: @Sendable @escaping (Result<String, NSError>) -> Void)
    func registerWithSyncManager()
    func reportPreSyncKeyRetrievalFailure(err: String)
    func verifyCreditCards(key: String, completionHandler: @escaping @Sendable (Bool) -> Void)
}

extension RustAutofill: AddressProvider, SyncAutofillProvider {}
