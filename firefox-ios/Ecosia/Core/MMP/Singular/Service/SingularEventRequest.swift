// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

#if os(iOS)

struct SingularEventRequest: BaseRequest {

    struct Parameters: Encodable {
        let identifier: String
        let name: String
        let platform: String
        let bundleId: String
        let osVersion: String

        enum CodingKeys: String, CodingKey {
            case identifier = "sing"
            case name = "n"
            case platform = "p"
            case bundleId = "i"
            case osVersion = "ve"
        }
    }

    var method: HTTPMethod {
        .get
    }

    var path: String {
        "/v2/attribution/event"
    }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    init(identifier: String, name: String, info: AppDeviceInfo) {
        self.queryParameters = Parameters(identifier: identifier,
                                          name: name,
                                          platform: info.platform,
                                          bundleId: info.bundleId,
                                          osVersion: info.osVersion).dictionary
    }
}

#endif
