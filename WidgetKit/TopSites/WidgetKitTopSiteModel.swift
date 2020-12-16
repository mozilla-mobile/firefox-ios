/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct WidgetKitTopSiteModel: Codable {
    var title: String
    var faviconUrl: String
    var url: URL
    var imageKey: String
    
    static let userDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
    
    static func save(widgetKitTopSites: [WidgetKitTopSiteModel]) {
        userDefaults.removeObject(forKey: PrefsKeys.WidgetKitSimpleTopTab)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(widgetKitTopSites) {
            userDefaults.set(encoded, forKey: PrefsKeys.WidgetKitSimpleTopTab)
        }
    }
    
    static func get() -> [WidgetKitTopSiteModel] {
        if let topSites = userDefaults.object(forKey: PrefsKeys.WidgetKitSimpleTopTab) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let sites = try jsonDecoder.decode([WidgetKitTopSiteModel].self, from: topSites)
                return sites
            }
            catch {
                print("Error occured")
            }
        }
        return [WidgetKitTopSiteModel]()
    }
}
