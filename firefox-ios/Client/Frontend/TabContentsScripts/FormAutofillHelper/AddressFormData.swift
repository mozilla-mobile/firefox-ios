// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct AddressFormData: Codable {
    let type: EventType
    let object: String?
    let value: String?
    let category: String?
    let method: Method?
    let extra: Extra?

    enum Method: String, Codable {
        case detected
        case filled
        case filledModified = "filled_modified"
    }
    enum EventType: String, Codable {
        case scalar
        case event
    }

    struct Extra: Codable {
        let streetAddress: String?
        let addressLine1: String?
        let addressLine2: String?
        let addressLine3: String?
        let addressLevel1: String?
        let addressLevel2: String?
        let postalCode: String?
        let country: String?
        let name: String?
        let givenName: String?
        let additionalName: String?
        let familyName: String?
        let email: String?
        let organization: String?
        let tel: String?
        let fieldName: String?

        enum CodingKeys: String, CodingKey {
            case streetAddress = "street_address"
            case addressLine1 = "address_line1"
            case addressLine2 = "address_line2"
            case addressLine3 = "address_line3"
            case addressLevel1 = "address_level1"
            case addressLevel2 = "address_level2"
            case postalCode = "postal_code"
            case country
            case name
            case givenName = "given_name"
            case additionalName = "additional_name"
            case familyName = "family_name"
            case email
            case organization
            case tel
            case fieldName = "field_name"
        }
    }
}
