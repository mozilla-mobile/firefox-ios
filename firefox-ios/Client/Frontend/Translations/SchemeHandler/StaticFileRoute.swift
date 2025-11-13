// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// TODO(FXIOS-14106): Implement this properly
struct StaticFileRoute: TinyRoute {
    func handle(url: URL, components: URLComponents) throws -> TinyHTTPReply? {
        return try? TinyRouter.ok(data: Data([1, 2, 3]), contentType: MIMEType.OctetStream, url: url)
    }
}
