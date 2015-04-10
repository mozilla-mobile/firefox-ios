import Foundation

// A base protocol for something that can be cleared.
protocol Clearable {
    var name: String { get }
    func clear(viewController: UIViewController, prompt: Bool, completion: (success: Bool) -> Void)
}

// A base implementation of a clearable setting. This is useful for avoiding redudant prompting code.
// Implementation can just overwrite innerClear to avoid writing boilerplate.
class ClearableStorage: Clearable {
    var name: String { return "Storage" }
    var message: String { return "Are you sure you want to clear storage?" }

    func clear(viewController: UIViewController, prompt: Bool = true, completion: (success: Bool) -> Void) {
        if prompt {
            let alert = UIAlertController(title: nil, message: self.message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.addAction(UIAlertAction(title: "Clear", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                self.clear(viewController, prompt: false, completion: completion)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in }))
            viewController.presentViewController(alert, animated: true) { () -> Void in }
        } else {
            innerClear(viewController, completion: completion)
        }
    }

    func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        println("Trying to clear an abstract class. Should not ever reach this")
        completion(success: false)
    }
}

// Clears our browsing history, including favicons and thumbnails.
class HistoryClearable : ClearableStorage {
    override var name: String { return "History" }
    override var message: String { return "Are you sure you want to clear your browsing history?" }

    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    override func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        profile.history.clear() { success in
            self.profile.thumbnails.clear({ (success) -> Void in
                SDImageCache.sharedImageCache().clearDisk()
                SDImageCache.sharedImageCache().clearMemory()
                self.profile.favicons.clear(nil, complete: completion)
            })
        }
    }
}

// Clear all stored passwords. This will clear both Firefox's SQLite storage and the system shared
// Credential storage.
class PasswordsClearable : ClearableStorage {
    override var name: String { return "Passwords" }
    override var message: String { return "Are you sure you want to clear your stored passwords?" }

    let profile: Profile
    init(profile: Profile) {
        self.profile = profile
    }

    override func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        // Clear our storage
        profile.passwords.removeAll() { success in
            let storage = NSURLCredentialStorage.sharedCredentialStorage()
            let credentials = storage.allCredentials
            for (space, credential) in credentials {
                storage.removeCredential(credential as! NSURLCredential, forProtectionSpace: space as! NSURLProtectionSpace)
            }
            completion(success: success)
        }
    }
}

// Clear the web cache. Note, this has to close all open tabs in order to ensure the data
// cached in them isn't flushed to disk.
class CacheClearable : ClearableStorage {
    override var name: String { return "Cache" }
    override var message: String { return "Are you sure you want the web cache? This will also close all your open tabs." }

    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    override func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        // First ensure we close all open tabs first.
        tabManager.removeAll()

        // Remove the basic cache.
        NSURLCache.sharedURLCache().removeAllCachedResponses()

        // Now lets finish up by destroying our Cache directory.
        let manager = NSFileManager.defaultManager()
        var url = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        var file = url.path!.stringByAppendingPathComponent("Caches")
        var error: NSError? = nil
        if let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(file, error: nil) {
            for content in contents {
                let filePath = file.stringByAppendingPathComponent(content as! String)
                NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
            }
        }

        completion(success: true)
    }
}

// Removes all site data stored for sites. This should include things like IndexedDB or websql storage.
class SiteDataClearable : ClearableStorage {
    override var name: String { return "Site Data" }
    override var message: String { return "Are you sure you want all stored site data? This will also close all your open tabs." }

    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    override func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        // First, close all tabs to make sure they don't hold any thing in memory.
        tabManager.removeAll()

        // Then we just wipe the WebKit directory from our Library.
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        let file = url.path!.stringByAppendingPathComponent("WebKit")
        var error: NSError? = nil
        NSFileManager.defaultManager().removeItemAtPath(file, error: &error)
        completion(success: true)
    }
}

// Remove all cookies stored by the site.
class CookiesClearable : ClearableStorage {
    override var name: String { return "Cookies" }
    override var message: String { return "Are you sure you want all stored cookies? This will also close all your open tabs." }

    let tabManager: TabManager
    init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    override func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        // First close all tabs to make sure they aren't holding anything in memory.
        tabManager.removeAll()

        // Now we wipe the system cookie store (for our app).
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        if let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie as! NSHTTPCookie)
            }
        }

        // And just to be safe, we also wipe the Cookies directory.
        let manager = NSFileManager.defaultManager()
        var url = manager.URLsForDirectory(NSSearchPathDirectory.LibraryDirectory, inDomains: .UserDomainMask)[0] as! NSURL
        var file = url.path!.stringByAppendingPathComponent("Cookies")
        var error: NSError? = nil
        if let contents = NSFileManager.defaultManager().contentsOfDirectoryAtPath(file, error: nil) {
            for content in contents {
                let filePath = file.stringByAppendingPathComponent(content as! String)
                NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
            }
        }

        completion(success: true)
    }
}

// A Clearable designed to clear all of the locally stored data for our app.
class EverythingClearable: ClearableStorage {
    override var name: String { return "Everything" }
    override var message: String { return "Are you sure you want all of your data? This will also close all open tabs." }

    private let clearables: [Clearable]

    init(profile: Profile, tabmanager: TabManager) {
        clearables = [
            HistoryClearable(profile: profile),
            CacheClearable(tabManager: tabmanager),
            CookiesClearable(tabManager: tabmanager),
            SiteDataClearable(tabManager: tabmanager),
            PasswordsClearable(profile: profile),
        ]
        super.init()
    }

    override func innerClear(viewController: UIViewController, completion: (success: Bool) -> Void) {
        clearController(viewController: viewController, completion: completion)
    }

    private func clearController(index: Int = 0, viewController: UIViewController, completion: (success: Bool) -> Void) {
        if index >= clearables.count {
            completion(success: true)
            return
        }

        clearables[index].clear(viewController, prompt: false) { success in
            if !success {
                println("Error clearing \(self.clearables[index].name)")
            }
            self.clearController(index: index+1, viewController: viewController, completion: completion)
        }
    }
}
