// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Used to setup internal scheme handlers
struct InternalUtil {
    @MainActor
    func setUpInternalHandlers() {
        let responders: [(String, WKInternalSchemeResponse)] =
             [(WKAboutHomeHandler.path, WKAboutHomeHandler()),
              (WKErrorPageHandler.path, WKErrorPageHandler())]
        responders.forEach { (path, responder) in
            WKInternalSchemeHandler.responders[path] = responder
        }
    }
}
