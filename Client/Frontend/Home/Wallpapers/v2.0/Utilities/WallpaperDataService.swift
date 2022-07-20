// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

///  Responsible for fetching data from the server.
struct WallpaperDataService: WallpaperFetchDataService {

    private let dataService: WallpaperFetchDataService

    init(with dataService: WallpaperFetchDataService) {
        self.dataService = dataService
    }

    func getMetadata() async throws -> WallpaperMetadata {
        // Roux Notes for PR Review:
        // Ignore the contents of this function for now. I just needed to make Xcode
        // not give me errors while I'm slowly building the system.
        return WallpaperMetadata(lastUpdatedDate: "0864",
                                 collections: [WallpaperCollection]())
    }
}
