// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AdServices
import Common

extension AppInfo {

    public static var ecosiaAppVersion: String {
        return applicationBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    private static let hasAttributedAppleSearchDownloadKey = "hasAttributedAppleSearchDownloadKey"

    /// Only available for iOS 14.3 and later (will return nil on earlier versions).
    /// Returns nil after the first time, so that no unwanted new token is generated.
    /// If an error is caught, it will return nil and retry next time it is fetched.
    static var adServicesAttributionToken: String? {
        guard #available(iOS 14.3, *),
                !UserDefaults.standard.bool(forKey: hasAttributedAppleSearchDownloadKey) else {
            return nil
        }
        do {
            let attributionToken = try AAAttribution.attributionToken()
            UserDefaults.standard.set(true, forKey: hasAttributedAppleSearchDownloadKey)
            return attributionToken
        } catch {
            return nil
        }
    }

    public static var installReceipt: String? {

        guard let receiptURL = Bundle.main.appStoreReceiptURL, let receiptData = try? Data(contentsOf: receiptURL) else {
            return nil
        }

        return receiptData.base64EncodedString(options: [])
    }
}
