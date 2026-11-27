// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A Glean ping uploaded by the app and captured by `GleanPingServer`.
struct GleanPing: Sendable {
    /// Ping name taken from the upload path `/submit/<app>/<name>/<version>/<id>`, e.g. `events`.
    let name: String
    let events: [GleanEvent]
    /// The full ping payload, as uploaded by the app.
    let json: Data

    init(path: String, body: Data) throws {
        let components = path.split(separator: "/")
        guard components.count >= 5, components[0] == "submit" else { throw GleanPingParseError.unexpectedPath }
        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: body)
        } catch {
            throw GleanPingParseError.invalidJSON(String(describing: error))
        }
        self.name = String(components[2])
        self.events = payload.events ?? []
        self.json = body
    }

    /// `json` indented with sorted keys, for test report attachments.
    var prettyJSON: Data {
        guard let object = try? JSONSerialization.jsonObject(with: json),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        else { return json }
        return pretty
    }

    private struct Payload: Decodable {
        let events: [GleanEvent]?
    }
}

enum GleanPingParseError: Error, CustomStringConvertible {
    case unexpectedPath
    case invalidJSON(String)

    var description: String {
        switch self {
        case .unexpectedPath:
            return "path isn't /submit/<app>/<ping>/<version>/<id>"
        case .invalidJSON(let detail):
            return "invalid ping JSON: \(detail)"
        }
    }
}

struct GleanEvent: Decodable, Sendable, CustomStringConvertible {
    let category: String
    let name: String
    let extra: [String: String]?

    var description: String {
        "\(category).\(name) \(extra ?? [:])"
    }

    /// Whether this is `category.name` and its extras contain every key/value in `extras`.
    func matches(category: String, name: String, extras: [String: String]) -> Bool {
        guard self.category == category, self.name == name else { return false }
        return extras.allSatisfy { extra?[$0.key] == $0.value }
    }
}
