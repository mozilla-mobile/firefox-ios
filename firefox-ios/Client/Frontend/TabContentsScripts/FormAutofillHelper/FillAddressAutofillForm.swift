// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct FillAddressAutofillForm: Codable {
    let payload: Payload
    let type: FormAutofillPayloadType

    struct Payload: Codable {
        var addressLevel1: String?
        var addressLevel2: String?
        var addressLevel3: String?
        var addressLine1: String?
        var country: String?
        var email: String?
        var familyName: String?
        var givenName: String?
        var name: String?
        var organization: String?
        var postalCode: String?
        var streetAddress: String?
        var tel: String?

        enum CodingKeys: String, CodingKey {
            case addressLevel1 = "address-level1"
            case addressLevel2 = "address-level2"
            case addressLevel3 = "address-level3"
            case addressLine1 = "address-line1"
            case country
            case email
            case familyName = "family-name"
            case givenName = "given-name"
            case name
            case organization
            case postalCode = "postal-code"
            case streetAddress = "street-address"
            case tel = "tel"
        }
    }
}
