/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class ProfileFileAccessor : FileAccessor {
    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    private func createDir(path: String) -> String? {
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            var err: NSError? = nil
            if !NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil, error: &err) {
                println("Error creating profile folder at \(path): \(err?.localizedDescription)")
                return nil
            }
        }
        return path
    }

    func getDir(name: String?, basePath: String? = nil) -> String? {
        var path = basePath
        if path == nil {
        	path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as? String
            path = createDir(path!.stringByAppendingPathComponent(profileDirName))

        }

        if let name = name {
            path = createDir(path!.stringByAppendingPathComponent(name))
        }
        return path!
    }

    func move(src: String, srcBasePath: String? = nil, dest: String, destBasePath: String? = nil) -> Bool {
        if let f = self.get(src, basePath: nil) {
            if let f2 = self.get(dest) {
                return NSFileManager.defaultManager().moveItemAtPath(f, toPath: f2, error: nil)
            }
        }

        return false
    }

    private var profileDirName: String {
        return "profile.\(profile.localName())"
    }

    func get(filename: String, basePath: String? = nil) -> String? {
        return getDir(nil, basePath: basePath)?.stringByAppendingPathComponent(filename)
    }


    func remove(filename: String, basePath: String? = nil) {
        let fileManager = NSFileManager.defaultManager()
        if var file = self.get(filename) {
            fileManager.removeItemAtPath(file, error: nil)
        }
    }

    func exists(filename: String, basePath: String? = nil) -> Bool {
        if var file = self.get(filename, basePath: basePath) {
            return NSFileManager.defaultManager().fileExistsAtPath(file)
        }
        return false
    }
}

/**
 * A Profile manages access to the user's data.
 */
protocol Profile {
    var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> { get }
    // var favicons: Favicons { get }
    var clients: Clients { get }
    var prefs: ProfilePrefs { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: History { get }
    var favicons: Favicons { get }
    var readingList: ReadingList { get }
    var passwords: Passwords { get }

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String
}

public class MockProfile: Profile {
    private let name: String = "mockaccount"

    func localName() -> String {
        return name
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        // Eventually this will be a SyncingBookmarksModel or an OfflineBookmarksModel, perhaps.
        return BookmarksSqliteFactory(files: self.files)
    } ()

    lazy var clients: Clients = {
        return MockClients(profile: self)
    } ()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines()
    } ()

    lazy var prefs: ProfilePrefs = {
        return MockProfilePrefs()
    } ()

    lazy var files: FileAccessor = {
        return ProfileFileAccessor(profile: self)
    } ()

    lazy var favicons: Favicons = {
        return SQLiteFavicons(files: self.files)
    }()

    lazy var history: History = {
        return SQLiteHistory(files: self.files)
    }()

    lazy var readingList: ReadingList = {
        return SQLiteReadingList(files: self.files)
    }()

    lazy var passwords: Passwords = {
        return MockPasswords(files: self.files)
    }()
}

public class BrowserProfile: Profile {
    private let name: String

    init(localName: String) {
        self.name = localName

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        notificationCenter.addObserver(self, selector: Selector("onLocationChange:"), name: "LocationChange", object: nil)
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let url = notification.userInfo!["url"] as? NSURL {
            var site: Site!
            if let title = notification.userInfo!["title"] as? NSString {
                site = Site(url: url.absoluteString!, title: title)
                let visit = Visit(site: site, date: NSDate())
                history.addVisit(visit, complete: { (success) -> Void in
                    // nothing to do
                })
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func localName() -> String {
        return name
    }

    var files: FileAccessor {
        return ProfileFileAccessor(profile: self)
    }

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination> = {
        return BookmarksSqliteFactory(files: self.files)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines()
    } ()

    func makePrefs() -> ProfilePrefs {
        return NSUserDefaultsProfilePrefs(profile: self)
    }

    lazy var clients: Clients = {
        return MockClients(profile: self)
    } ()

    lazy var favicons: Favicons = {
        return SQLiteFavicons(files: self.files)
    }()

    // lazy var ReadingList readingList

    lazy var prefs: ProfilePrefs = {
        return self.makePrefs()
    }()

    lazy var history: History = {
        return SQLiteHistory(files: self.files)
    }()

    lazy var readingList: ReadingList = {
        return SQLiteReadingList(files: self.files)
    }()

    lazy var passwords: Passwords = {
        return SQLitePasswords(files: self.files)
    }()
}
