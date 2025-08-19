// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Those extensions are kept public at the moment to avoid breaking any existing code, but ideally
/// in the future we should keep the usage of those extensions internal to the WebEngine only,
/// as the goal is that we only have URL extensions that relates to webview in this file. If they
/// cannot be internal then we should move the ones that needs to be public to the Common package.
/// This will be done with FXIOS-7960
public extension URL {
    func encodeReaderModeURL(_ baseReaderModeURL: String) -> URL? {
        if let encodedURL = absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            if let aboutReaderURL = URL(string: "\(baseReaderModeURL)?url=\(encodedURL)") {
                return aboutReaderURL
            }
        }
        return nil
    }
}
