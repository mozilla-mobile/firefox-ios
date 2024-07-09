// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import struct MozillaAppServices.UpdatableAddressFields
import struct MozillaAppServices.Address

protocol AddressProvider {
    func listAllAddresses(completion: @escaping ([Address]?, Error?) -> Void)
    func addAddress(address: UpdatableAddressFields, completion: @escaping (Result<Address, Error>) -> Void)
    func updateAddress(id: String, address: UpdatableAddressFields, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteAddress(id: String, completion: @escaping (Result<Void, Error>) -> Void)
}

extension RustAutofill: AddressProvider {}
