// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct EditAddressLocalization: Encodable {
    let autofillAddressGivenName: String
    let autofillAddressAdditionalName: String
    let autofillAddressFamilyName: String
    let autofillAddressName: String
    let autofillAddressOrganization: String
    let autofillAddressStreet: String
    let autofillAddressState: String
    let autofillAddressProvince: String
    let autofillAddressCity: String
    let autofillAddressCountry: String
    let autofillAddressZip: String
    let autofillAddressPostalCode: String
    let autofillAddressEmail: String
    let autofillAddressTel: String
    let autofillEditAddressTitle: String
    let autofillAddressNeighborhood: String
    let autofillAddressVillageTownship: String
    let autofillAddressIsland: String
    let autofillAddressTownland: String
    let autofillAddressDistrict: String
    let autofillAddressCounty: String
    let autofillAddressPostTown: String
    let autofillAddressSuburb: String
    let autofillAddressParish: String
    let autofillAddressPrefecture: String
    let autofillAddressArea: String
    let autofillAddressDoSi: String
    let autofillAddressDepartment: String
    let autofillAddressEmirate: String
    let autofillAddressOblast: String
    let autofillAddressPin: String
    let autofillAddressEircode: String
    let autofillAddressCountryOnly: String
    let autofillCancelButton: String
    let autofillSaveButton: String

    enum CodingKeys: String, CodingKey {
        case autofillAddressGivenName = "autofill-address-given-name"
        case autofillAddressAdditionalName = "autofill-address-additional-name"
        case autofillAddressFamilyName = "autofill-address-family-name"
        case autofillAddressName = "autofill-address-name"
        case autofillAddressOrganization = "autofill-address-organization"
        case autofillAddressStreet = "autofill-address-street"
        case autofillAddressState = "autofill-address-state"
        case autofillAddressProvince = "autofill-address-province"
        case autofillAddressCity = "autofill-address-city"
        case autofillAddressCountry = "autofill-address-country"
        case autofillAddressZip = "autofill-address-zip"
        case autofillAddressPostalCode = "autofill-address-postal-code"
        case autofillAddressEmail = "autofill-address-email"
        case autofillAddressTel = "autofill-address-tel"
        case autofillEditAddressTitle = "autofill-edit-address-title"
        case autofillAddressNeighborhood = "autofill-address-neighborhood"
        case autofillAddressVillageTownship = "autofill-address-village-township"
        case autofillAddressIsland = "autofill-address-island"
        case autofillAddressTownland = "autofill-address-townland"
        case autofillAddressDistrict = "autofill-address-district"
        case autofillAddressCounty = "autofill-address-county"
        case autofillAddressPostTown = "autofill-address-post-town"
        case autofillAddressSuburb = "autofill-address-suburb"
        case autofillAddressParish = "autofill-address-parish"
        case autofillAddressPrefecture = "autofill-address-prefecture"
        case autofillAddressArea = "autofill-address-area"
        case autofillAddressDoSi = "autofill-address-do-si"
        case autofillAddressDepartment = "autofill-address-department"
        case autofillAddressEmirate = "autofill-address-emirate"
        case autofillAddressOblast = "autofill-address-oblast"
        case autofillAddressPin = "autofill-address-pin"
        case autofillAddressEircode = "autofill-address-eircode"
        case autofillAddressCountryOnly = "autofill-address-country-only"
        case autofillCancelButton = "autofill-cancel-button"
        case autofillSaveButton = "autofill-save-button"
    }

    static let editAddressLocalizationIDs = EditAddressLocalization(
        autofillAddressGivenName: .Addresses.Settings.Edit.AutofillAddressName,
        autofillAddressAdditionalName: .Addresses.Settings.Edit.AutofillAddressName,
        autofillAddressFamilyName: .Addresses.Settings.Edit.AutofillAddressName,
        autofillAddressName: .Addresses.Settings.Edit.AutofillAddressName,
        autofillAddressOrganization: .Addresses.Settings.Edit.AutofillAddressOrganization,
        autofillAddressStreet: .Addresses.Settings.Edit.AutofillEditStreetAddressTitle,
        autofillAddressState: .Addresses.Settings.Edit.AutofillAddressState,
        autofillAddressProvince: .Addresses.Settings.Edit.AutofillAddressProvince,
        autofillAddressCity: .Addresses.Settings.Edit.AutofillAddressCity,
        autofillAddressCountry: .Addresses.Settings.Edit.AutofillAddressCountryRegion,
        autofillAddressZip: .Addresses.Settings.Edit.AutofillAddressZip,
        autofillAddressPostalCode: .Addresses.Settings.Edit.AutofillAddressPostalCode,
        autofillAddressEmail: .Addresses.Settings.Edit.AutofillAddressEmail,
        autofillAddressTel: .Addresses.Settings.Edit.AutofillAddressTel,
        autofillEditAddressTitle: .Addresses.Settings.Edit.AutofillEditAddressTitle,
        autofillAddressNeighborhood: .Addresses.Settings.Edit.AutofillAddressNeighborhood,
        autofillAddressVillageTownship: .Addresses.Settings.Edit.AutofillAddressVillageTownship,
        autofillAddressIsland: .Addresses.Settings.Edit.AutofillAddressIsland,
        autofillAddressTownland: .Addresses.Settings.Edit.AutofillAddressTownland,
        autofillAddressDistrict: .Addresses.Settings.Edit.AutofillAddressDistrict,
        autofillAddressCounty: .Addresses.Settings.Edit.AutofillAddressCounty,
        autofillAddressPostTown: .Addresses.Settings.Edit.AutofillAddressPostTown,
        autofillAddressSuburb: .Addresses.Settings.Edit.AutofillAddressSuburb,
        autofillAddressParish: .Addresses.Settings.Edit.AutofillAddressParish,
        autofillAddressPrefecture: .Addresses.Settings.Edit.AutofillAddressPrefecture,
        autofillAddressArea: .Addresses.Settings.Edit.AutofillAddressArea,
        autofillAddressDoSi: .Addresses.Settings.Edit.AutofillAddressDoSi,
        autofillAddressDepartment: .Addresses.Settings.Edit.AutofillAddressDepartment,
        autofillAddressEmirate: .Addresses.Settings.Edit.AutofillAddressEmirate,
        autofillAddressOblast: .Addresses.Settings.Edit.AutofillAddressOblast,
        autofillAddressPin: .Addresses.Settings.Edit.AutofillAddressPin,
        autofillAddressEircode: .Addresses.Settings.Edit.AutofillAddressEircode,
        autofillAddressCountryOnly: .Addresses.Settings.Edit.AutofillAddressCountryOnly,
        autofillCancelButton: .Addresses.Settings.Edit.AutofillCancelButton,
        autofillSaveButton: .Addresses.Settings.Edit.AutofillSaveButton
    )
}
