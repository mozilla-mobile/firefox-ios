// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Bundle {
    public static let version = marketing + "." + bundle
    private static let marketing = main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0.20"
    private static let bundle = main.infoDictionary?["CFBundleVersion"] as? String ?? "840"
}
