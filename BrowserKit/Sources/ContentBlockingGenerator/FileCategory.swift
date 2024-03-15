// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Those are the raw files taken as input for this script
enum FileCategory: String {
    case advertising
    case analytics
    case content
    case cryptomining
    case entity
    case fingerprinting
    case social

    func getPath(inputDirectory: String) -> String {
        return "\(inputDirectory)/\(location)"
    }

    private var location: String {
        switch self {
        case .advertising:
            return "normalized-lists/ads-track-digest256.json"
        case .analytics:
            return "normalized-lists/analytics-track-digest256.json"
        case .content:
            return "normalized-lists/content-track-digest256.json"
        case .cryptomining:
            return "normalized-lists/base-cryptomining-track-digest256.json"
        case .entity:
            return "disconnect-entitylist.json"
        case .fingerprinting:
            return "normalized-lists/base-fingerprinting-track-digest256.json"
        case .social:
            return "normalized-lists/social-track-digest256.json"
        }
    }

    func getOutputFile(outputDirectory: String, actionType: ActionType) -> String {
        return "\(outputDirectory)/disconnect-\(actionType.rawValue)-\(rawValue).json"
    }
}
