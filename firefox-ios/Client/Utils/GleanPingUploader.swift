// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import MozillaAppServices

/// Custom Glean Ping Uploader supporting both OHTTP and HTTP capabilities
struct GleanPingUploader: PingUploader {
    private let logger: Logger
    private let ohttpUploader: GleanOhttpUploader
    private let httpUploader: GleanHttpUploader

    private enum PingCapabilities: String {
        case ohttp, http
    }

    init?(logger: Logger = DefaultLogger.shared) {
        let environment = OhttpEnvironment.prod
        guard let configURL = environment.config,
              let relayUrl = environment.relay else {
            logger.log("Could not build OHTTP environment", level: .fatal, category: .telemetry)
            return nil
        }

        let manager = OhttpManager(configUrl: configURL, relayUrl: relayUrl)
        self.ohttpUploader = GleanOhttpUploader(manager: manager)
        self.httpUploader = GleanHttpUploader()
        self.logger = logger
    }

    func upload(request: CapablePingUploadRequest,
                callback: @escaping @Sendable (UploadResult) -> Void) {
        if let capableRequest = request.capable([PingCapabilities.http.rawValue]) {
            httpUploader.uploadHttpRequest(request: capableRequest, callback: callback)
        } else if let capableRequest = request.capable([PingCapabilities.ohttp.rawValue]) {
            ohttpUploader.uploadOhttpRequest(request: capableRequest, callback: callback)
        } else {
            logger.log("Rejected ping upload due to unsupported capabilities", level: .info, category: .telemetry)
            callback(.incapable(unused: 0))
            return
        }
    }
}

/// Adding a protocol on top of the `Glean.PingUploadRequest` so we can unit tests
protocol GleanPingUploadRequest {
    var url: String { get }
    var data: [UInt8] { get }
    var headers: HeadersList { get }
}

extension PingUploadRequest: GleanPingUploadRequest {}
