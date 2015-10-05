/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sync
import XCTest

private let log = Logger.syncLogger

private func optTimestamp(x: AnyObject?) -> Timestamp? {
    guard let str = x as? String else {
        return nil
    }
    return decimalSecondsStringToTimestamp(str)
}

private func optStringArray(x: AnyObject?) -> [String]? {
    guard let str = x as? String else {
        return nil
    }
    return str.componentsSeparatedByString(",").map { $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) }
}

// TODO: flesh out.
private struct SyncRequestSpec {
    let collection: String
    let id: String?
    let ids: [String]?
    let limit: Int?
    let offset: String?
    let sort: SortOption?
    let newer: Timestamp?
    let full: Bool

    static func fromRequest(request: GCDWebServerRequest) -> SyncRequestSpec? {
        // Input is "/1.5/user/storage/collection", possibly with "/id" at the end.
        // That means we get five or six path components here, the first being empty.

        let parts = request.path!.componentsSeparatedByString("/").filter { !$0.isEmpty }
        let id: String?
        let ids = optStringArray(request.query["ids"])
        let newer = optTimestamp(request.query["newer"])
        let full: Bool = request.query["full"] != nil

        let limit: Int?
        if let lim = request.query["limit"] as? String {
            limit = Int(lim)
        } else {
            limit = nil
        }

        let offset = request.query["offset"] as? String

        let sort: SortOption?
        switch request.query["sort"] as? String ?? "" {
        case "newest":
            sort = SortOption.Newest
        case "index":
            sort = SortOption.Index
        default:
            sort = nil
        }

        if parts.count < 4 {
            return nil
        }

        // Use dropFirst, you say! It's buggy.
        switch parts.count {
        case 4:
            id = nil
        case 5:
            id = parts[4]
        default:
            // Uh oh.
            return nil
        }
        return SyncRequestSpec(collection: parts[3], id: id, ids: ids, limit: limit, offset: offset, sort: sort, newer: newer, full: full)
    }
}

class MockSyncServer {
    let server = GCDWebServer()
    let username: String

    var offsets: Int = 0
    var continuations: [String: [EnvelopeJSON]] = [:]
    var collections: [String: [String: EnvelopeJSON]] = [:]
    var baseURL: String!

    init(username: String) {
        self.username = username
    }

    class func makeValidEnvelope(guid: GUID, modified: Timestamp) -> EnvelopeJSON {
        let clientBody: [String: AnyObject] = [
            "id": guid,
            "name": "Foobar",
            "commands": [],
            "type": "mobile",
        ]
        let clientBodyString = JSON(clientBody).toString(false)
        let clientRecord: [String : AnyObject] = [
            "id": guid,
            "collection": "clients",
            "payload": clientBodyString,
            "modified": Double(modified) / 1000,
        ]
        return EnvelopeJSON(JSON(clientRecord).toString(false))
    }

    func storeRecords(records: [EnvelopeJSON], inCollection collection: String) {
        var out = self.collections[collection] ?? [:]
        records.forEach { out[$0.id] = $0 }
        self.collections[collection] = out
    }

    private func splitArray<T>(items: [T], at: Int) -> ([T], [T]) {
        return (Array(items.dropLast(items.count - at)), Array(items.dropFirst(at)))
    }

    private func recordsMatchingSpec(spec: SyncRequestSpec) -> (records: [EnvelopeJSON], offsetID: String?)? {
        // If we have a provided offset, handle that directly.
        if let offset = spec.offset {
            log.debug("Got provided offset \(offset).")
            guard let remainder = self.continuations[offset] else {
                log.error("Unknown offset.")
                return nil
            }

            // Remove the old one.
            self.continuations.removeValueForKey(offset)

            // Handle the smaller-than-limit or no-provided-limit cases.
            guard let limit = spec.limit where limit < remainder.count else {
                log.debug("Returning all remaining items.")
                return (remainder, nil)
            }

            // Record the next continuation and return the first slice of records.
            let next = "\(self.offsets++)"
            let (returned, remaining) = splitArray(remainder, at: limit)
            self.continuations[next] = remaining
            log.debug("Returning \(limit) items; next continuation is \(next).")
            return (returned, next)
        }

        guard let records = self.collections[spec.collection]?.values else {
            // No matching records.
            return ([], nil)
        }

        var items = Array(records)
        log.debug("Got \(items.count) candidate records.")

        if spec.newer ?? 0 > 0 {
            items = items.filter { $0.modified > spec.newer }
        }

        if let ids = spec.ids {
            let ids = Set(ids)
            items = items.filter { ids.contains($0.id) }
        }

        if let sort = spec.sort {
            switch sort {
            case SortOption.Newest:
                items.sortInPlace { $0.modified < $1.modified }
            case SortOption.Index:
                log.warning("Index sorting not yet supported.")
            }
        }

        log.debug("Sorted items: \(items)")

        if let limit = spec.limit where items.count > limit {
            let next = "\(self.offsets++)"
            let (returned, remaining) = splitArray(items, at: limit)
            self.continuations[next] = remaining
            return (returned, next)
        }

        return (items, nil)
    }

    func start() {
        let basePath = "/1.5/\(self.username)/"
        let storagePath = "\(basePath)storage/"

        let match: GCDWebServerMatchBlock = { method, url, headers, path, query -> GCDWebServerRequest! in
            guard method == "GET" && path.startsWith(storagePath) else {
                return nil
            }
            return GCDWebServerRequest(method: method, url: url, headers: headers, path: path, query: query)
        }

        server.addHandlerWithMatchBlock(match) { (request) -> GCDWebServerResponse! in
            // 1. Decide what the URL is asking for. It might be a collection fetch or
            //    an individual record, and it might have query parameters.

            guard let spec = SyncRequestSpec.fromRequest(request) else {
                return GCDWebServerDataResponse(statusCode: 400)
            }

            // 2. Grab the matching set of records. Prune based on TTL, exclude with X-I-U-S, etc.
            if spec.id != nil {
                return GCDWebServerDataResponse(statusCode: 500)
            }

            guard let (items, offset) = self.recordsMatchingSpec(spec) else {
                // Unable to find the provided offset.
                return GCDWebServerDataResponse(statusCode: 400)
            }

            // TODO: TTL
            // TODO: X-I-U-S

            let body = JSON(items.map { $0.asJSON() }).toString()
            let bodyData = body.utf8EncodedData
            let response = GCDWebServerDataResponse(data: bodyData, contentType: "application/json")

            // 3. Compute the correct set of headers: timestamps, X-Weave-Records, etc.

            let xLastModified = millisecondsToDecimalSeconds(items.reduce(Timestamp(0)) { max($0, $1.modified) })
            response.setValue("\(xLastModified)", forAdditionalHeader: "X-Last-Modified")

            let xWeaveTimestamp = millisecondsToDecimalSeconds(NSDate.now())
            response.setValue("\(xWeaveTimestamp)", forAdditionalHeader: "X-Weave-Timestamp")

            response.setValue("\(items.count)", forAdditionalHeader: "X-Weave-Records")

            if let offset = offset {
                response.setValue(offset, forAdditionalHeader: "X-Weave-Next-Offset")
            }

            return response
        }

        if server.startWithPort(0, bonjourName: nil) == false {
            XCTFail("Can't start the GCDWebServer.")
        }

        baseURL = "http://localhost:\(server.port)\(basePath)"
    }
}
