// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

extension Locale {
    func regionCode() -> String {
        let systemRegion: String?
        if #available(iOS 17, *) {
            systemRegion = (self as NSLocale).regionCode
        } else {
            systemRegion = (self as NSLocale).countryCode
        }
        return systemRegion ?? self.identifier.components(separatedBy: "-").last ?? "US"
    }
}
