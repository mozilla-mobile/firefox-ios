// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Storage

import struct MozillaAppServices.Address

extension CodingUserInfoKey {
    static let formatStyleKey = CodingUserInfoKey(rawValue: "FormatStyleKey")!
}

enum FormatStyle {
    case kebabCase
}

struct FormatStyleError: Error {}

extension Address: Swift.Encodable {
    enum KebabCodingKeys: String, CodingKey {
        case guid
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
        case timeCreated = "time-created"
        case timeLastUsed = "time-last-used"
        case timeLastModified = "time-last-modified"
        case timesUsed = "times-used"
    }

    public func encode(to encoder: Encoder) throws {
        guard let format = encoder.userInfo[.formatStyleKey] as? FormatStyle else {
            throw FormatStyleError()
        }
        switch format {
        case .kebabCase:
            var container = encoder.container(keyedBy: KebabCodingKeys.self)
            try container.encode(guid, forKey: .guid)
            try container.encode(name, forKey: .name)
            try container.encode(organization, forKey: .organization)
            try container.encode(streetAddress, forKey: .streetAddress)
            try container.encode(addressLevel3, forKey: .addressLevel3)
            try container.encode(addressLevel2, forKey: .addressLevel2)
            try container.encode(addressLevel1, forKey: .addressLevel1)
            try container.encode(postalCode, forKey: .postalCode)
            try container.encode(country, forKey: .country)
            try container.encode(tel, forKey: .tel)
            try container.encode(email, forKey: .email)
            try container.encode(timeCreated, forKey: .timeCreated)
            try container.encodeIfPresent(timeLastUsed, forKey: .timeLastUsed)
            try container.encode(timeLastModified, forKey: .timeLastModified)
            try container.encode(timesUsed, forKey: .timesUsed)
        }
    }
}

extension Address: Swift.Identifiable {
    public var id: String { guid }
}

extension Address {
    var addressCityStateZipcode: String {
        var components = [addressLevel2, addressLevel1, postalCode]
        components = components.compactMap { $0.isEmpty ? nil : $0 }
        return components.joined(separator: ", ")
    }

    var a11ySettingsRow: String {
        let components = [
            name,
            streetAddress,
            addressLevel2,
            addressLevel1,
            postalCode
        ]
        let nonEmptyComponents = components.compactMap { $0.isEmpty ? nil : $0 }
        let addressDetails = nonEmptyComponents.joined(separator: ", ")
        let label = String(format: String.Addresses.Settings.ListItemA11y, addressDetails)
        return label
    }
}
