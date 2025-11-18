// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared

struct GleanHttpUploader: PingUploaderProtocol {
    let connectionTimeout = TimeInterval(10)
    let logger: Logger
    private let session: URLSessionProtocol

    init(session: URLSessionProtocol = NetworkUtils.defaultGleanPingURLSession(),
         logger: Logger = DefaultLogger.shared) {
        self.session = session
        self.logger = logger
    }

    /// Build the request and create upload operation using a URLSession
    func uploadHttpRequest(request: GleanPingUploadRequest,
                           callback: @escaping @Sendable (UploadResult) -> Void) {
        var body = Data(capacity: request.data.count)
        body.append(contentsOf: request.data)

        if let request = buildRequest(
            url: request.url,
            data: body,
            headers: request.headers
        ) {
            // Create an URLSessionUploadTask to upload our ping and handle the server responses.
            var uploadTask = session.uploadTaskWith(with: request, from: body) { _, response, error in
                if let error {
                    // Upload failed on the client-side. We should try again.
                    logger.log("Upload failed on the client-side: \(error)", level: .info, category: .telemetry)
                    callback(.recoverableFailure(unused: 0))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    logger.log("Upload failed due to unexpected response type", level: .info, category: .telemetry)
                    callback(.recoverableFailure(unused: 0))
                    return
                }

                // HTTP status codes are handled on the Rust side
                let statusCode = Int32(httpResponse.statusCode)
                callback(.httpStatus(code: statusCode))
                logger.log("Sent http ping with status code: \(statusCode)", level: .debug, category: .telemetry)
            }

            uploadTask.countOfBytesClientExpectsToSend = 1024 * 1024
            uploadTask.countOfBytesClientExpectsToReceive = 512
            uploadTask.resume()
        } else {
            logger.log("Rejected http ping since couldn't build request", level: .info, category: .telemetry)
            callback(.unrecoverableFailure(unused: 0))
        }
    }
}
