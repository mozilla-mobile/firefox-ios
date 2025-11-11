// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol BundleConfigurationProviding {
    var baseBundleIdentifier: String? { get }
    var sharedContainerIdentifier: String? { get }
}

struct BundleConfiguration: BundleConfigurationProviding {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    var baseBundleIdentifier: String? {
        guard let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? String,
              let bundleIdentifier = bundle.bundleIdentifier else {
            return nil
        }

        // If this is an extension (XPC!), remove the extension suffix
        guard packageType == "XPC!" else {
            return bundleIdentifier
        }

        let components = bundleIdentifier.components(separatedBy: ".")
        guard components.count > 1 else {
            return bundleIdentifier
        }

        return components.dropLast().joined(separator: ".")
    }

    var sharedContainerIdentifier: String? {
        guard var bundleIdentifier = baseBundleIdentifier else {
            return nil
        }

        // Handle special case for enterprise builds
        if bundleIdentifier == "org.mozilla.ios.FennecEnterprise" {
            bundleIdentifier = "org.mozilla.ios.Fennec.enterprise"
        }

        return "group.\(bundleIdentifier)"
    }
}
