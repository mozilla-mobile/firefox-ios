/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire

enum ReadingListDeleteRecordResult {
    case Success(ReadingListRecordResponse)
    case PreconditionFailed(ReadingListResponse)
    case NotFound(ReadingListResponse)
    case Failure(ReadingListResponse)
    case Error(NSError)
}

enum ReadingListGetRecordResult {
    case Success(ReadingListRecordResponse)
    case NotModified(ReadingListResponse) // TODO Should really call this NotModified for clarity
    case NotFound(ReadingListResponse)
    case Failure(ReadingListResponse)
    case Error(NSError)
}

enum ReadingListGetAllRecordsResult {
    case Success(ReadingListRecordsResponse)
    case NotModified(ReadingListResponse) // TODO Should really call this NotModified for clarity
    case Failure(ReadingListResponse)
    case Error(NSError)
}

enum ReadingListPatchRecordResult {
}

enum ReadingListAddRecordResult {
    case Success(ReadingListRecordResponse)
    case Failure(ReadingListResponse)
    case Conflict(ReadingListResponse)
    case Error(NSError)
}

enum ReadingListBatchAddRecordsResult {
    case Success(ReadingListBatchRecordResponse)
    case Failure(ReadingListResponse)
    case Error(NSError)
}

private let ReadingListClientUnknownError = NSError(domain: "org.mozilla.ios.Fennec.ReadingListClient", code: -1, userInfo: nil)

class ReadingListClient {
    var serviceURL: NSURL
    var authenticator: ReadingListAuthenticator

    var articlesURL: NSURL!
    var articlesBaseURL: NSURL!
    var batchURL: NSURL!

    func getRecordWithGuid(guid: String, ifModifiedSince: ReadingListTimestamp?, completion: (ReadingListGetRecordResult) -> Void) {
        if let url = NSURL(string: guid, relativeToURL: articlesBaseURL) {
            Alamofire.Manager.sharedInstance.request(createRequest("GET", url, ifModifiedSince: ifModifiedSince)).responseJSON(options: [], completionHandler: { (request, response, json) -> Void in
                if let json = json.value, response = response {
                    switch response.statusCode {
                        case 200:
                            completion(.Success(ReadingListRecordResponse(response: response, json: json)!))
                        case 304:
                            completion(.NotModified(ReadingListResponse(response: response, json: json)!))
                        case 404:
                            completion(.NotFound(ReadingListResponse(response: response, json: json)!))
                        default:
                            completion(.Failure(ReadingListResponse(response: response, json: json)!))
                    }
                } else {
                    completion(.Error(json.error as? NSError ?? ReadingListClientUnknownError))
                }
            })
        } else {
            // TODO ???
        }
    }

    func getRecordWithGuid(guid: String, completion: (ReadingListGetRecordResult) -> Void) {
        getRecordWithGuid(guid, ifModifiedSince: nil, completion: completion)
    }

    func getAllRecordsWithFetchSpec(fetchSpec: ReadingListFetchSpec, ifModifiedSince: ReadingListTimestamp?, completion: (ReadingListGetAllRecordsResult) -> Void) {
        if let url = fetchSpec.getURL(serviceURL: serviceURL, path: "/v1/articles") {
            Alamofire.Manager.sharedInstance.request(createRequest("GET", url)).responseJSON(options: [], completionHandler: { (request, response, json) -> Void in
                if let response = response, json = json.value {
                    switch response.statusCode {
                    case 200:
                        completion(.Success(ReadingListRecordsResponse(response: response, json: json)!))
                    case 304:
                        completion(.NotModified(ReadingListResponse(response: response, json: json)!))
                    default:
                        completion(.Failure(ReadingListResponse(response: response, json: json)!))
                    }
                } else {
                    completion(.Error(json.error as? NSError ?? ReadingListClientUnknownError))
                }
            })
        } else {
            // TODO ???
        }
    }

    func getAllRecordsWithFetchSpec(fetchSpec: ReadingListFetchSpec, completion: (ReadingListGetAllRecordsResult) -> Void) {
        getAllRecordsWithFetchSpec(fetchSpec, ifModifiedSince: nil, completion: completion)
    }

    func patchRecord(record: ReadingListClientRecord, completion: (ReadingListPatchRecordResult) -> Void) {
    }

    func addRecord(record: ReadingListClientRecord, completion: (ReadingListAddRecordResult) -> Void) {
        Alamofire.Manager.sharedInstance.request(createRequest("POST", articlesURL, json: record.json)).responseJSON(options: [], completionHandler: { (request, response, json) -> Void in
            if let response = response, json = json.value {
                switch response.statusCode {
                    case 200, 201: // TODO Should we have different results for these? Do we care about 200 vs 201?
                        completion(.Success(ReadingListRecordResponse(response: response, json: json)!))
                    case 303:
                        completion(.Conflict(ReadingListResponse(response: response, json: json)!))
                    default:
                        completion(.Failure(ReadingListResponse(response: response, json: json)!))
                }
            } else {
                completion(.Error(json.error as? NSError ?? ReadingListClientUnknownError))
            }
        })
    }

    /// Build the JSON body for POST /v1/batch { defaults: {}, request: [ {body: {} } ] }
    private func recordsToBatchJSON(records: [ReadingListClientRecord]) -> AnyObject {
        return [
            "defaults": ["method": "POST", "path": "/v1/articles", "headers": ["Content-Type": "application/json"]],
            "requests": records.map { ["body": $0.json] }
        ]
    }

    func batchAddRecords(records: [ReadingListClientRecord], completion: (ReadingListBatchAddRecordsResult) -> Void) {
        Alamofire.Manager.sharedInstance.request(createRequest("POST", batchURL, json: recordsToBatchJSON(records))).responseJSON(options: [], completionHandler: { (request, response, json) -> Void in
            if let response = response, json = json.value {
                switch response.statusCode {
                case 200:
                    completion(.Success(ReadingListBatchRecordResponse(response: response, json: json)!))
                default:
                    completion(.Failure(ReadingListResponse(response: response, json: json)!))
                }
            } else {
                completion(.Error(json.error as? NSError ?? ReadingListClientUnknownError))
            }
        })
    }

    func deleteRecordWithGuid(guid: String, ifUnmodifiedSince: ReadingListTimestamp?, completion: (ReadingListDeleteRecordResult) -> Void) {
        if let url = NSURL(string: guid, relativeToURL: articlesBaseURL) {
            Alamofire.Manager.sharedInstance.request(createRequest("DELETE", url, ifUnmodifiedSince: ifUnmodifiedSince)).responseJSON(options: [], completionHandler: { (request, response, json) -> Void in
                if let response = response,
                    let json = json.value {
                    switch response.statusCode {
                        case 200:
                            completion(.Success(ReadingListRecordResponse(response: response, json: json)!))
                        case 412:
                            completion(.PreconditionFailed(ReadingListResponse(response: response, json: json)!))
                        case 404:
                            completion(.NotFound(ReadingListResponse(response: response, json: json)!))
                        default:
                            completion(.Failure(ReadingListResponse(response: response, json: json)!))
                    }
                } else {
                    completion(.Error(json.error as? NSError ?? ReadingListClientUnknownError))
                }
            })
        } else {
            // TODO ???
        }
    }

    func deleteRecordWithGuid(guid: String, completion: (ReadingListDeleteRecordResult) -> Void) {
        deleteRecordWithGuid(guid, ifUnmodifiedSince: nil, completion: completion)
    }

    func createRequest(method: String, _ url: NSURL, ifUnmodifiedSince: ReadingListTimestamp? = nil, ifModifiedSince: ReadingListTimestamp? = nil, json: AnyObject? = nil) -> NSURLRequest {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method
        if let ifUnmodifiedSince = ifUnmodifiedSince {
            request.setValue(String(ifUnmodifiedSince), forHTTPHeaderField: "If-Unmodified-Since")
        }
        if let ifModifiedSince = ifModifiedSince {
            request.setValue(String(ifModifiedSince), forHTTPHeaderField: "If-Modified-Since")
        }
        for (headerField, value) in authenticator.headers {
            request.setValue(value, forHTTPHeaderField: headerField)
        }
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        if let json: AnyObject = json {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
            } catch _ {
                request.HTTPBody = nil
            } // TODO Handle errors here
        }
        return request
    }

    init(serviceURL: NSURL, authenticator: ReadingListAuthenticator) {
        self.serviceURL = serviceURL
        self.authenticator = authenticator

        self.articlesURL = NSURL(string: "/v1/articles", relativeToURL: self.serviceURL)
        self.articlesBaseURL = NSURL(string: "/v1/articles/", relativeToURL: self.serviceURL)
        self.batchURL = NSURL(string: "/v1/batch", relativeToURL: self.serviceURL)
    }
}