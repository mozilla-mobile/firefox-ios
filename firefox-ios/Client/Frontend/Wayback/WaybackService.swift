// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WaybackService {
    struct Snapshot: Decodable {
        public let available: Bool
        public let url: String
        public let timestamp: String
        public let status: String
    }

    private struct Response: Decodable {
        let archivedSnapshots: [String: Snapshot]
    }

    /// Returns the archived snapshot for a URL, or nil if none exists.
    static func fetchSnapshot(
        for urlString: String,
        session: URLSession = .shared
    ) async throws -> Snapshot? {
        var components = URLComponents(string: "https://archive.org/wayback/available")!
        components.queryItems = [URLQueryItem(name: "url", value: urlString)]

        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.archived_snapshots["closest"]
    }
}
