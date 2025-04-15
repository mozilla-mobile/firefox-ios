// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that displays localized text based on a given key.
struct EcosiaText: View {
    /// The key used to retrieve the localized string.
    let key: String.Key
    /// An optional comment that provides additional context for the localization.
    let comment: String

    /// Initializes a new instance of `EcosiaText` with the specified localization key and optional comment.
    ///
    /// - Parameters:
    ///   - key: The key used to retrieve the localized string.
    ///   - comment: An optional comment that provides additional context for the localization. Default is an empty string.
    init(_ key: String.Key, comment: String = "") {
        self.key = key
        self.comment = comment
    }

    var body: some View {
        if let parsed = try? AttributedString(markdown: .localized(key)) {
            Text(parsed)
        } else {
            Text(verbatim: .localized(key))
        }
    }
}
