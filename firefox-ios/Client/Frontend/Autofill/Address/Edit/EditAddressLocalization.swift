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

    // TODO: FXIOS-9100 Change the correct strings after UX finalize copyright
    static let editAddressLocalizationIDs = EditAddressLocalization(
        autofillAddressGivenName: "Given Name",
        autofillAddressAdditionalName: "Additional Name",
        autofillAddressFamilyName: "Family Name",
        autofillAddressName: "Full Name",
        autofillAddressOrganization: "Organization",
        autofillAddressStreet: "Street Address",
        autofillAddressState: "State",
        autofillAddressProvince: "Province",
        autofillAddressCity: "City",
        autofillAddressCountry: "Country",
        autofillAddressZip: "ZIP Code",
        autofillAddressPostalCode: "Postal Code",
        autofillAddressEmail: "Email Address",
        autofillAddressTel: "Telephone Number",
        autofillEditAddressTitle: "Edit Address",
        autofillAddressNeighborhood: "Neighborhood",
        autofillAddressVillageTownship: "Village/Township",
        autofillAddressIsland: "Island",
        autofillAddressTownland: "Townland",
        autofillAddressDistrict: "District",
        autofillAddressCounty: "County",
        autofillAddressPostTown: "Post Town",
        autofillAddressSuburb: "Suburb",
        autofillAddressParish: "Parish",
        autofillAddressPrefecture: "Prefecture",
        autofillAddressArea: "Area",
        autofillAddressDoSi: "District or Sub-island",
        autofillAddressDepartment: "Department",
        autofillAddressEmirate: "Emirate",
        autofillAddressOblast: "Oblast",
        autofillAddressPin: "Pincode",
        autofillAddressEircode: "Eircode",
        autofillAddressCountryOnly: "Country Only",
        autofillCancelButton: "Cancel",
        autofillSaveButton: "Save"
    )
}
