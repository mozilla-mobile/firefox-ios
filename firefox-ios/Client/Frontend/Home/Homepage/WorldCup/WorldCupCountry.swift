// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupCountry: Identifiable, Hashable {
    /// Uppercase ISO 3166-1 alpha-3 region code (e.g. "CAN", "FRA") or the
    /// FIFA-style code for sub-national teams (e.g. "ENG", "SCO").
    let id: String
}

struct WorldCupRegion: Identifiable {
    let name: String
    let countries: [WorldCupCountry]

    var id: String { name }
}

enum WorldCupCountryData {
    static let regions: [WorldCupRegion] = [
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.NorthAmerica, countries: [
            WorldCupCountry(id: "CAN"),
            WorldCupCountry(id: "MEX"),
            WorldCupCountry(id: "USA"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Asia, countries: [
            WorldCupCountry(id: "AUS"),
            WorldCupCountry(id: "IRN"),
            WorldCupCountry(id: "IRQ"),
            WorldCupCountry(id: "JPN"),
            WorldCupCountry(id: "JOR"),
            WorldCupCountry(id: "KOR"),
            WorldCupCountry(id: "QAT"),
            WorldCupCountry(id: "SAU"),
            WorldCupCountry(id: "UZB"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Africa, countries: [
            WorldCupCountry(id: "DZA"),
            WorldCupCountry(id: "CPV"),
            WorldCupCountry(id: "COD"),
            WorldCupCountry(id: "EGY"),
            WorldCupCountry(id: "GHA"),
            WorldCupCountry(id: "CIV"),
            WorldCupCountry(id: "MAR"),
            WorldCupCountry(id: "SEN"),
            WorldCupCountry(id: "ZAF"),
            WorldCupCountry(id: "TUN"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.CONCACAF, countries: [
            WorldCupCountry(id: "CUW"),
            WorldCupCountry(id: "HTI"),
            WorldCupCountry(id: "PAN"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.SouthAmerica, countries: [
            WorldCupCountry(id: "ARG"),
            WorldCupCountry(id: "BRA"),
            WorldCupCountry(id: "COL"),
            WorldCupCountry(id: "ECU"),
            WorldCupCountry(id: "PRY"),
            WorldCupCountry(id: "URY"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Oceania, countries: [
            WorldCupCountry(id: "NZL"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Europe, countries: [
            WorldCupCountry(id: "AUT"),
            WorldCupCountry(id: "BEL"),
            WorldCupCountry(id: "BIH"),
            WorldCupCountry(id: "HRV"),
            WorldCupCountry(id: "CZE"),
            WorldCupCountry(id: "ENG"),
            WorldCupCountry(id: "FRA"),
            WorldCupCountry(id: "DEU"),
            WorldCupCountry(id: "NLD"),
            WorldCupCountry(id: "NOR"),
            WorldCupCountry(id: "PRT"),
            WorldCupCountry(id: "SCO"),
            WorldCupCountry(id: "ESP"),
            WorldCupCountry(id: "SWE"),
            WorldCupCountry(id: "CHE"),
            WorldCupCountry(id: "TUR"),
        ]),
    ]
}
