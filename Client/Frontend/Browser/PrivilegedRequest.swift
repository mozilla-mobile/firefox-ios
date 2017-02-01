/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let REQUEST_KEY_PRIVILEGED = "privileged"

/**
 Request that is allowed to load local resources.

 Pages running on the local server have same origin access all resources
 on the server, so we need to prevent arbitrary web pages from accessing
 these resources. We do so by explicitly requiring "privileged" requests
 in our navigation policy when loading local resources.

 Be careful: creating a privileged request for an arbitrary URL provided
 by the page will break this model. Only use a privileged request when
 needed, and when you are sure the URL is from a trustworthy source!
 **/
class PrivilegedRequest: NSMutableURLRequest {
    override init(url URL: URL, cachePolicy: NSURLRequest.CachePolicy, timeoutInterval: TimeInterval) {
        super.init(url: URL, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        setPrivileged()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setPrivileged()
    }

    fileprivate func setPrivileged() {
        URLProtocol.setProperty(true, forKey: REQUEST_KEY_PRIVILEGED, in: self)
    }
}

extension URLRequest {
    var isPrivileged: Bool {
        return URLProtocol.property(forKey: REQUEST_KEY_PRIVILEGED, in: self) != nil
    }
}
