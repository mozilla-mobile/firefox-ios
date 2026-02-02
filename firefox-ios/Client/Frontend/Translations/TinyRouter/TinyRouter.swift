// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A minimal URL routing system that matches paths to handlers.
/// Routes are checked in registration order, first match returns response.
public final class TinyRouter {
    /// Internal storage for route entries, pairing path prefixes with handlers.
    /// Used to match incoming URLs against registered routes.
    private struct Entry {
        let prefix: String
        let route: TinyRoute
    }
    private var entries: [Entry] = []
    private var defaultRoute: TinyRoute?

    public init() {}

    /// Registers a route instance for a specific path prefix.
    func register(_ prefix: String, _ route: TinyRoute) -> TinyRouter {
        let clean = prefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        entries.append(Entry(prefix: clean, route: route))
        return self
    }

    /// Sets the default route used when no registered routes handle the request.
    /// This route is tried after all registered routes have been attempted.
    func setDefault(_ route: TinyRoute) -> TinyRouter {
        defaultRoute = route
        return self
    }

    /// Routes a URL to the appropriate handler and returns the response.
    /// Throws an error if no route can handle the request, including the default.
    @MainActor
    public func route(_ url: URL) async throws -> TinyHTTPReply {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TinyRouterError.badURL
        }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Check all registered routes for exact or prefix matches
        if let reply = try await handleRegisteredRoutes(for: path, url: url, components: comps) {
            return reply
        }

        // Try the default route if no registered route handled the request
        if let reply = try await defaultRoute?.handle(url: url, components: comps) {
            return reply
        }

        throw TinyRouterError.notFound
    }

    @MainActor
    private func handleRegisteredRoutes(
        for path: String,
        url: URL,
        components: URLComponents
    ) async throws -> TinyHTTPReply? {
        for entry in entries where path == entry.prefix || path.hasPrefix(entry.prefix + "/") {
            if let reply = try await entry.route.handle(url: url, components: components) {
                return reply
            }
        }
        return nil
    }

    /// Convenience method to return an 200 response from some data.
    /// Throws `.badResponse` if the HTTPURLResponse cannot be constructed.
    static func ok(data: Data, contentType: String, url: URL) throws -> TinyHTTPReply {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": contentType]
        )
        guard let httpResponse = response else { throw TinyRouterError.badResponse }
        return TinyHTTPReply(httpResponse: httpResponse, body: data)
    }
}
