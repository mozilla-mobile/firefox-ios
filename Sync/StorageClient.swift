/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import Account

public class ServerResponseError<T>: ErrorType {
    public let response: StorageResponse<T>

    public init(_ response: StorageResponse<T>) {
        self.response = response
    }

    public var description: String {
        return "Error."
    }
}

public class RequestError: ErrorType {
    public let error: NSError?

    public init(_ err: NSError?) {
        self.error = err
    }

    public var description: String {
        let str = self.error?.localizedDescription ?? "No description"
        return "Request error: \(str)."
    }
}

public class BadRequestError<T>: ServerResponseError<T> {
    public let request: NSURLRequest

    public init(request: NSURLRequest, response: StorageResponse<T>) {
        self.request = request
        super.init(response)
    }

    override public var description: String {
        return "Bad request."
    }
}

public class ServerError<T>: ServerResponseError<T> {
    override public var description: String {
        return "Server error."
    }

    override public init(_ response: StorageResponse<T>) {
        super.init(response)
    }
}

public class RecordParseError : ErrorType {
    public var description: String {
        return "Failed to parse record."
    }
}

// Returns milliseconds. Handles decimals.
private func optionalSecondsHeader(input: AnyObject?) -> Int64? {
    if input == nil {
        return nil
    }

    if let val = input as? String {
        if let double = NSScanner(string: val).scanDouble() {
            return Int64(double * 1000)
        }
    }

    if let seconds: Double = input as? Double {
        // Oh for a BigDecimal library.
        return Int64(seconds * 1000)
    }

    if let seconds: NSNumber = input as? NSNumber {
        // Who knows.
        return seconds.longLongValue * 1000
    }

    return nil
}

private func optionalIntegerHeader(input: AnyObject?) -> Int64? {
    if input == nil {
        return nil
    }

    if let val = input as? String {
        return NSScanner(string: val).scanLongLong()
    }

    if let val: Double = input as? Double {
        // Oh for a BigDecimal library.
        return Int64(val)
    }

    if let val: NSNumber = input as? NSNumber {
        // Who knows.
        return val.longLongValue
    }

    return nil
}

public struct ResponseMetadata {
    public let alert: String?
    public let nextOffset: String?
    public let records: Int64?
    public let quotaRemaining: Int64?
    public let timestampMilliseconds: Int64                    // Non-optional.
    public let lastModifiedMilliseconds: Int64?                // Included for all success responses.
    public let backoffMilliseconds: Int64?
    public let retryAfterMilliseconds: Int64?

    public init(response: NSHTTPURLResponse) {
        self.init(headers: response.allHeaderFields)
    }

    public init(headers: [NSObject : AnyObject]) {
        alert = headers["X-Weave-Alert"] as? String
        nextOffset = headers["X-Weave-Next-Offset"] as? String
        records = optionalIntegerHeader(headers["X-Weave-Records"])
        quotaRemaining = optionalIntegerHeader(headers["X-Weave-Quota-Remaining"])
        timestampMilliseconds = optionalSecondsHeader(headers["X-Weave-Timestamp"]) ?? -1
        lastModifiedMilliseconds = optionalSecondsHeader(headers["X-Last-Modified"])
        backoffMilliseconds = optionalSecondsHeader(headers["X-Weave-Backoff"]) ??
                              optionalSecondsHeader(headers["X-Backoff"])
        retryAfterMilliseconds = optionalSecondsHeader(headers["Retry-After"])
    }
}

public struct StorageResponse<T> {
    public let value: T
    public let metadata: ResponseMetadata

    init(value: T, metadata: ResponseMetadata) {
        self.value = value
        self.metadata = metadata
    }

    init(value: T, response: NSHTTPURLResponse) {
        self.value = value
        self.metadata = ResponseMetadata(response: response)
    }
}

public typealias Authorizer = (NSMutableURLRequest) -> NSMutableURLRequest
public typealias ResponseHandler = (NSURLRequest, NSHTTPURLResponse?, AnyObject?, NSError?) -> Void

private func errorWrap<T>(deferred: Deferred<Result<T>>, handler: ResponseHandler) -> ResponseHandler {
    return { (request, response, data, error) in
        println("Response is \(response), data is \(data)")

        if let error = error {
            println("Got error.")
            deferred.fill(Result<T>(failure: RequestError(error)))
            return
        }

        if response == nil {
            // TODO: better error.
            println("No response")
            let result = Result<T>(failure: RecordParseError())
            deferred.fill(result)
            return
        }

        println("Status code: \(response!.statusCode)")
        if response!.statusCode >= 500 {
            let err = StorageResponse(value: response!, metadata: ResponseMetadata(response: response!))
            let result = Result<T>(failure: ServerError(err))
            deferred.fill(result)
            return
        }

        if response!.statusCode >= 400 {
            let err = StorageResponse(value: response!, metadata: ResponseMetadata(response: response!))
            let result = Result<T>(failure: BadRequestError(request: request, response: err))
            deferred.fill(result)
            return
        }

        handler(request, response, data, error)
    }
}

// Don't forget to batch downloads.
public class Sync15StorageClient {
    private let authorizer: Authorizer
    private let serverURI: NSURL

    let workQueue: dispatch_queue_t
    let resultQueue: dispatch_queue_t

    public init(token: TokenServerToken, workQueue: dispatch_queue_t, resultQueue: dispatch_queue_t) {
        self.workQueue = workQueue
        self.resultQueue = resultQueue

        // This is a potentially dangerous assumption, but failable initializers up the stack are a giant pain.
        self.serverURI = NSURL(string: token.api_endpoint)!
        self.authorizer = {
            (r: NSMutableURLRequest) -> NSMutableURLRequest in
            let helper = HawkHelper(id: token.id, key: token.key.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
            r.addValue(helper.getAuthorizationValueFor(r), forHTTPHeaderField: "Authorization")
            return r
        }
    }

    public init(serverURI: NSURL, authorizer: Authorizer, workQueue: dispatch_queue_t, resultQueue: dispatch_queue_t) {
        self.serverURI = serverURI
        self.authorizer = authorizer
        self.workQueue = workQueue
        self.resultQueue = resultQueue
    }

    func requestGET(url: NSURL) -> Request {
        let req = NSMutableURLRequest(URL: url)
        req.HTTPMethod = Method.GET.rawValue
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        let authorized: NSMutableURLRequest = self.authorizer(req)
        return Alamofire.request(authorized)
                        .validate(contentType: ["application/json"])
    }

    func requestDELETE(url: NSURL) -> Request {
        let req = NSMutableURLRequest(URL: url)
        req.HTTPMethod = Method.DELETE.rawValue
        req.addValue("1", forHTTPHeaderField: "X-Confirm-Delete")
        let authorized: NSMutableURLRequest = self.authorizer(req)
        return Alamofire.request(authorized)
    }

    private func doOp<T>(op: (NSURL) -> Request, path: String, f: (JSON) -> T?) -> Deferred<Result<StorageResponse<T>>> {
        let deferred = Deferred<Result<StorageResponse<T>>>(defaultQueue: self.resultQueue)
        let req = op(self.serverURI.URLByAppendingPathComponent(path))
        req.responseParsedJSON(errorWrap(deferred, { (_, response, data, error) in
            if let json: JSON = data as? JSON {
                if let v = f(json) {
                    let storageResponse = StorageResponse<T>(value: v, response: response!)
                    deferred.fill(Result(success: storageResponse))
                } else {
                    deferred.fill(Result(failure: RecordParseError()))
                }
                return
            }

            deferred.fill(Result(failure: RecordParseError()))
        }))

        return deferred
    }

    private func getResource<T>(path: String, f: (JSON) -> T?) -> Deferred<Result<StorageResponse<T>>> {
        return doOp(self.requestGET, path: path, f)
    }

    private func deleteResource<T>(path: String, f: (JSON) -> T?) -> Deferred<Result<StorageResponse<T>>> {
        return doOp(self.requestDELETE, path: path, f)
    }

    func getInfoCollections() -> Deferred<Result<StorageResponse<InfoCollections>>> {
        return getResource("info/collections", InfoCollections.fromJSON)
    }

    func getMetaGlobal() -> Deferred<Result<StorageResponse<GlobalEnvelope>>> {
        return getResource("storage/meta/global", { GlobalEnvelope($0) })
    }

    func wipeStorage() -> Deferred<Result<StorageResponse<JSON>>> {
        // In Sync 1.5 it's preferred that we delete the root, not /storage.
        return deleteResource("", { $0 })
    }

    // TODO: it would be convenient to have the storage client manage Keys,
    // but of course we need to use a different set of keys to fetch crypto/keys
    // itself.
    func collectionClient<T: CleartextPayloadJSON>(collection: String, factory: (String) -> T?) -> Sync15CollectionClient<T> {
        let storage = self.serverURI.URLByAppendingPathComponent("storage", isDirectory: true)
        return Sync15CollectionClient(client: self, serverURI: storage, collection: collection, factory: factory)
    }
}

/**
 * We'd love to nest this in the overall storage client, but Swift
 * forbids the nesting of a generic class inside another class.
 */
public class Sync15CollectionClient<T: CleartextPayloadJSON> {
    private let client: Sync15StorageClient
    private let factory: (String) -> T?
    private let collectionURI: NSURL

    init(client: Sync15StorageClient, serverURI: NSURL, collection: String, factory: (String) -> T?) {
        self.client = client
        self.factory = factory
        self.collectionURI = serverURI.URLByAppendingPathComponent(collection, isDirectory: true)
    }

    private func uriForRecord(guid: String) -> NSURL {
        return self.collectionURI.URLByAppendingPathComponent(guid)
    }

    public func get(guid: String) -> Deferred<Result<StorageResponse<Record<T>>>> {
        let deferred = Deferred<Result<StorageResponse<Record<T>>>>(defaultQueue: client.resultQueue)

        let req = client.requestGET(uriForRecord(guid))
        req.responseParsedJSON(errorWrap(deferred, { (_, response, data, error) in

            if let json: JSON = data as? JSON {
                let envelope = EnvelopeJSON(json)
                println("Envelope: \(envelope) is valid \(envelope.isValid())")
                let record = Record<T>.fromEnvelope(envelope, payloadFactory: self.factory)
                if let record = record {
                    let storageResponse = StorageResponse(value: record, response: response!)
                    deferred.fill(Result(success: storageResponse))
                    return
                }
            } else {
                println("Couldn't cast JSON.")
            }

            deferred.fill(Result(failure: RecordParseError()))
        }))

        return deferred
    }

    /**
     * Unlike every other Sync client, we use the application/json format for fetching
     * multiple requests. The others use application/newlines. We don't want to write
     * another Serializer, and we're loading everything into memory anyway.
     */
    public func getSince(since: Int64) -> Deferred<Result<StorageResponse<[Record<T>]>>> {
        let deferred = Deferred<Result<StorageResponse<[Record<T>]>>>(defaultQueue: client.resultQueue)

        let req = client.requestGET(self.collectionURI)
        req.responseParsedJSON(errorWrap(deferred, { (_, response, data, error) in
            if let json: JSON = data as? JSON {
                func recordify(json: JSON) -> Record<T>? {
                    let envelope = EnvelopeJSON(json)
                    return Record<T>.fromEnvelope(envelope, payloadFactory: self.factory)
                }
                if let arr = json.asArray? {
                    let response = StorageResponse(value: optFilter(arr.map(recordify)), response: response!)
                    deferred.fill(Result(success: response))
                    return
                }
            }

            deferred.fill(Result(failure: RecordParseError()))
            return
        }))

        return deferred
    }
}
