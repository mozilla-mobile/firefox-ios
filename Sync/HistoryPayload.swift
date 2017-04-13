/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import SwiftyJSON

private let log = Logger.syncLogger

open class HistoryPayload: CleartextPayloadJSON {
    open class func fromJSON(_ json: JSON) -> HistoryPayload? {
        let p = HistoryPayload(json)
        if p.isValid() {
            return p
        }
        return nil
    }

    override open func isValid() -> Bool {
        log.debug("Calling HistoryPayload.isValid()...")
        if !super.isValid() {
            log.debug("HistoryPayload.isValid() -> false")
            return false
        }

        if self["deleted"].bool ?? false {
            log.debug("HistoryPayload.isValid() -> true")
            return true
        }

        log.debug("ID is: " + self.id)
        let result = self["histUri"].string != nil &&      // TODO: validate URI.
                     self["title"].isStringOrNull() &&
                     self["visits"].isArray()
        log.debug("HistoryPayload.isValid() -> " + (result ? "true" : "false"))
        return result
    }

    open func asPlace() -> Place {
        log.debug("Calling HistoryPayload.asPlace()...")

        if !self.isValid() {
            fatalError("HistoryPayload is invalid!")
        }

        let id: GUID = self.id
        log.debug("HistoryPayload.id == " + id)
        let histURI: String = self.histURI
        log.debug("HistoryPayload.histURI == " + histURI)
        let title: String = self.title
        log.debug("HistoryPayload.title == " + title)

        return Place(guid: id, url: histURI, title: title)
    }

    var visits: [Visit] {
        let visits = self["visits"].arrayObject as! [[String: Any]]
        return optFilter(visits.map(Visit.fromJSON))
    }

    fileprivate var histURI: String {
        return self["histUri"].string!
    }

    var historyURI: URL {
        return self.histURI.asURL!
    }

    var title: String {
        return self["title"].string ?? ""
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        if let p = obj as? HistoryPayload {
            if !super.equalPayloads(p) {
                return false
            }

            if p.deleted {
                return self.deleted == p.deleted
            }

            // If either record is deleted, these other fields might be missing.
            // But we just checked, so we're good to roll on.

            if p.title != self.title {
                return false
            }

            if p.historyURI != self.historyURI {
                return false
            }

            // TODO: compare visits.

            return true
        }

        return false
    }
}
