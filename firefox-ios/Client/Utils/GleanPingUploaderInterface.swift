// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

// TODO: Laurie - Will be imported from Glean 65.0.3 (TO REMOVE)

public typealias HeadersList = [String: String]

/// The interface defining how to send pings.
public protocol PingUploader {
    /**
     * Synchronously upload a ping to a server.
     *
     * @param request the ping upload request, locked within a uploader capability check
     *
     * @param callback used to return the status code of the upload response, so Glean knows whether or not to try again
     */
    func upload(
        request: CapablePingUploadRequest,
        callback: @escaping (UploadResult) -> Void
    )
}

struct PingRequest {
    let documentId: String
    let path: String
    let body: [UInt8]
    let headers: [String: String]
    let uploaderCapabilities: [String]
}

public struct PingUploadRequest {
    let documentId: String
    public let url: String
    public let data: [UInt8]
    public let headers: HeadersList
    let uploaderCapabilities: [String]

    init(request: PingRequest, endpoint: String) {
        self.documentId = request.documentId
        self.url = endpoint + request.path
        self.data = request.body
        self.headers = request.headers
        self.uploaderCapabilities = request.uploaderCapabilities
    }
}

public struct CapablePingUploadRequest {
    private let request: PingUploadRequest

    init(_ request: PingUploadRequest) {
        self.request = request
    }

    /**
     * Checks to see if the requested uploader capabilites are within the advertised uploader capabilities.
     *
     *@param uploaderCapabilities an array of Strings representing the uploader's supported capabilities.
     */
    public func capable(_ uploaderCapabilities: [String]) -> PingUploadRequest? {
        // Check to see if the request's uploader capabilites are all satisfied by the
        // uploader capabilites that were advertised by the uploader via the
        // `uploaderCapabilities` parameter to this function.
        if self.request.uploaderCapabilities.allSatisfy(uploaderCapabilities.contains) {
            return self.request
        }
        return nil
    }
}
