/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Sync

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
        case "oldest":
            sort = SortOption.OldestFirst
        case "newest":
            sort = SortOption.NewestFirst
        case "index":
            sort = SortOption.Index
        default:
            sort = nil
        }

        if parts.count < 4 {
            return nil
        }

        if parts[2] != "storage" {
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

struct SyncDeleteRequestSpec {
    let collection: String?
    let id: GUID?
    let ids: [GUID]?
    let wholeCollection: Bool

    static func fromRequest(request: GCDWebServerRequest) -> SyncDeleteRequestSpec? {
        // Input is "/1.5/user{/storage{/collection{/id}}}".
        // That means we get four, five, or six path components here, the first being empty.
        return SyncDeleteRequestSpec.fromPath(request.path!, withQuery: request.query)
    }

    static func fromPath(path: String, withQuery query: [NSObject: AnyObject]) -> SyncDeleteRequestSpec? {
        let parts = path.componentsSeparatedByString("/").filter { !$0.isEmpty }
        let queryIDs: [GUID]? = (query["ids"] as? String)?.componentsSeparatedByString(",")

        guard [2, 4, 5].contains(parts.count) else {
            return nil
        }

        if parts.count == 2 {
            return SyncDeleteRequestSpec(collection: nil, id: nil, ids: queryIDs, wholeCollection: true)
        }

        if parts[2] != "storage" {
            return nil
        }

        if parts.count == 4 {
            let hasIDs = queryIDs != nil
            return SyncDeleteRequestSpec(collection: parts[3], id: nil, ids: queryIDs, wholeCollection: !hasIDs)
        }

        return SyncDeleteRequestSpec(collection: parts[3], id: parts[4], ids: queryIDs, wholeCollection: false)
    }
}

private struct SyncPutRequestSpec {
    let collection: String
    let id: String

    static func fromRequest(request: GCDWebServerRequest) -> SyncPutRequestSpec? {
        // Input is "/1.5/user/storage/collection/id}}}".
        // That means we get six path components here, the first being empty.

        let parts = request.path!.componentsSeparatedByString("/").filter { !$0.isEmpty }

        guard parts.count == 5 else {
            return nil
        }

        if parts[2] != "storage" {
            return nil
        }

        return SyncPutRequestSpec(collection: parts[3], id: parts[4])
    }
}

class MockSyncServer {
    let server = GCDWebServer()
    let username: String

    var offsets: Int = 0
    var continuations: [String: [EnvelopeJSON]] = [:]
    var collections: [String: (modified: Timestamp, records: [String: EnvelopeJSON])] = [:]
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

    class func withHeaders(response: GCDWebServerResponse, lastModified: Timestamp? = nil, records: Int? = nil, timestamp: Timestamp? = nil) -> GCDWebServerResponse {
        let timestamp = timestamp ?? NSDate.now()
        let xWeaveTimestamp = millisecondsToDecimalSeconds(timestamp)
        response.setValue("\(xWeaveTimestamp)", forAdditionalHeader: "X-Weave-Timestamp")

        if let lastModified = lastModified {
            let xLastModified = millisecondsToDecimalSeconds(lastModified)
            response.setValue("\(xLastModified)", forAdditionalHeader: "X-Last-Modified")
        }

        if let records = records {
            response.setValue("\(records)", forAdditionalHeader: "X-Weave-Records")
        }

        return response;
    }

    func storeRecords(records: [EnvelopeJSON], inCollection collection: String, now: Timestamp? = nil) {
        let now = now ?? NSDate.now()
        let coll = self.collections[collection]
        var out = coll?.records ?? [:]
        records.forEach {
            out[$0.id] = $0.withModified(now)
        }
        let newModified = max(now, coll?.modified ?? 0)
        self.collections[collection] = (modified: newModified, records: out)
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

        guard let records = self.collections[spec.collection]?.records.values else {
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
            case SortOption.NewestFirst:
                items = items.sort { $0.modified > $1.modified }
                log.debug("Sorted items newest first: \(items.map { $0.modified })")
            case SortOption.OldestFirst:
                items = items.sort { $0.modified < $1.modified }
                log.debug("Sorted items oldest first: \(items.map { $0.modified })")
            case SortOption.Index:
                log.warning("Index sorting not yet supported.")
            }
        }

        if let limit = spec.limit where items.count > limit {
            let next = "\(self.offsets++)"
            let (returned, remaining) = splitArray(items, at: limit)
            self.continuations[next] = remaining
            return (returned, next)
        }

        return (items, nil)
    }

    private func recordResponse(record: EnvelopeJSON) -> GCDWebServerResponse {
        let body = JSON(record.asJSON()).toString()
        let bodyData = body.utf8EncodedData
        let response = GCDWebServerDataResponse(data: bodyData, contentType: "application/json")
        return MockSyncServer.withHeaders(response, lastModified: record.modified)
    }

    private func modifiedResponse(timestamp: Timestamp) -> GCDWebServerResponse {
        let body = JSON(["modified": NSNumber(unsignedLongLong: timestamp)]).toString()
        let bodyData = body.utf8EncodedData
        let response = GCDWebServerDataResponse(data: bodyData, contentType: "application/json")
        return MockSyncServer.withHeaders(response)
    }

    func modifiedTimeForCollection(collection: String) -> Timestamp? {
        return self.collections[collection]?.modified
    }

    func removeAllItemsFromCollection(collection: String, atTime: Timestamp) {
        if self.collections[collection] != nil {
            self.collections[collection] = (atTime, [:])
        }
    }

    func start() {
        let basePath = "/1.5/\(self.username)"
        let storagePath = "\(basePath)/storage/"

        let infoCollectionsPath = "\(basePath)/info/collections"
        server.addHandlerForMethod("GET", path: infoCollectionsPath, requestClass: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse! in
            var ic = [String: NSNumber]()
            var lastModified: Timestamp = 0
            for collection in self.collections.keys {
                if let timestamp = self.modifiedTimeForCollection(collection) {
                    ic[collection] = NSNumber(double: Double(timestamp) / 1000)
                    lastModified = max(lastModified, timestamp)
                }

            }
            let body = JSON(ic).toString()
            let bodyData = body.utf8EncodedData

            let response = GCDWebServerDataResponse(data: bodyData, contentType: "application/json")
            return MockSyncServer.withHeaders(response, lastModified: lastModified, records: ic.count)
        }

        let matchPut: GCDWebServerMatchBlock = { method, url, headers, path, query -> GCDWebServerRequest! in
            guard method == "PUT" && path.startsWith(basePath) else {
                return nil
            }
            return GCDWebServerDataRequest(method: method, url: url, headers: headers, path: path, query: query)
        }

        server.addHandlerWithMatchBlock(matchPut) { (request) -> GCDWebServerResponse! in
            guard let request = request as? GCDWebServerDataRequest else {
                return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 400))
            }

            guard let spec = SyncPutRequestSpec.fromRequest(request) else {
                return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 400))
            }

            var body = JSON(request.jsonObject).asDictionary!
            body["modified"] = JSON(millisecondsToDecimalSeconds(NSDate.now()))
            let record = EnvelopeJSON(JSON(body))

            self.storeRecords([record], inCollection: spec.collection)
            let timestamp = self.modifiedTimeForCollection(spec.collection)!

            let response = GCDWebServerDataResponse(data: millisecondsToDecimalSeconds(timestamp).utf8EncodedData, contentType: "application/json")
            return MockSyncServer.withHeaders(response)
        }

        let matchDelete: GCDWebServerMatchBlock = { method, url, headers, path, query -> GCDWebServerRequest! in
            guard method == "DELETE" && path.startsWith(basePath) else {
                return nil
            }
            return GCDWebServerRequest(method: method, url: url, headers: headers, path: path, query: query)
        }

        server.addHandlerWithMatchBlock(matchDelete) { (request) -> GCDWebServerResponse! in
            guard let spec = SyncDeleteRequestSpec.fromRequest(request) else {
                return GCDWebServerDataResponse(statusCode: 400)
            }

            if let collection = spec.collection, id = spec.id {
                guard var items = self.collections[collection]?.records else {
                    // Unable to find the requested collection.
                    return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 404))
                }

                guard let item = items[id] else {
                    // Unable to find the requested id.
                    return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 404))
                }
                items.removeValueForKey(id)
                return self.modifiedResponse(item.modified)
            }

            if let collection = spec.collection {
                if spec.wholeCollection {
                    self.collections.removeValueForKey(collection)
                } else {
                    if let ids = spec.ids,
                       var map = self.collections[collection]?.records {
                            for id in ids {
                                map.removeValueForKey(id)
                            }
                            self.collections[collection] = (modified: NSDate.now(), records: map)
                    }
                }
                return self.modifiedResponse(NSDate.now())
            }

            self.collections = [:]
            return MockSyncServer.withHeaders(GCDWebServerDataResponse(data: "{}".utf8EncodedData, contentType: "application/json"))
        }

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
                return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 400))
            }

            // 2. Grab the matching set of records. Prune based on TTL, exclude with X-I-U-S, etc.
            if let id = spec.id {
                guard let collection = self.collections[spec.collection], record = collection.records[id] else {
                    // Unable to find the requested collection/id.
                    return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 404))
                }

                return self.recordResponse(record)
            }

            guard let (items, offset) = self.recordsMatchingSpec(spec) else {
                // Unable to find the provided offset.
                return MockSyncServer.withHeaders(GCDWebServerDataResponse(statusCode: 400))
            }

            // TODO: TTL
            // TODO: X-I-U-S

            let body = JSON(items.map { $0.asJSON() }).toString()
            let bodyData = body.utf8EncodedData
            let response = GCDWebServerDataResponse(data: bodyData, contentType: "application/json")

            // 3. Compute the correct set of headers: timestamps, X-Weave-Records, etc.
            if let offset = offset {
                response.setValue(offset, forAdditionalHeader: "X-Weave-Next-Offset")
            }

            let timestamp = self.modifiedTimeForCollection(spec.collection)!
            log.debug("Returning GET response with X-Last-Modified for \(items.count) records: \(timestamp).")
            return MockSyncServer.withHeaders(response, lastModified: timestamp, records: items.count)
        }

        if server.startWithPort(0, bonjourName: nil) == false {
            XCTFail("Can't start the GCDWebServer.")
        }

        baseURL = "http://localhost:\(server.port)\(basePath)"
    }
}
