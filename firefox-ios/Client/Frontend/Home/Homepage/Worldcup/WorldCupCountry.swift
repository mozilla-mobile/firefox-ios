// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct WorldCupCountry: Identifiable, Hashable {
    let id: String
    let name: String
    let code: String
    let flagEmoji: String
}

struct WorldCupRegion: Identifiable {
    let id: String
    let name: String
    let countries: [WorldCupCountry]
}

enum WorldCupCountryData {
    static let regions: [WorldCupRegion] = [
        WorldCupRegion(id: "na", name: "NORTH AMERICA", countries: [
            WorldCupCountry(id: "ca", name: "Canada", code: "CAN", flagEmoji: "\u{1F1E8}\u{1F1E6}"),
            WorldCupCountry(id: "mx", name: "Mexico", code: "MEX", flagEmoji: "\u{1F1F2}\u{1F1FD}"),
            WorldCupCountry(id: "us", name: "United States", code: "USA", flagEmoji: "\u{1F1FA}\u{1F1F8}"),
        ]),
        WorldCupRegion(id: "as", name: "ASIA", countries: [
            WorldCupCountry(id: "au", name: "Australia", code: "AUS", flagEmoji: "\u{1F1E6}\u{1F1FA}"),
            WorldCupCountry(id: "ir", name: "Iran", code: "IRN", flagEmoji: "\u{1F1EE}\u{1F1F7}"),
            WorldCupCountry(id: "iq", name: "Iraq", code: "IRQ", flagEmoji: "\u{1F1EE}\u{1F1F6}"),
            WorldCupCountry(id: "jp", name: "Japan", code: "JPN", flagEmoji: "\u{1F1EF}\u{1F1F5}"),
            WorldCupCountry(id: "jo", name: "Jordan", code: "JOR", flagEmoji: "\u{1F1EF}\u{1F1F4}"),
            WorldCupCountry(id: "kr", name: "Korean Republic", code: "KOR", flagEmoji: "\u{1F1F0}\u{1F1F7}"),
            WorldCupCountry(id: "qa", name: "Qatar", code: "QAT", flagEmoji: "\u{1F1F6}\u{1F1E6}"),
            WorldCupCountry(id: "sa", name: "Saudi Arabia", code: "KSA", flagEmoji: "\u{1F1F8}\u{1F1E6}"),
            WorldCupCountry(id: "uz", name: "Uzbekistan", code: "UZB", flagEmoji: "\u{1F1FA}\u{1F1FF}"),
        ]),
        WorldCupRegion(id: "af", name: "AFRICA", countries: [
            WorldCupCountry(id: "dz", name: "Algeria", code: "ALG", flagEmoji: "\u{1F1E9}\u{1F1FF}"),
            WorldCupCountry(id: "cv", name: "Cape Verde", code: "CPV", flagEmoji: "\u{1F1E8}\u{1F1FB}"),
            WorldCupCountry(id: "cd", name: "DR Congo", code: "COD", flagEmoji: "\u{1F1E8}\u{1F1E9}"),
            WorldCupCountry(id: "eg", name: "Egypt", code: "EGY", flagEmoji: "\u{1F1EA}\u{1F1EC}"),
            WorldCupCountry(id: "gh", name: "Ghana", code: "GHA", flagEmoji: "\u{1F1EC}\u{1F1ED}"),
            WorldCupCountry(id: "ci", name: "Ivory Coast", code: "CIV", flagEmoji: "\u{1F1E8}\u{1F1EE}"),
            WorldCupCountry(id: "ma", name: "Morocco", code: "MOR", flagEmoji: "\u{1F1F2}\u{1F1E6}"),
            WorldCupCountry(id: "sn", name: "Senegal", code: "SEN", flagEmoji: "\u{1F1F8}\u{1F1F3}"),
            WorldCupCountry(id: "za", name: "South Africa", code: "RSA", flagEmoji: "\u{1F1FF}\u{1F1E6}"),
            WorldCupCountry(id: "tn", name: "Tunisia", code: "TUN", flagEmoji: "\u{1F1F9}\u{1F1F3}"),
        ]),
        WorldCupRegion(id: "cb", name: "CARIBBEAN", countries: [
            WorldCupCountry(id: "cw", name: "Curaçao", code: "CUW", flagEmoji: "\u{1F1E8}\u{1F1FC}"),
            WorldCupCountry(id: "ht", name: "Haiti", code: "HAI", flagEmoji: "\u{1F1ED}\u{1F1F9}"),
            WorldCupCountry(id: "pa", name: "Panama", code: "PAN", flagEmoji: "\u{1F1F5}\u{1F1E6}"),
        ]),
        WorldCupRegion(id: "sa", name: "SOUTH AMERICA", countries: [
            WorldCupCountry(id: "ar", name: "Argentina", code: "ARG", flagEmoji: "\u{1F1E6}\u{1F1F7}"),
            WorldCupCountry(id: "br", name: "Brazil", code: "BRA", flagEmoji: "\u{1F1E7}\u{1F1F7}"),
            WorldCupCountry(id: "co", name: "Colombia", code: "COL", flagEmoji: "\u{1F1E8}\u{1F1F4}"),
            WorldCupCountry(id: "ec", name: "Ecuador", code: "ECU", flagEmoji: "\u{1F1EA}\u{1F1E8}"),
            WorldCupCountry(id: "py", name: "Paraguay", code: "PAR", flagEmoji: "\u{1F1F5}\u{1F1FE}"),
            WorldCupCountry(id: "uy", name: "Uruguay", code: "URU", flagEmoji: "\u{1F1FA}\u{1F1FE}"),
        ]),
        WorldCupRegion(id: "oc", name: "OCEANIA", countries: [
            WorldCupCountry(id: "nz", name: "New Zealand", code: "NZL", flagEmoji: "\u{1F1F3}\u{1F1FF}"),
        ]),
        WorldCupRegion(id: "eu", name: "EUROPE", countries: [
            WorldCupCountry(id: "at", name: "Austria", code: "AUT", flagEmoji: "\u{1F1E6}\u{1F1F9}"),
            WorldCupCountry(id: "be", name: "Belgium", code: "BEL", flagEmoji: "\u{1F1E7}\u{1F1EA}"),
            WorldCupCountry(id: "ba", name: "Bosnia and Herzegovina", code: "BIH", flagEmoji: "\u{1F1E7}\u{1F1E6}"),
            WorldCupCountry(id: "hr", name: "Croatia", code: "CRO", flagEmoji: "\u{1F1ED}\u{1F1F7}"),
            WorldCupCountry(id: "cz", name: "Czechia", code: "CZE", flagEmoji: "\u{1F1E8}\u{1F1FF}"),
            WorldCupCountry(id: "eng", name: "England", code: "ENG", flagEmoji: "\u{1F3F4}\u{E0067}\u{E0062}\u{E0065}\u{E006E}\u{E0067}\u{E007F}"),
            WorldCupCountry(id: "fr", name: "France", code: "FRA", flagEmoji: "\u{1F1EB}\u{1F1F7}"),
            WorldCupCountry(id: "de", name: "Germany", code: "GER", flagEmoji: "\u{1F1E9}\u{1F1EA}"),
            WorldCupCountry(id: "nl", name: "Netherlands", code: "NED", flagEmoji: "\u{1F1F3}\u{1F1F1}"),
            WorldCupCountry(id: "no", name: "Norway", code: "NOR", flagEmoji: "\u{1F1F3}\u{1F1F4}"),
            WorldCupCountry(id: "pt", name: "Portugal", code: "POR", flagEmoji: "\u{1F1F5}\u{1F1F9}"),
            WorldCupCountry(id: "sco", name: "Scotland", code: "SCO", flagEmoji: "\u{1F3F4}\u{E0067}\u{E0062}\u{E0073}\u{E0063}\u{E0074}\u{E007F}"),
            WorldCupCountry(id: "es", name: "Spain", code: "ESP", flagEmoji: "\u{1F1EA}\u{1F1F8}"),
            WorldCupCountry(id: "se", name: "Sweden", code: "SWE", flagEmoji: "\u{1F1F8}\u{1F1EA}"),
            WorldCupCountry(id: "ch", name: "Switzerland", code: "SUI", flagEmoji: "\u{1F1E8}\u{1F1ED}"),
            WorldCupCountry(id: "tr", name: "Turkey", code: "TUR", flagEmoji: "\u{1F1F9}\u{1F1F7}"),
        ]),
    ]
}
