// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import class MozillaAppServices.MozAdsClient

public final class RustAdsClient {
    public static let shared = MozAdsClient(dbPath: getDatabaseURL())
    private init() {}
}

func getDatabaseURL() -> String {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    return documentsURL.appendingPathComponent("ads-client.db").path
}
