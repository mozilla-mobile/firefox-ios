
import Foundation
import Shared

public struct UserDefaultClipboardKey {
    public static let KeyLastSavedURL = "KeylastSavedURL"
}

protocol ClipboardBarDisplayHandlerDelegate: class {
    func shouldDisplayClipboardBar(absoluteString: String)
}


class ClipboardBarDisplayHandler {
    weak var delegate: ClipboardBarDisplayHandlerDelegate?
    private var sessionStarted = true
    private var prefs: Prefs
    private var lastDisplayedURL: String? {
        if let value = NSUserDefaults.standardUserDefaults().objectForKey(UserDefaultClipboardKey.KeyLastSavedURL) as? String {
            return value
        }
        return nil
    }
    
    init(prefs: Prefs) {
        self.prefs = prefs
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.SELAppWillEnterForegroundNotification), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }

    @objc private func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }
    
    private func shouldDisplayBar() -> Bool {
        let allowClipboard = (prefs.boolForKey(PrefsKeys.KeyClipboardOption) ?? true)
        
        if !sessionStarted || !allowClipboard || UIPasteboard.generalPasteboard().copiedURL == nil || wasClipboardURLAlreadyDisplayed() {
            return false
        }
        sessionStarted = false
        return true
    }
    
    private func saveLastDisplayedURL(url: String?) {
        if let urlString = url {
            NSUserDefaults.standardUserDefaults().setObject(urlString, forKey: UserDefaultClipboardKey.KeyLastSavedURL)
        } else {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(UserDefaultClipboardKey.KeyLastSavedURL)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    //If we already displayed this URL on the previous session
    //We shouldn't display it again
    private func wasClipboardURLAlreadyDisplayed() -> Bool {
        guard let clipboardURL = UIPasteboard.generalPasteboard().copiedURL?.absoluteString ,
        let savedURL = lastDisplayedURL else {
            return false
        }
        if clipboardURL == savedURL {
            return true
        }
        return false
    }
    
    func checkIfShouldDisplayBar() {
        if shouldDisplayBar() {
            if let absoluteString = UIPasteboard.generalPasteboard().copiedURL?.absoluteString {
                delegate?.shouldDisplayClipboardBar(absoluteString)
            }
        }
    }
}
