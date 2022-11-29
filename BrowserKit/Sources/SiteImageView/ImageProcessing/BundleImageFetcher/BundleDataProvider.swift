// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

protocol BundleDataProvider {
    func getBundleData() throws -> Data
}

class DefaultBundleDataProvider: BundleDataProvider {

    enum BundleError: Error {
        case noPath
    }

    private var bundle: Bundle {
        var bundle = Bundle.main
        // Allows us to access bundle from extensions
        // Taken from: https://stackoverflow.com/questions/26189060/get-the-main-app-bundle-from-within-extension
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let otherBundle = Bundle(url: url) {
                bundle = otherBundle
            }
        }
        return bundle
    }

    func getBundleData() throws -> Data {
        guard let path = bundle.path(forResource: "top_sites", ofType: "json") else {
            throw BundleError.noPath
        }

        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
}
