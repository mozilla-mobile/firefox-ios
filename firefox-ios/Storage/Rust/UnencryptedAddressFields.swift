// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct UnencryptedAddressFields {
    public var addressLevel1: String = ""
    public var organization: String = ""
    public var country: String = ""
    public var addressLevel2: String = ""
    public var addressLevel3: String = ""
    public var email: String = ""
    public var streetAddress: String = ""
    public var name: String = ""
    public var postalCode: String = ""
    public var tel: String = ""

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
