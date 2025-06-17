/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum OAuthScope {
    // Necessary to fetch a profile.
    public static let profile: String = "profile"
    // Necessary to obtain sync keys.
    public static let oldSync: String = "https://identity.mozilla.com/apps/oldsync"
    // Necessary to obtain a sessionToken, which gives full access to the account.
    public static let session: String = "https://identity.mozilla.com/tokens/session"
}
