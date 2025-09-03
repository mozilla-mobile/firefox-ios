// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
@testable import Client

struct MockGleanPingUploadRequest: GleanPingUploadRequest {
    var url = "https://test.com"
    var data: [UInt8] = [1, 2, 3, 4, 6]
    var headers: HeadersList = ["ContentType": "application/json"]
}
