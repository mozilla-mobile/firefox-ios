/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import Storage
import Shared

final class EcosiaHistory {

    struct Data {
        let domains: [String: Int]
        let sites: [Site: Int]
        let visits: [(SiteVisit, Int)]
    }

    struct Item {
        let index: Int
        let page: Core.Page
        let date: Date
        let site: Site
    }

    static func migrateHighLevel(_ historyItems: [(Date, Core.Page)], to profile: Profile, finished: @escaping (Result<[SiteVisit], EcosiaImport.Failure>) -> ()){

        guard !historyItems.isEmpty else {
            finished(.success([]))
            return
        }

        var errors = [MaybeErrorType]()
        var visits = [SiteVisit]()
        let group = DispatchGroup()

        for entry in historyItems {
            group.enter()

            let site = Site(url: entry.1.url.absoluteString, title: entry.1.title)
            let visit = SiteVisit(site: site, date: entry.0.toMicrosecondTimestamp())

            let success = profile.history.addLocalVisit(visit)
            success.uponQueue(.main) { result in
                switch result {
                case .success:
                    visits.append(visit)
                case .failure(let error):
                    errors.append(error)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if errors.count > 0 {
                finished(.failure(.init(reasons: errors)))
            } else {
                finished(.success(visits))
            }
        }
    }


    static func migrateLowLevel(_ historyItems: [(Date, Core.Page)], to profile: Profile, finished: @escaping (Result<Void, EcosiaImport.Failure>) -> ()){

        guard !historyItems.isEmpty else {
            finished(.success(Void()))
            return
        }

        let data = prepare(history: historyItems)
        guard let history = profile.history as? SQLiteHistory else { return }

        let success = history.storeDomains(data.domains)
            >>> { history.storeSites(data.sites) }
            >>> { history.storeVisits(data.visits) }

        success.uponQueue(.main) { (result) in
            switch result {
            case .success:
                finished(.success(Void()))
            case .failure(let error):
                finished(.failure(.init(reasons: [error])))
            }
        }
    }

    static func prepare(history: [(Date, Core.Page)]) -> EcosiaHistory.Data {
        // extract distinct domains
        var domains = [String: Int]() //unique per domain e.g. ecosia.org + domain_id
        var sites = [Site: Int]() // unique per url e.g. ecosia.org/search?q=foo + domain_id
        var visits = [(SiteVisit, Int)]() // all visitis + site_id

        for item in history {
            guard let domain = item.1.url.normalizedHost, !isIgnoredURL(domain) else { continue }
            var domainIndex: Int
            if let index = domains[domain] {
                domainIndex = index
            } else {
                domainIndex = domains.count + 1
                domains[domain] = domainIndex
            }

            var site: Site
            if let match = sites.first(where: { $0.key.url == item.1.url.absoluteString }) {
                site = match.key
            } else {
                site = Site(url: item.1.url.absoluteString, title: item.1.title)
                site.id = sites.count + 1
                sites[site] = domainIndex
            }

            // add all visits
            let visit = SiteVisit(site: site, date: item.0.toMicrosecondTimestamp())
            visits.append((visit, site.id!))
        }
        return .init(domains: domains, sites: sites, visits: visits)
    }
}
