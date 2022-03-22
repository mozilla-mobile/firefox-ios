/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct Metadata: Codable {
    public let title: String?
    public let language: String?
    public let url: String
    public let provider: String?
    public let icon: String?
}
