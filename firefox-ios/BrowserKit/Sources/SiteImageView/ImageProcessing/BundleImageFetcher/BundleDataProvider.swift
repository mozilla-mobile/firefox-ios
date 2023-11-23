// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol BundleDataProvider {
    func getBundleData() throws -> Data

    func getPath(from path: String) -> String?

    func getBundleImage(from path: String) -> UIImage?
}

class DefaultBundleDataProvider: BundleDataProvider {
    enum BundleDataError: Error {
        case noPath
    }

    func getBundleData() throws -> Data {
        guard let path = bundle.path(forResource: "bundle_sites", ofType: "json") else {
            throw BundleDataError.noPath
        }

        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func getPath(from path: String) -> String? {
        return Bundle.main.path(forResource: "TopSites/" + path, ofType: "png")
    }

    func getBundleImage(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
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
}
