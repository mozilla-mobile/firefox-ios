/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
/*
 Workaround to make assets available for other packages.
 
 https://forums.swift.org/t/unable-to-find-bundle-in-package-target-tests-when-package-depends-on-another-package-containing-resources-accessed-via-bundle-module/43974
 */
import Foundation

private class CurrentBundleFinder {}

extension Foundation.Bundle {

    static var myModule: Bundle = {

        // Name of the target
        let bundleName = "DesignSystem_DesignSystem"
        // Name of Package prefixed by LocalPackages_
        let localBundleName = "LocalPackages_Focus"

        let candidates = [
            /* Bundle should be present here when the package is linked into an App. */
            Bundle.main.resourceURL,

            /* Bundle should be present here when the package is linked into a framework. */
            Bundle(for: CurrentBundleFinder.self).resourceURL,

            /* For command-line tools. */
            Bundle.main.bundleURL,

            /* Bundle should be present here when running previews from a different package (this is the path to "…/Debug-iphonesimulator/"). */
            Bundle(for: CurrentBundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
            Bundle(for: CurrentBundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent()
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }

            let localBundlePath = candidate?.appendingPathComponent(localBundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        return .module

    }()

}
