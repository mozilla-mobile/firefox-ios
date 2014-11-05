//
//  RestAPI.swift
//  Client
//
//  Created by Wes Johnston on 11/5/14.
//  Copyright (c) 2014 Mozilla. All rights reserved.
//

import Foundation
import AlamoFire

private let username = "sarentz+syncapi@mozilla.com";
private let password = "q1w2e3r4";
private let BASE_URL = "https://syncapi-dev.sateh.com/1.0/"

class RestAPI {
    class func sendRequest(request: String, callback: (response: AnyObject?) -> Void) {
        Alamofire.request(.GET, BASE_URL + request)
            .authenticate(user: username, password: password)
            .responseJSON { (request, response, data, error) in
                callback(response: data?);
        }
    }
}