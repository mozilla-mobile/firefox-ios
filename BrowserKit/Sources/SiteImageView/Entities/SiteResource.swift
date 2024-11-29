// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The source of a favicon or hero image.
public enum SiteResource: Codable, Hashable {
    /// An image that may be downloaded over the network.
    /// - Parameter url: The URL of the image.
    case remoteURL(url: URL)
    /// An image bundled in the app in a .xcassets library.
    /// - Parameter name: The name of the image.
    /// - Parameter forRemoteResource: The URL from which this bundled image was obtained. Can be cached for future requests.
    case bundleAsset(name: String, forRemoteResource: URL)

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .remoteURL(url):
            hasher.combine(url)
        case let .bundleAsset(name, forRemoteResource):
            hasher.combine(name)
            hasher.combine(forRemoteResource)
        }
    }
}
