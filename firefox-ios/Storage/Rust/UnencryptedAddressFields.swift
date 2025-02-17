// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct UnencryptedAddressFields {
    public var addressLevel1 = ""
    public var organization = ""
    public var country = ""
    public var addressLevel2 = ""
    public var addressLevel3 = ""
    public var email = ""
    public var streetAddress = ""
    public var name = ""
    public var postalCode = ""
    public var tel = ""

    public init() { }

    public init(addressLevel1: String,
                organization: String,
                country: String,
                addressLevel2: String,
                addressLevel3: String,
                email: String,
                streetAddress: String,
                name: String,
                postalCode: String,
                tel: String) {
        self.addressLevel1 = addressLevel1
        self.organization = organization
        self.country = country
        self.addressLevel2 = addressLevel2
        self.addressLevel3 = addressLevel3
        self.email = email
        self.streetAddress = streetAddress
        self.name = name
        self.postalCode = postalCode
        self.tel = tel
    }
}
