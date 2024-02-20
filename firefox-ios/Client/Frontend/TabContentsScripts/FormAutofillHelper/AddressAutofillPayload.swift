// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct AddressAutofillPayload: Codable {
    let addressLevel1: String
    let organization: String
    let country: String
    let addressLevel2: String
    let email: String
    let streetAddress: String
    let name: String
    let postalCode: String

    enum CodingKeys: String, CodingKey, CaseIterable {
        case addressLevel1 = "address-level1"
        case organization = "organization"
        case country = "country"
        case addressLevel2 = "address-level2"
        case email = "email"
        case streetAddress = "street-address"
        case name = "name"
        case postalCode = "postal-code"
    }
}
