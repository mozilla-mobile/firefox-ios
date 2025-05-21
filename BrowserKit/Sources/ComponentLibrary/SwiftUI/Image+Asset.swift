// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public extension Image {
    /// Attempts to load `name` from your asset catalog first; if missing, falls back to SF Symbols.
    init(assetOrSymbol name: String, bundle: Bundle? = nil) {
        if let uiImage = UIImage(named: name, in: bundle, compatibleWith: nil) {
            // Found in Assets
            self = Image(uiImage: uiImage)
        } else {
            // Not in Assets → assume an SF Symbol
            self = Image(systemName: name)
        }
    }
}
