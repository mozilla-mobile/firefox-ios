/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

public class HistoryPayload: CleartextPayloadJSON {
    public class func fromJSON(json: JSON) -> HistoryPayload? {
        let p = HistoryPayload(json)
        if p.isValid() {
            return p
        }
        return nil
    }

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if self["deleted"].asBool ?? false {
            return true
        }

        return self["histUri"].isString &&      // TODO: validate URI.
               self["title"].isStringOrNull &&
               self["visits"].isArray
    }

    public func asPlace() -> Place {
        return Place(guid: self.id, url: self.histURI, title: self.title)
    }

    var visits: [Visit] {
        return optFilter(self["visits"].asArray!.map(Visit.fromJSON))
    }

    private var histURI: String {
        return self["histUri"].asString!
    }

    var historyURI: NSURL {
        return self.histURI.asURL!
    }

    var title: String {
        return self["title"].asString ?? ""
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
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
