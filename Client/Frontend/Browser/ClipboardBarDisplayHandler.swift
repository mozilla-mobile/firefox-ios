
import Foundation
import Shared

public struct ClipboardBarToastUX {
    static let DismissAfter = 4.0
}

protocol ClipboardBarDisplayHandlerDelegate: class {
    func shouldDisplayClipboardBar(absoluteString: String)
}

class ClipboardBarDisplayHandler {
    weak var delegate: ClipboardBarDisplayHandlerDelegate?
    private var sessionStarted = true
    private var prefs: Prefs
    private var lastDisplayedURL: String?
    
    init(prefs: Prefs) {
        self.prefs = prefs
        NotificationCenter.default.addObserver(self, selector: #selector(self.SELAppWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc private func SELAppWillEnterForegroundNotification() {
        sessionStarted = true
        checkIfShouldDisplayBar()
    }
    
    private func shouldDisplayBar() -> Bool {
        if !sessionStarted || UIPasteboard.general.copiedURL == nil || wasClipboardURLAlreadyDisplayed() {
            return false
        }
        sessionStarted = false
        lastDisplayedURL = UIPasteboard.general.copiedURL?.absoluteString
        return true
    }
    
    //If we already displayed this URL on the previous session
    //We shouldn't display it again
    private func wasClipboardURLAlreadyDisplayed() -> Bool {
        guard let clipboardURL = UIPasteboard.general.copiedURL?.absoluteString ,
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
            if let absoluteString = UIPasteboard.general.copiedURL?.absoluteString {
                delegate?.shouldDisplayClipboardBar(absoluteString: absoluteString)
            }
        }
    }
}
