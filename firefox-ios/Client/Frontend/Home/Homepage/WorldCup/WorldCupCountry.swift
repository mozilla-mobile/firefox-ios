// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupCountry: Identifiable, Hashable {
    /// Uppercase 3-letter team code matching the World Cup teams API
    /// (e.g. "CAN", "FRA", "GER", "ENG"). Mostly aligned with FIFA codes,
    /// with a few API-specific overrides (e.g. "CDR" for DR Congo,
    /// "CVI" for Cabo Verde).
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
            WorldCupCountry(id: "KSA"),
            WorldCupCountry(id: "UZB"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.Africa, countries: [
            WorldCupCountry(id: "ALG"),
            WorldCupCountry(id: "CVI"),
            WorldCupCountry(id: "CDR"),
            WorldCupCountry(id: "EGY"),
            WorldCupCountry(id: "GHA"),
            WorldCupCountry(id: "CIV"),
            WorldCupCountry(id: "MAR"),
            WorldCupCountry(id: "SEN"),
            WorldCupCountry(id: "RSA"),
            WorldCupCountry(id: "TUN"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.CONCACAF, countries: [
            WorldCupCountry(id: "CUW"),
            WorldCupCountry(id: "HAI"),
            WorldCupCountry(id: "PAN"),
        ]),
        WorldCupRegion(name: .WorldCup.CountryPicker.Confederation.SouthAmerica, countries: [
            WorldCupCountry(id: "ARG"),
            WorldCupCountry(id: "BRA"),
            WorldCupCountry(id: "COL"),
            WorldCupCountry(id: "ECU"),
            WorldCupCountry(id: "PAR"),
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
            WorldCupCountry(id: "GER"),
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
