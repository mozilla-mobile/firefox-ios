// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupCountry: Identifiable, Hashable {
    /// ISO 3166-1 alpha-2 region code (e.g. "CA", "FR") or a custom code for
    /// sub-national teams (e.g. "ENG", "SCO").
    let id: String

    var name: String {
        switch id {
        case "ENG": return .WorldCup.CountryPicker.CountryName.England
        case "SCO": return .WorldCup.CountryPicker.CountryName.Scotland
        default:
            return Locale.current.localizedString(forRegionCode: id) ?? id
        }
    }
}

struct WorldCupRegion: Identifiable {
    let name: String
    let countries: [WorldCupCountry]

    var id: String { name }
}

enum WorldCupCountryData {
    static let regions: [WorldCupRegion] = [
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.NorthAmerica, countries: [
            WorldCupCountry(id: "CA"),
            WorldCupCountry(id: "MX"),
            WorldCupCountry(id: "US"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Asia, countries: [
            WorldCupCountry(id: "AU"),
            WorldCupCountry(id: "IR"),
            WorldCupCountry(id: "IQ"),
            WorldCupCountry(id: "JP"),
            WorldCupCountry(id: "JO"),
            WorldCupCountry(id: "KR"),
            WorldCupCountry(id: "QA"),
            WorldCupCountry(id: "SA"),
            WorldCupCountry(id: "UZ"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Africa, countries: [
            WorldCupCountry(id: "DZ"),
            WorldCupCountry(id: "CV"),
            WorldCupCountry(id: "CD"),
            WorldCupCountry(id: "EG"),
            WorldCupCountry(id: "GH"),
            WorldCupCountry(id: "CI"),
            WorldCupCountry(id: "MA"),
            WorldCupCountry(id: "SN"),
            WorldCupCountry(id: "ZA"),
            WorldCupCountry(id: "TN"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.CONCACAF, countries: [
            WorldCupCountry(id: "CW"),
            WorldCupCountry(id: "HT"),
            WorldCupCountry(id: "PA"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.SouthAmerica, countries: [
            WorldCupCountry(id: "AR"),
            WorldCupCountry(id: "BR"),
            WorldCupCountry(id: "CO"),
            WorldCupCountry(id: "EC"),
            WorldCupCountry(id: "PY"),
            WorldCupCountry(id: "UY"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Oceania, countries: [
            WorldCupCountry(id: "NZ"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Europe, countries: [
            WorldCupCountry(id: "AT"),
            WorldCupCountry(id: "BE"),
            WorldCupCountry(id: "BA"),
            WorldCupCountry(id: "HR"),
            WorldCupCountry(id: "CZ"),
            WorldCupCountry(id: "ENG"),
            WorldCupCountry(id: "FR"),
            WorldCupCountry(id: "DE"),
            WorldCupCountry(id: "NL"),
            WorldCupCountry(id: "NO"),
            WorldCupCountry(id: "PT"),
            WorldCupCountry(id: "SCO"),
            WorldCupCountry(id: "ES"),
            WorldCupCountry(id: "SE"),
            WorldCupCountry(id: "CH"),
            WorldCupCountry(id: "TR"),
        ]),
    ]
}
