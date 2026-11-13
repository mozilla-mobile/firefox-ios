// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Platform independent counterpart of Apple's `BEBrowserDataBookmark`.
/// https://developer.apple.com/documentation/browserkit/bebrowserdatabookmark
public struct BrowserTransferBookmark: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case folder
        case link(URL)
    }

    public let sourceIdentifier: String
    /// `nil` for root level items.
    public let parentIdentifier: String?
    public let kind: Kind
    public let title: String

    public init(sourceIdentifier: String, parentIdentifier: String?, kind: Kind, title: String) {
        self.sourceIdentifier = sourceIdentifier
        self.parentIdentifier = parentIdentifier
        self.kind = kind
        self.title = title
    }

    public init?(sourceIdentifier: String, parentIdentifier: String?, isFolder: Bool, title: String, url: URL?) {
        let kind: Kind
        if isFolder {
            kind = .folder
        } else if let url {
            kind = .link(url)
        } else {
            return nil
        }

        let parentIdentifier = parentIdentifier?.isEmpty == false ? parentIdentifier : nil
        self.init(sourceIdentifier: sourceIdentifier, parentIdentifier: parentIdentifier, kind: kind, title: title)
    }
}
