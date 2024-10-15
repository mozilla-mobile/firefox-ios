// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage
import struct MozillaAppServices.UpdatableAddressFields

extension UpdatableAddressFields: Swift.Decodable {
    enum KebabCodingKeys: String, CodingKey {
        case name
        case organization
        case streetAddress = "street-address"
        case addressLevel3 = "address-level3"
        case addressLevel2 = "address-level2"
        case addressLevel1 = "address-level1"
        case postalCode = "postal-code"
        case country
        case tel
        case email
    }

    public init(from decoder: Decoder) throws {
        guard let format = decoder.userInfo[.formatStyleKey] as? FormatStyle else {
            throw FormatStyleError()
        }
        switch format {
        case .kebabCase:
            let container = try decoder.container(keyedBy: KebabCodingKeys.self)
            let name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            let organization = try container.decodeIfPresent(String.self, forKey: .organization) ?? ""
            let streetAddress = try container.decodeIfPresent(String.self, forKey: .streetAddress) ?? ""
            let addressLevel3 = try container.decodeIfPresent(String.self, forKey: .addressLevel3) ?? ""
            let addressLevel2 = try container.decodeIfPresent(String.self, forKey: .addressLevel2) ?? ""
            let addressLevel1 = try container.decodeIfPresent(String.self, forKey: .addressLevel1) ?? ""
            let postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode) ?? ""
            let country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
            let tel = try container.decodeIfPresent(String.self, forKey: .tel) ?? ""
            let email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
            self.init(
                name: name,
                organization: organization,
                streetAddress: streetAddress,
                addressLevel3: addressLevel3,
                addressLevel2: addressLevel2,
                addressLevel1: addressLevel1,
                postalCode: postalCode,
                country: country,
                tel: tel,
                email: email
            )
        }
    }
}
