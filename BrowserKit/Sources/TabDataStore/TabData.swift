// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

struct TabData: Codable {
    let id: UUID
    let title: String
    let siteUrl: String
    let faviconURL: String
    let isPrivate: Bool
    let lastUsedTime: Date
    let createdAtTime: Date
}
