// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum SessionErrors: Error {
    case dataUnavailable
}

/// A protocol serving as a wrapper on URLSession to provide
/// async/await functionality for ios 13 & 14, but still leaving
/// room for each feature to implement its own networking module
/// to meet its specific needs
protocol Networking {
    func data(from url: URL) async throws -> (Data, URLResponse)
}
