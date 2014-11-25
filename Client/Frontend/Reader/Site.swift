// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

func == (a: Site, b: Site) -> Bool {
    return a.url == b.url && a.title == b.title
}

func != (a: Site, b: Site) -> Bool {
    return a.url != b.url || a.title != b.title
}

func == (a: Site, b: String) -> Bool {
    return a.url == b
}

func != (a: Site, b: String) -> Bool {
    return a.url != b
}

func == (a: String, b: Site) -> Bool {
    return a == b.url
}

func != (a: String, b: Site) -> Bool {
    return a != b.url
}

class Site : Equatable {
    let title : String
    let url : String
    init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}
