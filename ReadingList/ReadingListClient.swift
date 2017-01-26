/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire

enum ReadingListDeleteRecordResult {
    case success(ReadingListRecordResponse)
    case preconditionFailed(ReadingListResponse)
    case notFound(ReadingListResponse)
    case failure(ReadingListResponse)
    case error(NSError)
}

enum ReadingListGetRecordResult {
    case success(ReadingListRecordResponse)
    case notModified(ReadingListResponse) // TODO Should really call this NotModified for clarity
    case notFound(ReadingListResponse)
    case failure(ReadingListResponse)
    case error(NSError)
}

enum ReadingListGetAllRecordsResult {
    case success(ReadingListRecordsResponse)
    case notModified(ReadingListResponse) // TODO Should really call this NotModified for clarity
    case failure(ReadingListResponse)
    case error(NSError)
}

enum ReadingListPatchRecordResult {
}

enum ReadingListAddRecordResult {
    case success(ReadingListRecordResponse)
    case failure(ReadingListResponse)
    case conflict(ReadingListResponse)
    case error(NSError)
}

enum ReadingListBatchAddRecordsResult {
    case success(ReadingListBatchRecordResponse)
    case failure(ReadingListResponse)
    case error(NSError)
}

private let ReadingListClientUnknownError = NSError(domain: "org.mozilla.ios.Fennec.ReadingListClient", code: -1, userInfo: nil)

class ReadingListClient {
    var serviceURL: URL
    var authenticator: ReadingListAuthenticator

    var articlesURL: URL!
    var articlesBaseURL: URL!
    var batchURL: URL!

    func getRecordWithGuid(_ guid: String, ifModifiedSince: ReadingListTimestamp?, completion: @escaping (ReadingListGetRecordResult) -> Void) {
        if let url = URL(string: guid, relativeTo: articlesBaseURL) {
            SessionManager.default.request(createRequest("GET", url, ifModifiedSince: ifModifiedSince)).responseJSON(options: [], completionHandler: { response -> Void in
                if let json = response.result.value as? [String: Any], let response = response.response {
                    switch response.statusCode {
                        case 200:
                            completion(.success(ReadingListRecordResponse(response: response, json: json)!))
                        case 304:
                            completion(.notModified(ReadingListResponse(response: response, json: json)!))
                        case 404:
                            completion(.notFound(ReadingListResponse(response: response, json: json)!))
                        default:
                            completion(.failure(ReadingListResponse(response: response, json: json)!))
                    }
                } else {
                    completion(.error(response.result.error as NSError? ?? ReadingListClientUnknownError))
                }
            })
        } else {
            // TODO ???
        }
    }

    func getRecordWithGuid(_ guid: String, completion: @escaping (ReadingListGetRecordResult) -> Void) {
        getRecordWithGuid(guid, ifModifiedSince: nil, completion: completion)
    }

    func getAllRecordsWithFetchSpec(_ fetchSpec: ReadingListFetchSpec, ifModifiedSince: ReadingListTimestamp?, completion: @escaping (ReadingListGetAllRecordsResult) -> Void) {
        if let url = fetchSpec.getURL(serviceURL: serviceURL, path: "/v1/articles") {
            SessionManager.default.request(createRequest("GET", url)).responseJSON(options: [], completionHandler: { response -> Void in
                if let json = response.result.value as? [String: Any], let response = response.response {
                    switch response.statusCode {
                    case 200:
                        completion(.success(ReadingListRecordsResponse(response: response, json: json)!))
                    case 304:
                        completion(.notModified(ReadingListResponse(response: response, json: json)!))
                    default:
                        completion(.failure(ReadingListResponse(response: response, json: json)!))
                    }
                } else {
                    completion(.error(response.result.error as NSError? ?? ReadingListClientUnknownError))
                }
            })
        } else {
            // TODO ???
        }
    }

    func getAllRecordsWithFetchSpec(_ fetchSpec: ReadingListFetchSpec, completion: @escaping (ReadingListGetAllRecordsResult) -> Void) {
        getAllRecordsWithFetchSpec(fetchSpec, ifModifiedSince: nil, completion: completion)
    }

    func patchRecord(_ record: ReadingListClientRecord, completion: (ReadingListPatchRecordResult) -> Void) {
    }

    func addRecord(_ record: ReadingListClientRecord, completion: @escaping (ReadingListAddRecordResult) -> Void) {
        SessionManager.default.request(createRequest("POST", articlesURL, json: record.json)).responseJSON(options: [], completionHandler: { response in
            if let json = response.result.value as? [String: Any], let response = response.response {
                switch response.statusCode {
                    case 200, 201: // TODO Should we have different results for these? Do we care about 200 vs 201?
                        completion(.success(ReadingListRecordResponse(response: response, json: json)!))
                    case 303:
                        completion(.conflict(ReadingListResponse(response: response, json: json)!))
                    default:
                        completion(.failure(ReadingListResponse(response: response, json: json)!))
                }
            } else {
                completion(.error(response.result.error as NSError? ?? ReadingListClientUnknownError))
            }
        })
    }

    /// Build the JSON body for POST /v1/batch { defaults: {}, request: [ {body: {} } ] }
    fileprivate func recordsToBatchJSON(_ records: [ReadingListClientRecord]) -> AnyObject {
        return [
            "defaults": ["method": "POST", "path": "/v1/articles", "headers": ["Content-Type": "application/json"]],
            "requests": records.map { ["body": $0.json] }
        ] as NSDictionary
    }

    func batchAddRecords(_ records: [ReadingListClientRecord], completion: @escaping (ReadingListBatchAddRecordsResult) -> Void) {
        SessionManager.default.request(createRequest("POST", batchURL, json: recordsToBatchJSON(records))).responseJSON(options: [], completionHandler: { response in
            if let json = response.result.value as? [String: Any], let response = response.response {
                switch response.statusCode {
                case 200:
                    completion(.success(ReadingListBatchRecordResponse(response: response, json: json)!))
                default:
                    completion(.failure(ReadingListResponse(response: response, json: json)!))
                }
            } else {
                completion(.error(response.result.error as NSError? ?? ReadingListClientUnknownError))
            }
        })
    }

    func deleteRecordWithGuid(_ guid: String, ifUnmodifiedSince: ReadingListTimestamp?, completion: @escaping (ReadingListDeleteRecordResult) -> Void) {
        if let url = URL(string: guid, relativeTo: articlesBaseURL) {
            SessionManager.default.request(createRequest("DELETE", url, ifUnmodifiedSince: ifUnmodifiedSince)).responseJSON(options: [], completionHandler: { response in
                if let json = response.result.value as? [String: Any], let response = response.response {
                    switch response.statusCode {
                        case 200:
                            completion(.success(ReadingListRecordResponse(response: response, json: json)!))
                        case 412:
                            completion(.preconditionFailed(ReadingListResponse(response: response, json: json)!))
                        case 404:
                            completion(.notFound(ReadingListResponse(response: response, json: json)!))
                        default:
                            completion(.failure(ReadingListResponse(response: response, json: json)!))
                    }
                } else {
                    completion(.error(response.result.error as NSError? ?? ReadingListClientUnknownError))
                }
            })
        } else {
            // TODO ???
        }
    }

    func deleteRecordWithGuid(_ guid: String, completion: @escaping (ReadingListDeleteRecordResult) -> Void) {
        deleteRecordWithGuid(guid, ifUnmodifiedSince: nil, completion: completion)
    }

    func createRequest(_ method: String, _ url: URL, ifUnmodifiedSince: ReadingListTimestamp? = nil, ifModifiedSince: ReadingListTimestamp? = nil, json: AnyObject? = nil) -> URLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
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
        if let json = json {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
            } catch _ {
                request.httpBody = nil
            } // TODO Handle errors here
        }
        return request as URLRequest
    }

    init(serviceURL: URL, authenticator: ReadingListAuthenticator) {
        self.serviceURL = serviceURL
        self.authenticator = authenticator

        self.articlesURL = URL(string: "/v1/articles", relativeTo: self.serviceURL)
        self.articlesBaseURL = URL(string: "/v1/articles/", relativeTo: self.serviceURL)
        self.batchURL = URL(string: "/v1/batch", relativeTo: self.serviceURL)
    }
}
