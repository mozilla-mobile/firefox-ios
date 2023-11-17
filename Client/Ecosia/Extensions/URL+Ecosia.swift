// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

extension URL {

    public var isHTTPS: Bool {
        scheme == "https"
    }
    
    /// This computed var is utilized to determine whether a Website is considered secure from the Ecosia's perspective
    /// We use it mainly to define the UI that tells the user that the currently visited website is secure
    /// When the URL page isn't loaded properly for some reason, we still lookup the website that is being loaded, and determine its security
    /// so the end user alway have an idea of the website being loaded shown in the URL bar and avoid any UI misalignment showing the `warning` icon for a secure website
    /// having issues to load
    /// In case at least one of the flags evaluates to `true`, we consider the URL secure.
    public var isSecure: Bool {
        let isOriginalUrlFromErrorPageSecure = InternalURL(self)?.originalURLFromErrorPage?.isHTTPS == true
        let internalUrlIsNotErrorPage = InternalURL(self)?.isErrorPage == false
        let securityFlags = [isOriginalUrlFromErrorPageSecure, internalUrlIsNotErrorPage, isHTTPS, isReaderModeURL]
        return securityFlags.first(where: { $0 == true }) ?? false
    }
}
