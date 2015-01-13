/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// TODO: Make this configurable.
let defaultEngineName = "Yahoo"

class SearchEngines {
    lazy var defaultEngine: OpenSearchEngine = {
        for engine in self.list {
            if engine.shortName == defaultEngineName {
                return engine
            }
        }

        assertionFailure("Default engine could not be found")
    } ()

    lazy var list: [OpenSearchEngine] = {
        var error: NSError?
        let path = NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("Locales/en-US/searchplugins")

        if path == nil {
            println("Error: Could not find search engine directory")
            return []
        }

        let directory = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path!, error: &error)

        if error != nil {
            println("Could not fetch search engines")
            return []
        }

        var engines = [OpenSearchEngine]()
        let parser = OpenSearchParser(pluginMode: true)
        for file in directory! {
            let fullPath = path!.stringByAppendingPathComponent(file as String)
            let engine = parser.parse(fullPath)
            engines.append(engine!)
        }

        return engines
    } ()
}