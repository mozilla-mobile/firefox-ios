/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import Foundation

struct TodayModel {
<<<<<<< HEAD
    static var copiedURL: URL?
    
=======
    public var copiedURL: URL?

>>>>>>> 3c460f1a9... added ViewModel and Model files to widget extension and re-architect the widget
    var scheme: String {
        guard let string = Bundle.main.object(forInfoDictionaryKey: "MozInternalURLScheme") as? String else {
            // Something went wrong/weird, but we should fallback to the public one.
            return "firefox"
        }
        return string
    }
}
