
import Foundation
import Shared

class ClipboardBarDisplayHandler {
    private let clipboardBar: ClipboardBar
    var sessionStarted = true
    var prefs: Prefs
    //var preferences: Prefs
    var isClipboardBarVisible: Bool { return !clipboardBar.hidden }
    
    init(clipboardBar: ClipboardBar, prefs: Prefs) {
        self.clipboardBar = clipboardBar
        self.clipboardBar.hidden = true
        self.prefs = prefs
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.SELAppWillEnterForegroundNotification), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }

    @objc func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        displayBarIfNecessary()
    }
    
    func hideBar() {
        if !isClipboardBarVisible {
            return
        }
        UIView.animateWithDuration(0.2, delay: 0, options: .BeginFromCurrentState, animations: {
            self.clipboardBar.alpha = 0.0
            }, completion: { _ in
                self.clipboardBar.hidden = true
            }
         )
    }
    
    func displayBarIfNecessary() {
        let allowClipboard = (prefs.boolForKey(PrefsKeys.KeyClipboardOption) ?? true)
        if !sessionStarted || !allowClipboard || UIPasteboard.generalPasteboard().copiedURL == nil {
            hideBar()
            return
        }

        clipboardBar.hidden = false
        clipboardBar.alpha = 1.0;
        sessionStarted = false
        clipboardBar.urlString = UIPasteboard.generalPasteboard().copiedURL?.absoluteString
        
        let seconds = 10.0
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) { [weak self] in
            self?.hideBar()
        }
    }
}
