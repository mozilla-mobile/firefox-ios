/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */
//

import Foundation

public protocol OpenTabs {
    init(files: FileAccessor)
    
    func persist()
}

public class FileOpenTabs : OpenTabs {
    private let files: FileAccessor

    public var persistenceTask: (() -> Void)?

    public required init(files: FileAccessor) {
        self.files = files
    }
    
    public func persist() {
        if let task = self.persistenceTask {
            task()
        } else {
            println("No Persisting")
        }
    }
    
    public func writeToDisk(tabs:AnyObject) {
        var err: NSError?
        let jsonData = NSJSONSerialization.dataWithJSONObject(tabs, options:NSJSONWritingOptions(0), error: &err)
        files.write("open-tabs.json", data:jsonData)
    }
}
