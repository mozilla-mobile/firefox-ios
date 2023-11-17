/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core

#if MOZ_CHANNEL_FENNEC
extension EcosiaImport {
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyz"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }

    func testFavorites(num: Int, finished: @escaping (Migration) -> ()) {
        let favs: [Page] = (0..<num).map { _ in
            let tld = EcosiaImport.randomString(length: 10)
            return Page(url: URL(string: "https://\(tld).org")!, title: tld)
        }

        let before = Date()
        EcosiaFavourites.migrate(favs, to: profile) { (result) in
            switch result {
            case .success(let guids):
                assert(guids.count == num)
                let after = Date().timeIntervalSince(before)
                NSLog("ECOSIA: Time to migrate \(num) favorites: \(after) s")
            case .failure:
                break
            }
            finished(Migration())
        }

    }

    static func createTabs(num: Int) -> [Core.Tab] {
       return (0..<num).map { i in
            let url = URL(string: "https://www.google.com/search?q=\(i)")!
            let page = Page(url: url, title: "Title URL \(i)")
            return Core.Tab(page: page)
        }
    }

    func testHistoryLowLevel(num: Int, finished: @escaping (Migration) -> ()) {

        let items = EcosiaImport.mockHistory(days: num, visits: num)
        let before = Date()

        EcosiaHistory.migrate(items, to: profile) { (result) in
            switch result {
            case .success:
                let after = Date().timeIntervalSince(before)
                NSLog("ECOSIA: Time to migrate \(num) history items: \(after) s")
            case .failure:
                break
            }
            finished(Migration())
        }

    }

    func testAllSequentiallyV2(history: Int, favorites: Int, tabs: Int, finished: @escaping (Migration) -> ()) {
        let before = Date()
        testHistoryLowLevel(num: history) { (migration) in
            self.testFavorites(num: favorites) { (migration) in
                let after = Date().timeIntervalSince(before)
                NSLog("ECOSIA: Total time: \(after) s")
            }
        }
    }

}
#endif

extension EcosiaImport {
    static func mockHistory(days: Int, visits: Int) -> [(Date, Core.Page)]  {
        let topSiteUrls = getTopSiteURLs()

        let items: [(Date, Core.Page)] = (0..<days).map { day in
            let now = Date()
            let oneDay = 24 * 60 * 60

            let visitsPerDay: [(Date, Page)] = (0..<visits).map { visit in
                let url = URL(string: topSiteUrls.randomElement()!)!
                let page = Page(url: url, title: url.host ?? url.absoluteString)
                return (Date(timeInterval: -Double(day * oneDay + visit), since: now), page)
            }
            return visitsPerDay
        }.reduce([], +)
        return items
    }

    static func createMigrationData() {
        let history = Core.History()
        let favs = Core.Favourites()

        let items = mockHistory(days: 1000, visits: 50) // 50 different sites in last 1000 days
        history.items = items

        let topSiteUrls = getTopSiteURLs()

        favs.items = (0...1000).map({ _ in
            let url = URL(string: topSiteUrls.randomElement()!)!
            return Page(url: url, title: url.host ?? url.absoluteString)
        })

        Core.User.shared.migrated = false
    }

    class func getTopSiteURLs() -> [String] {

        struct BundledImage: Codable {
            var title: String
            var url: String?
            var image_url: String
            var background_color: String
            var domain: String
        }

        let filePath = Bundle.main.path(forResource: "bundle_sites", ofType: "json")
        let file = try! Data(contentsOf: URL(fileURLWithPath: filePath!))
        let decoded = try! JSONDecoder().decode([BundledImage].self, from: file)
        return decoded.compactMap({$0.url})
    }
}
