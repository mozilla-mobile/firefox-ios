/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class HandoffManager: NSObject {
    static var sharedInstance = HandoffManager()
    
    lazy var userActivity: NSUserActivity = {
        return NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    }()
    
    func start() {
        // iOS 8.x is not current target
        if #available(iOS 9.0, *) {
            guard ((userActivity.webpageURL) != nil) else {
                return
            }
            userActivity.becomeCurrent()
        }
    }
    
    func stop() {
        if #available(iOS 9.0, *) {
            userActivity.resignCurrent()
        }
    }
    
    func clearCurrentURL() {
        userActivity.webpageURL = nil
    }
    
    func updateCurrentURL(urlStr: String?) {
        guard let url = urlStr?.asURL
            where ["http", "https"].contains(url.scheme) else {
            return
        }
        
        userActivity.webpageURL = url
    }
}
