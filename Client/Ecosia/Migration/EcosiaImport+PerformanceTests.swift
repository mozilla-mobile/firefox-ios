/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core

#if MOZ_CHANNEL_FENNEC
extension EcosiaImport {
    func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyz"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }

    func mockHistory(num: Int) -> [(Date, Core.Page)]  {
        let now = Date()
        let items: [(Date, Core.Page)] = (0..<num).map { _ in
            let tld = randomString(length: 10)
            let page = Page(url: URL(string: "https://\(tld).org")!, title: tld)
            let date = Date(timeInterval: -Double(num), since: now)
            return ((date , page))
        }
        return items
    }

    func testFavorites(num: Int, finished: @escaping (Migration) -> ()) {
        let favs: [Page] = (0..<num).map { _ in
            let tld = randomString(length: 10)
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

    func testTabs(num: Int, finished: @escaping (Migration) -> ()) {
        let urls: [URL] = (0..<num).map { _ in
            let tld = randomString(length: 10)
            return URL(string: "https://\(tld).org")!
        }

        let before = Date()
        EcosiaTabs.migrate(urls, to: tabManager) { (result) in
            switch result {
            case .success(let guids):
                assert(guids.count == num)
                let after = Date().timeIntervalSince(before)
                NSLog("ECOSIA: Time to migrate \(num) Tabs: \(after) s")
            case .failure:
                break
            }
            finished(Migration())
        }

    }

    func testHistoryHighLevel(num: Int, finished: @escaping (Migration) -> ()) {

        let items = mockHistory(num: num)
        let before = Date()

        EcosiaHistory.migrateHighLevel(items, to: profile) { (result) in
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

    func testHistoryLowLevel(num: Int, finished: @escaping (Migration) -> ()) {

        let items = mockHistory(num: num)
        let before = Date()

        EcosiaHistory.migrateLowLevel(items, to: profile) { (result) in
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

    func testAllSequentiallyV1(history: Int, favorites: Int, tabs: Int, finished: @escaping (Migration) -> ()) {
        let before = Date()


        testHistoryHighLevel(num: history) { (migration) in
            self.testFavorites(num: favorites) { (migration) in
                self.testTabs(num: tabs) { (migration) in
                    let after = Date().timeIntervalSince(before)
                    NSLog("ECOSIA: Total time: \(after) s")
                }
            }
        }
    }

    func testAllSequentiallyV2(history: Int, favorites: Int, tabs: Int, finished: @escaping (Migration) -> ()) {
        let before = Date()


        testHistoryLowLevel(num: history) { (migration) in
            self.testFavorites(num: favorites) { (migration) in
                self.testTabs(num: tabs) { (migration) in
                    let after = Date().timeIntervalSince(before)
                    NSLog("ECOSIA: Total time: \(after) s")
                }
            }
        }
    }

}
#endif
