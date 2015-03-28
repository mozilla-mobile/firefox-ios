/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */
//

import Foundation

public protocol OpenTabs {
    init(files: FileAccessor)
    
    func persist()
    
    func canRestore() -> Bool
}

public class FileOpenTabs : OpenTabs {
    private let files: FileAccessor

    let restoreFile = "open-tabs.json"
    
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

    public func canRestore() -> Bool {
        return files.exists(restoreFile)
    }
    
    public func writeToDisk(tabs:AnyObject) {
        var err: NSError?
        let jsonData = NSJSONSerialization.dataWithJSONObject(tabs, options:NSJSONWritingOptions(0), error: &err)
        files.write(restoreFile, data:jsonData)
    }
    
    public func readFromDisk() -> NSDictionary? {
        let data_ = files.read(restoreFile, error: nil)
        if (data_ == .None) {
            return .None
        }
        let data = data_!
        var parseError: NSError?
        let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.AllowFragments,
            error:&parseError)

        return parsedObject as? NSDictionary
    }
}
