// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol WallpaperDateFormatter {

}

extension WallpaperDateFormatter {
    func dateFrom(_ stringDate: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = dateFormatter.date(from: stringDate) else {
            return Calendar.current.startOfDay(for: Date())
        }

        return Calendar.current.startOfDay(for: date)
    }
}
