// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import UIKit
import Shared

var scheme: String {
    return URL.mozInternalScheme
}

func linkToContainingApp(_ urlSuffix: String = "", query: String) -> URL {
    let urlString = "\(scheme)://\(query)\(urlSuffix)"
    return URL(string: urlString, invalidCharacters: false)!
}
